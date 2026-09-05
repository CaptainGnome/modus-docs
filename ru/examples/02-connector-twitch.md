# Connector / Twitch

Коннектор — живая площадка: OAuth через хост, HTTP/WS, emit канона, ответ на `chat.act`. Twitch эталон (~700 строк): ниже только auth → IRC → wait-loop → emit, без полного дампа Helix/EventSub.

## Feature и гранты

| | |
| --- | --- |
| Feature SDK | `connector` |
| Обязательные (типично) | `auth.token` + `net.http` + `net.ws` + `bus.emit` + `media.cache` |
| Модули | `auth_token`, `net_http`, `net_ws`, `bus_emit`, `chat_complete`, `media_cache` |
| Карта | [ref/01-roles](../ref/01-roles.md) |

Эталон: [`plugins/twitch`](../../../plugins/twitch). Auth/сеть — [ref/06-net-auth](../ref/06-net-auth.md).

## Манифест (фрагмент)

| Поле | Зачем |
| --- | --- |
| `capabilities` | токен, HTTP, WS, emit, кэш эмодзи |
| `platform_id` | `"twitch"` — метка канона и слот площадки |
| `auth_mode` | `"broker"` — OAuth через брокер Core/CLI |
| `client_id` / `auth_url` / `token_url` / `userinfo_url` | OAuth Helix |
| `broker_url` | брокер обмена кода |
| `scopes` | chat / mod / redemptions |
| `hosts` | allowlist DNS для `net.*` |

```json
{
  /* полный набор живой площадки: токен, HTTP, WS, emit, кэш эмодзи */
  "capabilities": ["auth.token", "net.http", "net.ws", "bus.emit", "media.cache"],
  /* один живой плагин на platform_id; метка в Event.source */
  "platform_id": "twitch",
  /* OAuth через брокер Core/CLI, не свой redirect-сервер */
  "auth_mode": "broker",
  /* DNS allowlist: всё вне списка → «… вне манифеста» */
  "hosts": [
    "id.twitch.tv",
    "api.twitch.tv",
    "irc-ws.chat.twitch.tv",
    "eventsub.wss.twitch.tv"
  ]
}
```

Полный файл: [`plugins/twitch/manifest`](../../../plugins/twitch/manifest).

## Код: auth → WS → wait → emit

**Старт: аккаунт и токен.** Без аккаунта `run` тихо выходит; токен только через грант.

```rust
fn run() {
    // аккаунты, которые пользователь привязал в Core/CLI
    let accounts = auth_token::list_accounts();
    if accounts.is_empty() {
        // без логина некуда: тихий выход, не Retry
        log::log(Level::Info, "нет аккаунта");
        return;
    }
    // берём первый; мульти-аккаунт — отдельная политика
    run_account(&accounts[0]);
}

fn run_session(account_id: &str) -> Outcome {
    // токен только через грант auth.token; чужой id → ошибка
    let token = match auth_token::token(account_id) {
        Ok(token) => token,
        // is_stop (отозван / остановлен) — не глотать в backoff
        Err(err) => return fail(&err),
    };
    // helix_user(&token) → nick / user_id для IRC NICK и Helix
    let irc = match net_ws::connect(IRC_URL) {
        /* wss из hosts; иначе отказ сети */
        Ok(h) => h,
        Err(e) => return fail(&e),
    };
    // PASS oauth:… / NICK / CAP REQ / JOIN #channel по irc handle
    // далее wait-loop на том же session
}
```

**Wait-loop (скелет).** Один IRC + EventSub; `Act` → Helix/PRIVMSG; закрытие сокета → retry с backoff.

```rust
loop {
    match wait::wait() {
        // выкл — закрыть сокеты, Outcome::Stopped (не Retry)
        Ready::Stop => { /* close; Outcome::Stopped */ }
        // обрыв IRC → fail → backoff / reconnect
        Ready::WsClosed(h) if h == session.irc => return fail("ws закрыт"),
        // кадр IRC: PRIVMSG / NOTICE / PING…
        Ready::WsText(frame) if frame.handle == session.irc => {
            if let Some(out) = handle_irc(&mut session, &frame.text) {
                return out; // Stopped или фатальная ошибка парсера
            }
        }
        // job от commander → Helix/PRIVMSG + chat_complete
        Ready::Act(req) => handle_act(&session, &req),
        // хост просит пересобрать сессию (токен / сеть)
        Ready::Resume => return fail("resume"),
        // периодический poll: EventSub reconnect / viewers
        Ready::Timer => { /* EventSub reconnect / poll viewers */ }
        _ => {}
    }
}
```

**Emit из PRIVMSG.** Парсер → `Payload::Message` → `bus_emit`; URL эмодзи в `media_cache`.

```rust
Line::Privmsg(msg) => {
    // заранее lookup URL эмодзи — прогреть кэш до ensure
    for url in &urls { let _ = media_cache::lookup(url); }
    // собрать канон: user, fragments, color, badges…
    let payload = Payload::Message(Message { /* user, fragments, color… */ });
    // канал = IRC channel без #; opaque обычно None
    if let Err(err) = bus_emit::emit(&msg.channel, &payload, None) {
        // остановлен во время emit — выйти из сессии, не Retry
        if HostError::classify(&err).is_stop() {
            return Some(Outcome::Stopped);
        }
    }
    // pin картинок эмодзи после emit (overlay/cache/{key})
    for url in &urls { let _ = media_cache::ensure(url); }
}
```

**Act → complete.** Send идёт в IRC; ban/timeout/delete — Helix; всегда `chat_complete`.

```rust
fn handle_act(session: &Session, req: &ActRequest) {
    // Send → PRIVMSG; Ban/Timeout/Delete → Helix API
    match execute_act(session, req) {
        // complete обязателен — иначе job висит у командира
        Ok(()) => chat_complete::complete(&req.id, Ok(())),
        Err(err) => chat_complete::complete(&req.id, Err(err.as_str())),
    }
}
```

## Assets

У Twitch — `platform_logo.svg` (иконка площадки). Settings UI в эталоне нет: канал = логин аккаунта IRC.

## Как запустить

```powershell
modus new connector --id com.you.twitch --dir twitch
```

Офлайн без живого Twitch ([start/07-connector](../start/07-connector.md)):

```powershell
modus dev ../../../plugins/twitch --token fake --replay frames.replay
```

Опционально `--http-file` для Helix. Живой OAuth — Core / брокер, не первый шаг отладки.

## Типичные ошибки хоста

| Ситуация | Строка |
| --- | --- |
| Нет cap | `нет гранта auth.token` / `net.ws` / `bus.emit` |
| Хост не в `hosts` | `… вне манифеста` |
| Не https/wss | `только https/wss` |
| Токен чужой / отозван | `чужой аккаунт`, `refresh отозван` (`is_stop`) |
| Нет `platform_id` | `нет platform_id` |
| Площадка занята | `platform_id … уже занят` |
| Стоп во время backoff | `остановлен` — выйти, не `Retry` |
