# Provider / 7TV

Provider не эмитит канон чата: тянет HTTP/WS стороннего каталога, кладёт медиа в cache и публикует срез через `catalog.publish`. 7TV — эмодзи для Twitch-канала.

## Feature и гранты

| | |
| --- | --- |
| Feature SDK | `provider` |
| Обязательные гранты | `net.http` + `net.ws` + `media.cache` + `catalog.publish` |
| Модули | `net_http`, `net_ws`, `media_cache`, `catalog` |
| Не делает | `platform_id`, `bus.emit` |
| Карта | [ref/01-roles](../ref/01-roles.md) |

Эталон: `modus new provider`.

## Манифест

```json
{
  "id": "com.modus.7tv",
  /* сеть + кэш картинок + публикация среза каталога */
  "capabilities": ["net.http", "net.ws", "media.cache", "catalog.publish"],
  /* API / CDN / events WS — всё вне списка запрещено */
  "hosts": ["7tv.io", "cdn.7tv.app", "events.7tv.io"],
  /* имя среза + схема: потребители указывают consumes: ["emotes"] */
  "provides": [{ "name": "emotes", "schema": "modus.emotes.v1" }],
  /* мягкая связь: канал с шины Twitch, если settings.channel пуст */
  "depends": [{ "platform": "twitch" }]
}
```

| Поле | Зачем |
| --- | --- |
| `hosts` | allowlist API / CDN / events WS |
| `provides` | имя среза каталога + схема для потребителей (`consumes`) |
| `depends` | мягкая связь: канал с шины Twitch, если settings пуст |

## Код

**Канал: settings или шина.** Подписка нужна, чтобы подхватить `event.source.channel` с Twitch.

```rust
fn init() {
    // нужна шина: пустой channel → ждём Twitch event.source.channel
    wait::subscribe();
    // i18n-label в settings UI («статус»)
    let _ = modus_sdk::set_label_i18n("status", "status.start", None);
}

fn resolve_channel() -> String {
    // ручной оверлей settings; trim + lower — как login Twitch
    settings::get("channel").unwrap_or_default().trim().to_ascii_lowercase()
}
```

**Refresh → pin → publish.** HTTP наборы → `media_cache::ensure` → JSON body → `catalog::publish("emotes", …)`.

```rust
fn refresh(channel: &str) -> Result<Vec<String>, String> {
    // global + user sets → chosen emotes (PIN_MAX — квота pin)
    for emote in chosen {
        // CDN URL → ключ кэша для overlay (cache/{key})
        let key = media_cache::ensure(&cdn_url(&emote.id))?;
        // элемент среза: имя чата + id 7TV + ключ картинки
        published.push(json!({ "name": emote.name, "id": emote.id, "key": key, … }));
    }
    // тело каталога: канал, платформы, список эмодзи
    let body = json!({ "channel": channel, "platforms": ["twitch"], "emotes": published });
    // publish("emotes") — имя из provides; байты = JSON среза
    catalog::publish("emotes", &serde_json::to_vec(&body)?)?;
    // set_ids нужны для subscribe на events WS
    Ok(set_ids)
}
```

**Events WS.** Heartbeat + subscribe на set id; смена набора → повторный `refresh`.

```rust
// wss://events.7tv.io — хост из манифеста
let handle = net_ws::connect(EVENTS_URL)?;
// op 1 → subscribe_body(set_id) после refresh
// op 0 emote_set.update → снова refresh
// Timer → heartbeat {"op":2}, иначе сервер рвёт сокет
```

## Assets

| Путь | Назначение |
| --- | --- |
| [`assets/settings.json`](modus new provider/assets/settings.json) | поле `channel` + label `status` |
| [`assets/i18n/ru.json`](modus new provider/assets/i18n/ru.json) | строки статуса / подписей |

Пустой `channel` → статус `status.need_twitch`, ждём шину или `--settings`.

## Как запустить

```powershell
modus new provider --id com.you.7tv --dir seventv
modus dev modus new provider --settings channel.json
```

`channel.json` — оверлей ключей settings (см. [api/11-cli-dev](../api/11-cli-dev.md)). Для сети без интернета — `--http-file` / `--replay`. Рядом полезен живой/fixture Twitch, если канал берётся с шины.

## Типичные ошибки хоста

| Ситуация | Строка |
| --- | --- |
| Нет `catalog.publish` | `нет гранта catalog.publish` |
| CDN/API вне `hosts` | `… вне манифеста` |
| Квота / размер | `квота http`, `тело слишком большое` |
| Стоп | `остановлен` → не крутить `Retry` |
| Emit канона из provider | роли так не делают; гранта `bus.emit` нет |
