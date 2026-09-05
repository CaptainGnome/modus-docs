# Канон шины

**Правило.** Гость передаёт `channel`, `payload` и опциональный `opaque`. Core штампует `id`, `ts`, `source.plugin_id` и кладёт `source.platform` из `platform_id` манифеста. `system` только Core. Канон площадки без непустого `platform_id` — отказ.

Сжатый обзор — [ref/03-canon](../ref/03-canon.md). Emit: [`modus-examples/emitter`](../../../modus-examples/emitter), `modus new connector`. Слушатель: [`modus-examples/consumer`](../../../modus-examples/consumer).

## Вызов emit

Грант `bus.emit`, SDK feature `emitter` / `connector` (re-export `bus_emit`).

```text
bus_emit::emit(channel, &payload, opaque) -> Result<(), String>
```

| Аргумент | Правило |
| --- | --- |
| `channel` | канал площадки (логин / room), не `id` плагина |
| `payload` | `types::Payload` |
| `opaque` | `Option<&str>`: пусто/`None` или **валидный JSON-текст**. Иначе `opaque is not JSON`. Не секреты; не ABI между плагинами без договорённости |

Нет гранта — `no grant bus.emit`. JSON штампованного события > 64 KiB — drop, `TooLarge`.

Подделать `source.plugin_id` нельзя. Один живой плагин на `platform_id`; второй — `platform_id … already taken`.

Helpers SDK (`consumer` / `emitter` / `connector`): `text_message`, `donation`, `follow`, `reward`, `viewer_count`, `money`, `text_fragment`, `sanitize_name_color`. Остальные payload и фрагменты — руками через `types::*`.

## Событие у гостя (`Ready::Bus`)

После фильтров Core гость видит `wait::Event` (не UI-конверт Core):

| Поле | Кто ставит | Смысл |
| --- | --- | --- |
| `id` | Core | UUID события |
| `ts` | Core | unix ms |
| `source.plugin_id` | Core | пакет, который эмитил |
| `source.platform` | Core ← `platform_id` | метка площадки в каноне (`twitch`, `fixture`, …); у `Custom` может быть пусто |
| `source.channel` | гость при emit | канал |
| `payload` | гость (или Core для `System`) | tagged union |
| `opaque` | гость → Core → строка JSON | `Option<String>` у гостя |
| `flags` | Core после фильтров | `hide_chat`, `skip_alert`, `highlight`, `mask?` |

Отдельного поля `kind` у гостя нет — kind из варианта `payload`. Поля `audio_key` в guest Event **нет**: ключ кэша звука, если нужен, кладут в `opaque` (например `{"audio_key":"…"}`). В React-ленте Core может поднять `audioKey` из opaque/скина — это не ABI гостя.

**Payload сырой.** `hide_chat` — не «события не было»: journal (кроме `ViewerCount`) и `Ready::Bus` получают событие; лента может скрыть. `mask` — подмена текста **для показа** в UI, не для парсера гостя.

## Кто какой payload

| Payload | Нужен `platform_id` | Кто |
| --- | --- | --- |
| `Message` / `Donation` / `Sub` / `Follow` / `Raid` / `ViewerCount` / `Reward` / `Moderation` | да, иначе `no platform_id` | коннектор / emitter этой площадки |
| `Custom` | нет (пусто ок) | любой с `bus.emit` |
| `System` | — | только Core; гость — `system is Core-only` |

Имена канона (запрещены как `Custom.kind`): `message`, `donation`, `sub`, `follow`, `raid`, `viewer_count`, `reward`, `moderation`, `system`.

## Payload

Wire у Core UI — JSON tagged (`"type":"message"`, поля camelCase, snake_case aliases на вход). У гостя — WIT/SDK enums (`Payload::Message(Message { … })`). Ниже поля как в SDK.

### Message

| Поле | Смысл |
| --- | --- |
| `user_id`, `display_name` | автор |
| `fragments` | упорядоченные куски тела (см. ниже). Не HTML |
| `name_color?` | только `#` + 6 hex; иначе Core **выкинет** цвет, emit не падает |
| `message_id?` | id сообщения на площадке (для `chat.act` delete и т.п.) |
| `rewarded` | строка чата за очки канала (`msg-id=highlighted-message` / `custom-reward-id`). Не `flags.highlight`, не badges |

Badges в каноне **нет** — только то, что в таблице.

### Donation

`user_id`, `display_name`, `money: Money { amount: f64, currency }`, `fragments` (часто текст доната; можно пусто).

`currency` — договорённость авторов (ISO вроде `RUB`/`USD` или юнит `BITS`). Core сумму/валюту не нормализует. Не строка «100₽» вместо `Money`.

### Sub

`user_id`, `display_name`, `months`, `tier?`, `gifted`, `gifter_id?`, `gifter_name?`, `fragments` (сообщение саба; можно пусто).

### Follow

`user_id`, `display_name`.

### Raid

`from_user_id`, `from_display_name`, `viewers` (u32).

### ViewerCount

`count` (u32). Площадка/канал — в `source`. Offline / нет стрима — `count: 0`.

Core всегда форсит `hide_chat` + `skip_alert`, **не** пишет journal и **не** шлёт в UI-ленту; fanout подписчикам `Ready::Bus` и snapshot зрителей (`viewers:update`) остаются.

### Reward

Очки канала / аналог: `user_id`, `display_name`, `reward_id`, `title`, `cost` (u32, **не** `Money`), `fragments` (промпт зрителя; пусто если промпта нет), `image_url?`.

Bits / деньги — `Donation`, не `Reward`.

На Twitch часто пара событий: EventSub `Reward` + IRC `Message` с `rewarded: true`. Core **не** прячет автоматически ни одно из них; дубль в ленте — фильтры стримера / политика коннектора, не правило ABI.

`https:` в `image_url` и в `Emote.url` Core может подхватить для pin кэша картинок.

### Moderation

Факт модерации **с площадки**, не результат `chat.act` сам по себе.

| Поле | Смысл |
| --- | --- |
| `action` | `delete` / `timeout` / `ban` / `unban` |
| `target_user_id` | id цели, не ник |
| `target_display_name` | отображаемое имя |
| `moderator_id?`, `moderator_name?` | кто применил |
| `message_id?` | у `delete` — id сообщения |
| `duration_sec?` | у `timeout` |

Лента может убрать строки по событию; journal Core **не** стирает. На шину после `chat.act` попадает только если площадка прислала кадр и коннектор сделал отдельный `emit`.

### Custom

`Custom { kind: String, fields: Vec<(String, String)> }`.

`kind` не имя канона — иначе `custom cannot mask canon`. Примеры договорённостей (не Core ABI): `tts.request`, `obs.set-scene`.

### System (только Core)

| Поле | Смысл |
| --- | --- |
| `code` | см. таблицу |
| `plugin_id?` | затронутый пакет |
| `account_id?` | аккаунт auth |
| `platform?` | площадка |
| `detail?` | свободный хвост |

Точные строки `code` (kebab-case):

| Code |
| --- |
| `plugin-disabled` |
| `plugin-crashed` |
| `plugin-quarantined` |
| `plugin-rollback` |
| `plugin-reconnecting` |
| `plugin-load-failed` |
| `plugin-removed` |
| `auth-connected` |
| `auth-disconnected` |
| `auth-revoked` |
| `auth-login-failed` |
| `network-resume` |
| `ws-closed` |
| `unknown` |

## Фрагменты

`fragments` — **упорядоченный** список кусков. Это не «текст + отдельно эмодзи»: коннектор режет тело сообщения на последовательность `Text` / `Emote` / `Mention` / `Url`. Не HTML и не markdown от гостя.

| Вариант SDK | Wire `type` | Поля | Зачем |
| --- | --- | --- | --- |
| `Fragment::Text(s)` | `text` | `text` | обычный текст, пробелы сохранять в кусках |
| `Fragment::Emote(Emote { id, alt, url })` | `emote` | `id`, `alt`, `url?` | картинка эмодзи; `alt` — fallback / a11y |
| `Fragment::Mention(Mention { … })` | `mention` | `user_id`, `display_name` | @упоминание с id |
| `Fragment::Url(href)` | `url` | `href` | ссылка отдельным куском |

Пример смысла (не полный код):

```text
Text("hi ") + Emote{id, alt:"Kappa", url:Some("https://…")} + Text(" there")
```

Правила для автора коннектора:

1. Режь по границам эмодзи/URL/mention площадки; не оставляй сырой HTML.
2. `Emote.url` — лучше `https:`; Core для pin смотрит только `https:`. Без URL UI может взять каталог/`alt`.
3. После emit обычно `media_cache::ensure` на URL эмодзи (см. эталон коннектора).
4. `@nick` можно оставить в `Text` или выделить `Mention`, если есть стабильный `user_id`.
5. SDK helper есть только `text_fragment(…)` → `Fragment::Text`. Emote/Mention/Url — конструкторы `types`.
6. Командиры и снифферы часто склеивают только `Text` (или `alt` эмодзи) — не рассчитывай, что все читают полный список.

Где бывают `fragments`: `Message`, `Donation`, `Sub`, `Reward`. У `Follow` / `Raid` / `ViewerCount` / `Moderation` — нет.

## Opaque и flags

| | Правило |
| --- | --- |
| `opaque` | JSON-хвост; пример для player: `{"audio_key":"…"}` после `media_cache` |
| `flags.hide_chat` | лента может скрыть; шина и journal (кроме viewers) — да |
| `flags.skip_alert` | касса алертов пропускает |
| `flags.highlight` | подсветка в UI; не путать с `Message.rewarded` |
| `flags.mask?` | подмена текста в ленте |

## `chat.act` ≠ emit

| | `bus.emit` | `chat.act` |
| --- | --- | --- |
| Что | факт уже случился | просьба сделать действие |
| Кто | connector / emitter | commander / композер Core |
| Куда | шина → subscribe | очередь Core → один коннектор `platform_id` |
| Ответ | нет | `chat_complete` |

Цепочка: `act` → парк → `Ready::Act` → протокол → `complete` → факт на шину **только** если площадка прислала кадр и коннектор сделал отдельный `emit`. Подробнее — [06-kv-act-alerts](06-kv-act-alerts.md).

Inbox 64 — [01-lifecycle-wait](01-lifecycle-wait.md).

Следующая глава — [ошибки хоста](03-errors.md).
