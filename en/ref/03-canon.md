# Bus canon

If you listen on the bus for the first time — [tutorial](../start/03-dev.md) `dev`. If you emit canon — this chapter. Grant and world — [role map](01-roles.md). Delivery to the guest — [`wait`](02-wait.md) / `Ready::Bus`.

**Rule.** `id`, `ts`, `source.plugin_id` are stamped by Core. The guest passes channel, payload, and optional opaque. `system` only Core. Platform canon — with `platform_id` in the manifest.

## Call

Grant `bus.emit`, SDK role `emitter` / `connector` (not consumer).

```text
bus_emit::emit(channel, &payload, opaque) -> Result<(), String>
```

- `channel` — platform channel, not plugin id.
- `payload` — `types::Payload`.
- `opaque` — `Option<&str>`: empty or **JSON text**. Not JSON — `"opaque не JSON"`. Consumers do not parse the tail. Do not put secrets.

No grant — `"нет гранта bus.emit"`. Stamped event body > 64 KiB JSON — drop, `"TooLarge"`.

`source.platform` comes from the manifest `platform_id`. You cannot forge `plugin_id`.

Scaffold: `modus_sdk::text_message`, `donation`, `reward`, `money`, `text_fragment`. Emit reference — [`modus-examples/emitter`](../../../modus-examples/emitter); live platform — `modus new connector`.

## Who may emit which payload


| Payload                                                           | Needs `platform_id`           | Who                                                |
| ----------------------------------------------------------------- | ----------------------------- | -------------------------------------------------- |
| `Message` / `Donation` / `Sub` / `Follow` / `Raid` / `ViewerCount` / `Reward` / `Moderation` | yes, else `"нет platform_id"` | connector (or emitter fixture) of **this** platform |
| `Custom`                                                          | no (empty ok)                 | anyone with `bus.emit`                                 |
| `System`                                                          | —                             | Core only; guest — `"system только Core"`        |


One live plugin per `platform_id`; a second will not start: `"platform_id … уже занят"`. `platform_id` is a short platform name (`twitch`), not the package `id`.

`Moderation` on the bus — a fact from the platform, not `chat.act`. Fields: `target_user_id` (id, not nick), `target_display_name`, optional moderator, `message_id` for delete, `duration_sec` for timeout. The feed hides rows by event; we do not erase the journal. How this meets the commander — below.

`Reward` — channel points: platform `reward_id`, `title`, `cost` (u32, not `Money`), prompt `fragments`, `image_url?`. Bits stay `Donation`. Highlight and custom-with-text are not drawn in the feed (duplicate IRC `message.rewarded`); alert and journal remain.

`ViewerCount` — channel viewer gauge: `count` (u32). Channel/platform in `source`. Core always sets `hide_chat` and `skip_alert`, does **not** write to journal and does **not** put in the feed; fanout to subscribers and UI snapshot (`viewers:update`) remain. Offline / no stream — `count: 0`.

`Custom { kind, fields }` — `kind` is not a canon name (`message`, `donation`, `sub`, `follow`, `raid`, `viewer_count`, `reward`, `moderation`, `system`). Else `"custom не может маскировать канон"`. TTS request — `custom` kind `tts.request`, not voice in Core.

## `chat.act` — not emit

Two different channels.

| | `bus.emit` | `chat.act` |
| --- | --- | --- |
| What it is | event **already happened** (chat, donation, ban on platform) | **request** to do send / delete / timeout / ban / unban |
| Who calls | connector / emitter | commander or Core composer |
| Where it goes | bus → all `subscribe` | Core queue → one connector for this `platform_id` |
| Grant / role | `bus.emit`, `emitter`/`connector` | `chat.act`, `commander` |
| Reply | none (or emit error) | `chat_complete` with the same `id` |

Chain:

1. Commander saw `Ready::Bus` (someone else's message) or Core pressed “send”. Call `chat_act::act(job)`: `platform`, `channel`, `kind` (`Send` / `Delete` / `Timeout` / `Ban` / `Unban`), optionally text / `message_id` / `target_user_id` / `duration_sec`.
2. Host checks grant, validates job (empty send, timeout 0, no target — refuse), fills `account_id`, parks the job. No live connector for this platform — immediate error, no bus.
3. Connector in its `wait` gets `Ready::Act(req)` with job `id`. Runs the protocol (Twitch: PRIVMSG / Helix). Then `chat_complete::complete(&req.id, Ok(()) | Err(...))`. Foreign `id` — refuse. No `complete` within 15 s — error to the caller.
4. Nothing is placed on the bus by itself. A message or ban appears only if the **platform** sends it in the protocol, and the connector does a **separate** `bus.emit` (`Message` / `Moderation`).

The commander does not call `complete` and does not emit canon. In the `Act` branch the connector must not `emit` “from itself instead of the platform”: the fact comes from IRC/Helix, like a normal frame. [`modus-examples/emitter`](../../../modus-examples/emitter) also emits after `Act` — that is a platform **simulation** in `dev`, not a commander pattern.

Storm: 10 `act`/s per plugin, 5/s at Core. Send text ≤ 500. Job reference — `modus new commander`; execution — `modus new connector` (`handle_act`). `Ready::Act` in [wait](02-wait.md).

## Canon fields

- **Message:** `user_id`, `display_name`, `fragments`, `name_color?`, `message_id?` (platform id), `rewarded` (chat line for channel points: `highlighted-message` / `custom-reward-id`). Not `flags.highlight`.
- **Donation:** user + `Money { amount: f64, currency }` + `fragments`. Amount and currency (ISO or unit like `BITS`), not a string “100₽”.
- **Sub:** user, `months`, `tier?`, `gifted`, `gifter_id` / `gifter_name?`, `fragments`.
- **Follow:** user.
- **Raid:** `from_user_id`, `from_display_name`, `viewers`.
- **ViewerCount:** `count`. Not journal / not feed; Core forces hide_chat + skip_alert.
- **Reward:** channel points. Feed does not draw a row if it is highlight / prompt with text (IRC duplicate). Alert and journal remain.

Fragments — not HTML: `Text`, `Emote { id, alt, url? }` (`url` for `<img>`, prefer https), `Mention { user_id, display_name }`, `Url`.

`name_color`: only `#` + 6 hex (`#FF4500`). Else Core **drops** the color; emit does not fail.

## What the consumer sees

After Core filters the event has `flags`: `hide_chat`, `skip_alert`, `highlight`, `mask?`. **Payload is raw.** `hide_chat` is not “the event never happened”: journal and `Ready::Bus` get it; the feed may hide. Mask — for display, not for a guest parser.

Inbox 64, full — drop, see [wait](02-wait.md).

Listener reference: [`modus-examples/consumer`](../../../modus-examples/consumer) (logs kind, source, flags, text).
