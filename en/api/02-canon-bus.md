# Bus canon

**Rule.** `id`, `ts`, `source.plugin_id` are stamped by **Core**. The guest passes channel, payload, and optional opaque. `system` is Core-only. Platform canon — with `platform_id` in the manifest.

Compressed overview — [ref/03-canon](../ref/03-canon.md). Emit: [`modus-examples/emitter`](../../../modus-examples/emitter), `modus new connector`. Listener: [`modus-examples/consumer`](../../../modus-examples/consumer).

## Emit call

Grant `bus.emit`, feature `emitter` / `connector`.

```text
bus_emit::emit(channel, &payload, opaque) -> Result<(), String>
```

| Argument | Rule |
| --- | --- |
| `channel` | platform channel, not plugin id |
| `payload` | `types::Payload` |
| `opaque` | `Option<&str>`: empty or **valid JSON text**. Not JSON — `opaque не JSON`. Consumers do not parse the tail. Do not put secrets |

No grant — `нет гранта bus.emit`. Stamped event body > 64 KiB — drop, `TooLarge`.

`source.platform` ← manifest `platform_id`. Forging `plugin_id` is impossible.

SDK helpers (`emitter`/`connector`/`consumer`): `text_message`, `donation`, `follow`, `reward`, `viewer_count`, `money`, `text_fragment`, `sanitize_name_color`.

## Who emits which payload

| Payload | Needs `platform_id` | Who |
| --- | --- | --- |
| `Message` / `Donation` / `Sub` / `Follow` / `Raid` / `ViewerCount` / `Reward` / `Moderation` | yes, else `нет platform_id` | connector / emitter of that platform |
| `Custom` | no (empty ok) | anyone with `bus.emit` |
| `System` | — | Core only; guest — `system только Core` |

One live plugin per `platform_id`.

## Payload fields

### Message

| Field | Meaning |
| --- | --- |
| `user_id`, `display_name` | author |
| `fragments` | text pieces (not HTML) |
| `name_color?` | only `#` + 6 hex; otherwise Core **drops** the color, emit does not fail |
| `message_id?` | platform id |
| `rewarded` | chat string for channel points (`highlighted-message` / custom-reward). Not `flags.highlight` |

### Donation

User + `Money { amount: f64, currency }` + `fragments`. Currency — ISO or unit (`BITS`), not a “100₽” string.

### Sub

User, `months`, `tier?`, `gifted`, `gifter_id` / `gifter_name?`, `fragments`.

### Follow

`user_id`, `display_name`.

### Raid

`from_user_id`, `from_display_name`, `viewers`.

### ViewerCount

`count` (u32). Core always sets `hide_chat` + `skip_alert`, does **not** write journal and does **not** put in the feed; subscriber fanout and UI snapshot remain. Offline — `count: 0`.

### Reward

Channel points: `reward_id`, `title`, `cost` (u32, not `Money`), prompt `fragments`, `image_url?`. Bits stay `Donation`. Highlight/custom with text is not drawn in the feed (IRC duplicate); alert and journal remain.

### Moderation

Fact from the platform, **not** `chat.act`. Fields: `action` (`delete`/`timeout`/`ban`/`unban`), `target_user_id` (id, not nick), `target_display_name`, optional moderator, `message_id` on delete, `duration_sec` on timeout. Feed hides by event; journal is not erased.

### Custom

`Custom { kind, fields }`. `kind` must not be a canon name (`message`, `donation`, `sub`, `follow`, `raid`, `viewer_count`, `reward`, `moderation`, `system`) — else `custom не может маскировать канон`. TTS request — `custom` kind `tts.request`, not voice in Core.

### System (Core only)

Codes (`SystemCode`): plugin disabled/crashed/quarantined/rollback/reconnecting/load-failed/removed; auth connected/disconnected/revoked/login-failed; `network-resume`; `ws-closed`; `unknown`. Fields: `code`, optional `plugin_id`, `account_id`, `platform`, `detail`.

## Fragments

| Kind | Fields |
| --- | --- |
| `Text` | string |
| `Emote` | `id`, `alt`, `url?` (prefer https for `<img>`) |
| `Mention` | `user_id`, `display_name` |
| `Url` | URL string |

Not HTML and not markdown markup from the guest.

## Opaque and flags

| | Rule |
| --- | --- |
| `opaque` | optional JSON tail; not for secrets; not a contract between plugins without agreement |
| `flags` after Core filters | `hide_chat`, `skip_alert`, `highlight`, `mask?` |

**Payload is raw.** `hide_chat` is not “event never happened”: journal and `Ready::Bus` still receive it; the feed may hide. Mask — for display, not for guest parsers.

## `chat.act` ≠ emit

Two channels:

| | `bus.emit` | `chat.act` |
| --- | --- | --- |
| What | fact already happened | request to perform an action |
| Who | connector / emitter | commander / Core composer |
| Where | bus → subscribe | Core queue → one `platform_id` connector |
| Reply | none | `chat_complete` |

Chain: `act` → park → `Ready::Act` → protocol → `complete` → fact on the bus **only** if the platform sent a frame and the connector did a separate `emit`. Details — [06-kv-act-alerts](06-kv-act-alerts.md).

Inbox 64 — [01-lifecycle-wait](01-lifecycle-wait.md).

Next chapter — [host errors](03-errors.md).
