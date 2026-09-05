# Канон шины

Если слушаете шину в первый раз — [туториал](../start/03-dev.md) `dev`. Если эмитите канон — эта глава + полный контракт [api/02-canon-bus](../api/02-canon-bus.md). Грант и роли — [карта ролей](01-roles.md). Доставка — [`wait`](02-wait.md) / `Ready::Bus`.

**Правило.** Гость передаёт `channel`, `payload`, опциональный `opaque`. Core штампует `id`, `ts`, `source.plugin_id` и `source.platform` ← `platform_id` манифеста. `system` только Core. Канон площадки без непустого `platform_id` — отказ.

## Вызов

Грант `bus.emit`, SDK feature `emitter` / `connector` (не consumer).

```text
bus_emit::emit(channel, &payload, opaque) -> Result<(), String>
```

- `channel` — канал площадки, не id плагина.
- `payload` — `types::Payload`.
- `opaque` — пусто или **JSON-текст** (хвост рядом с payload, не канон). Иначе `opaque is not JSON`. Секреты нельзя. Известные ключи Core: `audio_key` / `audio_kind`. Примеры — [api § Opaque](../api/02-canon-bus.md#opaque).

Нет гранта — `no grant bus.emit`. Штамп > 64 KiB JSON — drop, `TooLarge`. Подделать `plugin_id` нельзя. Один живой плагин на `platform_id`.

Helpers: `text_message`, `donation`, `follow`, `reward`, `viewer_count`, `money`, `text_fragment`, `sanitize_name_color`. Эталон emit — [`modus-examples/emitter`](../../../modus-examples/emitter); живая площадка — `modus new connector`.

## Кто какой payload

| Payload | `platform_id` | Кто |
| --- | --- | --- |
| `Message` / `Donation` / `Sub` / `Follow` / `Raid` / `ViewerCount` / `Reward` / `Moderation` | обязателен | коннектор / emitter этой площадки |
| `Custom` | не нужен | любой с `bus.emit` |
| `System` | — | только Core |

`platform_id` — короткое имя площадки (`twitch`), не `id` пакета. Это метка источника канона в `source.platform`, не «только роль connector».

## Поля (кратко)

Гость в `Ready::Bus` видит: `id`, `ts`, `source`, `payload`, `opaque?`, `flags`. Отдельного `kind` и `audio_key` нет (`audio_key` — в opaque / UI Core).

- **Message:** `user_id`, `display_name`, `fragments`, `name_color?` (`#`+6 hex или Core выкинет), `message_id?`, `rewarded` (очки канала в IRC). Badges в каноне нет.
- **Donation:** юзер + `Money { amount, currency }` + `fragments`. Валюта — договорённость (`RUB`, `BITS`, …), Core не нормализует.
- **Sub:** юзер, `months`, `tier?`, `gifted`, `gifter_*?`, `fragments`.
- **Follow:** юзер.
- **Raid:** `from_user_id`, `from_display_name`, `viewers`.
- **ViewerCount:** `count`. Core: `hide_chat`+`skip_alert`, без journal и без ленты; fanout и snapshot зрителей остаются.
- **Reward:** `reward_id`, `title`, `cost` (u32), `fragments` промпта, `image_url?`. Bits → `Donation`. Пара с `Message.rewarded` на Twitch возможна; Core авто-hide не делает.
- **Moderation:** факт с площадки (`delete`/`timeout`/`ban`/`unban`), не сам `chat.act`. Лента может убрать строки; journal не трём.
- **Custom:** `kind` + `fields`; `kind` ≠ имя канона.
- **System:** коды kebab (`plugin-crashed`, `auth-revoked`, `ws-closed`, …) — полный список в api.

## Фрагменты

Упорядоченный список, не HTML: `Text` / `Emote { id, alt, url? }` / `Mention` / `Url`. Коннектор режет тело по границам эмодзи и ссылок. Helper SDK — только `text_fragment`; остальное через `types`. `https:` в `Emote.url` — для pin кэша. Подробности и пример — [api](../api/02-canon-bus.md#фрагменты).

## Flags

После фильтров: `hide_chat`, `skip_alert`, `highlight`, `mask?`. **Payload сырой.** `hide_chat` ≠ «события не было». `highlight` ≠ `Message.rewarded`.

## `chat.act` — не emit

| | `bus.emit` | `chat.act` |
| --- | --- | --- |
| Что | факт уже случился | просьба send/delete/timeout/ban/unban |
| Кто | connector / emitter | commander / композер Core |
| Куда | шина → subscribe | очередь → коннектор `platform_id` |
| Ответ | нет | `chat_complete` |

Цепочка: `act` → парк → `Ready::Act` → протокол → `complete` → на шину только отдельный `emit` факта с площадки. Командир `complete`/канон не делает. [`modus-examples/emitter`](../../../modus-examples/emitter) после `Act` эмитит — имитация площадки в `dev`.

Шторм: 10 `act`/с на плагин, 5/с у Core. Текст send ≤ 500. Эталон: `modus new commander` + `modus new connector`.

Inbox 64 — [wait](02-wait.md). Слушатель: [`modus-examples/consumer`](../../../modus-examples/consumer).
