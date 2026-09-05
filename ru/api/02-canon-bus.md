# Канон шины

**Правило.** `id`, `ts`, `source.plugin_id` штампует **Core**. Гость передаёт канал, payload и опциональный opaque. `system` только Core. Канон площадки — с `platform_id` в манифесте.

Сжатый обзор — [ref/03-canon](../ref/03-canon.md). Emit: [`modus-examples/emitter`](../../../modus-examples/emitter), `modus new connector`. Слушатель: [`modus-examples/consumer`](../../../modus-examples/consumer).

## Вызов emit

Грант `bus.emit`, feature `emitter` / `connector`.

```text
bus_emit::emit(channel, &payload, opaque) -> Result<(), String>
```

| Аргумент | Правило |
| --- | --- |
| `channel` | канал площадки, не id плагина |
| `payload` | `types::Payload` |
| `opaque` | `Option<&str>`: пусто или **валидный JSON-текст**. Не JSON — `opaque не JSON`. Потребители хвост не разбирают. Секреты не класть |

Нет гранта — `нет гранта bus.emit`. Тело штампованного события > 64 KiB — drop, `TooLarge`.

`source.platform` ← `platform_id` манифеста. Подделать `plugin_id` нельзя.

Helpers SDK (`emitter`/`connector`/`consumer`): `text_message`, `donation`, `follow`, `reward`, `viewer_count`, `money`, `text_fragment`, `sanitize_name_color`.

## Кто какой payload

| Payload | Нужен `platform_id` | Кто |
| --- | --- | --- |
| `Message` / `Donation` / `Sub` / `Follow` / `Raid` / `ViewerCount` / `Reward` / `Moderation` | да, иначе `нет platform_id` | коннектор / emitter этой площадки |
| `Custom` | нет (пусто ок) | любой с `bus.emit` |
| `System` | — | только Core; гость — `system только Core` |

Один живой плагин на `platform_id`.

## Поля payload

### Message

| Поле | Смысл |
| --- | --- |
| `user_id`, `display_name` | автор |
| `fragments` | куски текста (не HTML) |
| `name_color?` | только `#` + 6 hex; иначе Core **выкинет** цвет, emit не падает |
| `message_id?` | id площадки |
| `rewarded` | строка чата за очки канала (`highlighted-message` / custom-reward). Не `flags.highlight` |

### Donation

Юзер + `Money { amount: f64, currency }` + `fragments`. Валюта — ISO или юнит (`BITS`), не строка «100₽».

### Sub

Юзер, `months`, `tier?`, `gifted`, `gifter_id` / `gifter_name?`, `fragments`.

### Follow

`user_id`, `display_name`.

### Raid

`from_user_id`, `from_display_name`, `viewers`.

### ViewerCount

`count` (u32). Core всегда ставит `hide_chat` + `skip_alert`, **не** пишет journal и **не** кладёт в ленту; fanout подписчикам и snapshot UI остаются. Offline — `count: 0`.

### Reward

Очки канала: `reward_id`, `title`, `cost` (u32, не `Money`), `fragments` промпта, `image_url?`. Bits остаются `Donation`. Хайлайт/кастом с текстом в ленте не рисуем (дубль IRC); алерт и журнал остаются.

### Moderation

Факт с площадки, **не** `chat.act`. Поля: `action` (`delete`/`timeout`/`ban`/`unban`), `target_user_id` (id, не ник), `target_display_name`, опционально модератор, `message_id` у delete, `duration_sec` у timeout. Лента прячет по событию; journal не трём.

### Custom

`Custom { kind, fields }`. `kind` не имя канона (`message`, `donation`, `sub`, `follow`, `raid`, `viewer_count`, `reward`, `moderation`, `system`) — иначе `custom не может маскировать канон`. TTS-запрос — `custom` kind `tts.request`, не голос в Core.

### System (только Core)

Коды (`SystemCode`): plugin disabled/crashed/quarantined/rollback/reconnecting/load-failed/removed; auth connected/disconnected/revoked/login-failed; `network-resume`; `ws-closed`; `unknown`. Поля: `code`, опционально `plugin_id`, `account_id`, `platform`, `detail`.

## Фрагменты

| Вид | Поля |
| --- | --- |
| `Text` | строка |
| `Emote` | `id`, `alt`, `url?` (лучше https для `<img>`) |
| `Mention` | `user_id`, `display_name` |
| `Url` | строка URL |

Не HTML и не markdown разметка от гостя.

## Opaque и flags

| | Правило |
| --- | --- |
| `opaque` | опциональный JSON-хвост; не для секретов; не контракт между плагинами без договорённости |
| `flags` после фильтров Core | `hide_chat`, `skip_alert`, `highlight`, `mask?` |

**Payload сырой.** `hide_chat` — не «события не было»: journal и `Ready::Bus` его получают; лента может скрыть. Маска — для показа, не для парсера гостя.

## `chat.act` ≠ emit

Два канала:

| | `bus.emit` | `chat.act` |
| --- | --- | --- |
| Что | факт уже случился | просьба сделать действие |
| Кто | connector / emitter | commander / композер Core |
| Куда | шина → subscribe | очередь Core → один коннектор `platform_id` |
| Ответ | нет | `chat_complete` |

Цепочка: `act` → парк → `Ready::Act` → протокол → `complete` → факт на шину **только** если площадка прислала кадр и коннектор сделал отдельный `emit`. Подробнее — [06-kv-act-alerts](06-kv-act-alerts.md).

Inbox 64 — [01-lifecycle-wait](01-lifecycle-wait.md).

Следующая глава — [ошибки хоста](03-errors.md).
