# Канон шины

Если слушаете шину в первый раз — [туториал](../start/03-dev.md) `dev`. Если эмитите канон — эта глава. Грант и world — [карта ролей](01-roles.md). Доставка в гостя — `wait` [/](02-wait.md) `Ready::Bus`.

**Правило.** `id`, `ts`, `source.plugin_id` штампует Core. Гость передаёт канал, payload и опциональный opaque. `system` только Core. Канон площадки — с `platform_id` в манифесте.

## Вызов

Грант `bus.emit`, роль SDK `emitter` / `connector` (не consumer).

```text
bus_emit::emit(channel, &payload, opaque) -> Result<(), String>
```

- `channel` — канал площадки, не id плагина.
- `payload` — `types::Payload`.
- `opaque` — `Option<&str>`: пусто или **JSON-текст**. Не JSON — `"opaque не JSON"`. Потребители хвост не разбирают. Секреты не класть.

Нет гранта — `"нет гранта bus.emit"`. Тело штампованного события > 64 KiB JSON — drop, `"TooLarge"`.

`source.platform` берётся из `platform_id` манифеста. Подделать `plugin_id` нельзя.

Каркас: `modus_sdk::text_message`, `donation`, `reward`, `money`, `text_fragment`. Эталон emit — `[plugins/fixture](../../plugins/fixture)`, живая площадка — `[plugins/twitch](../../plugins/twitch)`.

## Кто может какой payload


| Payload                                                           | Нужен `platform_id`           | Кто                                                |
| ----------------------------------------------------------------- | ----------------------------- | -------------------------------------------------- |
| `Message` / `Donation` / `Sub` / `Follow` / `Raid` / `ViewerCount` / `Reward` / `Moderation` | да, иначе `"нет platform_id"` | коннектор (или emitter-фикстура) **этой** площадки |
| `Custom`                                                          | нет (пусто ок)                | любой с `bus.emit`                                 |
| `System`                                                          | —                             | только Core; гость — `"system только Core"`        |


Один живой плагин на `platform_id`; второй не встанет: `"platform_id … уже занят"`. `platform_id` — короткое имя площадки (`twitch`), не `id` пакета.

`Moderation` на шине — факт с площадки, не `chat.act`. Поля: `target_user_id` (id, не ник), `target_display_name`, опционально модератор, `message_id` у delete, `duration_sec` у timeout. Лента прячет строки по событию; журнал не трём. Как это стыкуется с командиром — ниже.

`Reward` — очки канала: `reward_id` площадки, `title`, `cost` (u32, не `Money`), `fragments` промпта, `image_url?`. Bits остаются `Donation`. Хайлайт и кастом с текстом в ленте не рисуем (дубль IRC `message.rewarded`); алерт и журнал остаются.

`ViewerCount` — gauge зрителей канала: `count` (u32). Канал/площадка в `source`. Core всегда ставит `hide_chat` и `skip_alert`, **не** пишет в journal и **не** кладёт в ленту; fanout подписчикам и snapshot в UI (`viewers:update`) остаются. Offline / нет стрима — `count: 0`.

`Custom { kind, fields }` — `kind` не имя канона (`message`, `donation`, `sub`, `follow`, `raid`, `viewer_count`, `reward`, `moderation`, `system`). Иначе `"custom не может маскировать канон"`. TTS-запрос — `custom` kind `tts.request`, не голос в Core.

## `chat.act` — не emit

Два разных канала.

| | `bus.emit` | `chat.act` |
| --- | --- | --- |
| Что это | событие **уже случилось** (чат, донат, бан на площадке) | **просьба** сделать send / delete / timeout / ban / unban |
| Кто зовёт | коннектор / emitter | командир или композер Core |
| Куда попадает | шина → все `subscribe` | очередь Core → один коннектор этой `platform_id` |
| Грант / роль | `bus.emit`, `emitter`/`connector` | `chat.act`, `commander` |
| Ответ | нет (или ошибка emit) | `chat_complete` с тем же `id` |

Цепочка:

1. Командир увидел `Ready::Bus` (чужое сообщение) или Core нажал «отправить». Зовут `chat_act::act(job)`: `platform`, `channel`, `kind` (`Send` / `Delete` / `Timeout` / `Ban` / `Unban`), опционально текст / `message_id` / `target_user_id` / `duration_sec`.
2. Хост проверяет грант, валидирует job (пустое send, timeout 0, нет цели — отказ), подставляет `account_id`, паркует job. Нет живого коннектора этой площадки — сразу ошибка, шины нет.
3. Коннектор в своём `wait` получает `Ready::Act(req)` с `id` job. Исполняет протокол (Twitch: PRIVMSG / Helix). Потом `chat_complete::complete(&req.id, Ok(()) | Err(...))`. Чужой `id` — отказ. Нет `complete` за 15 с — ошибка вызывающему.
4. На шину само по себе ничего не кладётся. Сообщение или бан появятся, только если **площадка** пришлёт это в протоколе, и коннектор сделает **отдельный** `bus.emit` (`Message` / `Moderation`).

Командир `complete` не вызывает и канон не эмитит. Коннектор в ветке `Act` не должен `emit` «от себя вместо площадки»: факт — из IRC/Helix, как обычный кадр. [`plugins/fixture`](../../plugins/fixture) после `Act` ещё и эмитит — это **имитация** площадки в `dev`, не образец командира.

Шторм: 10 `act`/с на плагин, 5/с у Core. Текст send ≤ 500. Эталон заявки — [`plugins/commander`](../../plugins/commander); исполнение — [`plugins/twitch`](../../plugins/twitch) (`handle_act`). `Ready::Act` в [wait](02-wait.md).

## Поля канона

- **Message:** `user_id`, `display_name`, `fragments`, `name_color?`, `message_id?` (id площадки), `rewarded` (строка чата за очки канала: `highlighted-message` / `custom-reward-id`). Не `flags.highlight`.
- **Donation:** юзер + `Money { amount: f64, currency }` + `fragments`. Сумма и валюта (ISO или юнит вроде `BITS`), не строка «100₽».
- **Sub:** юзер, `months`, `tier?`, `gifted`, `gifter_id` / `gifter_name?`, `fragments`.
- **Follow:** юзер.
- **Raid:** `from_user_id`, `from_display_name`, `viewers`.
- **ViewerCount:** `count`. Не journal / не лента; Core форсит hide_chat + skip_alert.
- **Reward:** очки канала. Лента не рисует строку, если это хайлайт / промпт с текстом (дубль IRC). Алерт и журнал остаются.

Фрагменты — не HTML: `Text`, `Emote { id, alt, url? }` (`url` для `<img>`, лучше https), `Mention { user_id, display_name }`, `Url`.

`name_color`: только `#` + 6 hex (`#FF4500`). Иначе Core **выкинет** цвет, emit не падает.

## Что видит consumer

После фильтров Core у события `flags`: `hide_chat`, `skip_alert`, `highlight`, `mask?`. **Payload сырой.** `hide_chat` — не «события не было»: журнал и `Ready::Bus` его получают, лента может скрыть. Маска — для показа, не для гостя-парсера.

Inbox 64, полный — drop, см. [wait](02-wait.md).

Эталон слушателя: `[plugins/consumer](../../plugins/consumer)` (логирует kind, source, flags, текст).