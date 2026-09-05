# Commander

Командир читает канон с шины и шлёт `chat.act` на живой коннектор площадки. Сам канон не эмитит и в сеть не ходит: ban/timeout/say выполняет connector через `Ready::Act` + `chat_complete`.

## Feature и гранты

| | |
| --- | --- |
| Feature SDK | `commander` |
| Обязательные гранты | `chat.act` |
| Модули | `chat_act` |
| Не делает | `bus.emit`, сеть |
| Карта | [ref/01-roles](../ref/01-roles.md) |

Эталон: `modus new commander`.

## Манифест

```json
{
  "id": "com.modus.commander",
  "name": "Commander",
  "version": "0.1.0",
  "author": "modus",
  "abi": 2,
  /* единственный грант: ставить ActJob на живой connector */
  "capabilities": ["chat.act"]
  /* platform_id не нужен: platform/channel берутся из Event.source */
}
```

`platform_id` не нужен: job несёт `platform`/`channel` из события шины.

## Код

**Подписка и фильтр message.**

```rust
fn init() {
    // без subscribe Ready::Bus не придёт — команды из чата не увидим
    wait::subscribe();
}

fn on_bus(event: &Event) {
    // только Message; donation/follow и пр. — не команды
    let Payload::Message(msg) = &event.payload else { return };
    // текст только из Fragment::Text (эмодзи не ломают парсер)
    let text = fragments_text(&msg.fragments);
    // platform/channel из источника события → куда слать act
    let Some(job) = parse_command(&event.source.platform, &event.source.channel, &text) else {
        return; // не !ban / !timeout / !say — молча
    };
    // хост будит connector Ready::Act; ошибка сразу, если нет живой площадки
    if let Err(err) = chat_act::act(&job) {
        log::log(Level::Warn, &err);
    }
}
```

**Парсер команд.** `!ban` / `!unban` / `!timeout <user> <sec>` / `!say …` → `ActJob`.

```rust
match cmd.as_str() {
    // Ban: target user, без duration
    "!ban" => Some(job(platform, channel, ActKind::Ban, None, Some(user), None)),
    // Timeout: user + secs в последнем аргументе
    "!timeout" => Some(job(platform, channel, ActKind::Timeout, None, Some(user), Some(secs))),
    // Send: текст rest → PRIVMSG через connector
    "!say" => Some(job(platform, channel, ActKind::Send, Some(rest.into()), None, None)),
    // неизвестная команда — не слать act
    _ => None,
}
```

Текст берётся только из `Fragment::Text` (эмодзи/mention в команду не мешают).

## Assets

Нет: settings / web / panel у эталона отсутствуют.

## Как запустить

```powershell
modus new commander --id com.you.cmd --dir cmd
modus dev modus new commander
```

В `dev` `chat.act` логируется учебным хостом (не очередь Core). Для полного пути нужен живой connector той же `platform` (fixture тоже отвечает на `Act`). Рядом: `modus dev …/fixture` + inject/`!say` с шины, или `--inject` с message-текстом команды.

Флаги: [api/11-cli-dev](../api/11-cli-dev.md). Контракт act — [api/06-kv-act-alerts](../api/06-kv-act-alerts.md).

## Типичные ошибки хоста

| Ситуация | Строка / эффект |
| --- | --- |
| Нет гранта | `нет гранта chat.act` |
| Нет живого коннектора площадки | ошибка сразу на `act` (хост не кому будить) |
| Коннектор в backoff | `нет соединения` на complete-пути |
| Стоп | `остановлен` |
