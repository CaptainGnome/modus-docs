# Bus canon

**Rule.** The guest passes `channel`, `payload`, and optional `opaque`. Core stamps `id`, `ts`, `source.plugin_id` and sets `source.platform` from the manifest `platform_id`. `system` is Core-only. Platform canon without a non-empty `platform_id` is refused.

Compressed overview — [ref/03-canon](../ref/03-canon.md). Emit: [`modus-examples/emitter`](../../../modus-examples/emitter), `modus new connector`. Listener: [`modus-examples/consumer`](../../../modus-examples/consumer).

## Emit call

Grant `bus.emit`, SDK feature `emitter` / `connector` (re-exports `bus_emit`).

```text
bus_emit::emit(channel, &payload, opaque) -> Result<(), String>
```

| Argument | Rule |
| --- | --- |
| `channel` | platform channel (login / room), not plugin `id` |
| `payload` | `types::Payload` |
| `opaque` | `Option<&str>`: empty/`None` or **valid JSON text**. Else `opaque is not JSON`. No secrets; not an inter-plugin ABI without agreement |

No grant — `no grant bus.emit`. Stamped event JSON > 64 KiB — drop, `TooLarge`.

Forging `source.plugin_id` is impossible. One live plugin per `platform_id`; a second — `platform_id … already taken`.

SDK helpers (`consumer` / `emitter` / `connector`): `text_message`, `donation`, `follow`, `reward`, `viewer_count`, `money`, `text_fragment`, `sanitize_name_color`. Other payloads and fragments — build with `types::*`.

## Event at the guest (`Ready::Bus`)

After Core filters the guest sees `wait::Event` (not the Core UI envelope):

| Field | Who sets | Meaning |
| --- | --- | --- |
| `id` | Core | event UUID |
| `ts` | Core | unix ms |
| `source.plugin_id` | Core | package that emitted |
| `source.platform` | Core ← `platform_id` | platform label in canon (`twitch`, `fixture`, …); may be empty for `Custom` |
| `source.channel` | guest on emit | channel |
| `payload` | guest (or Core for `System`) | tagged union |
| `opaque` | guest → Core → JSON string | `Option<String>` for the guest |
| `flags` | Core after filters | `hide_chat`, `skip_alert`, `highlight`, `mask?` |

No separate `kind` field for the guest — kind comes from the `payload` variant. There is **no** `audio_key` on the guest Event: if a cache key is needed, put it in `opaque` (e.g. `{"audio_key":"…"}`). Core’s React feed may lift `audioKey` from opaque/skin — that is not guest ABI.

**Payload is raw.** `hide_chat` is not “the event never happened”: journal (except `ViewerCount`) and `Ready::Bus` still receive it; the feed may hide. `mask` replaces text **for display** in UI, not for guest parsers.

## Who emits which payload

| Payload | Needs `platform_id` | Who |
| --- | --- | --- |
| `Message` / `Donation` / `Sub` / `Follow` / `Raid` / `ViewerCount` / `Reward` / `Moderation` | yes, else `no platform_id` | connector / emitter of that platform |
| `Custom` | no (empty ok) | anyone with `bus.emit` |
| `System` | — | Core only; guest — `system is Core-only` |

Canon names (forbidden as `Custom.kind`): `message`, `donation`, `sub`, `follow`, `raid`, `viewer_count`, `reward`, `moderation`, `system`.

## Payload

Core UI wire is tagged JSON (`"type":"message"`, camelCase fields, snake_case aliases on input). Guest side is WIT/SDK enums (`Payload::Message(Message { … })`). Fields below match the SDK.

### Message

| Field | Meaning |
| --- | --- |
| `user_id`, `display_name` | author |
| `fragments` | ordered body pieces (see below). Not HTML |
| `name_color?` | only `#` + 6 hex; otherwise Core **drops** the color, emit does not fail |
| `message_id?` | platform message id (for `chat.act` delete, etc.) |
| `rewarded` | chat line for channel points (`msg-id=highlighted-message` / `custom-reward-id`). Not `flags.highlight`, not badges |

There are **no** badges in canon — only the fields above.

### Donation

`user_id`, `display_name`, `money: Money { amount: f64, currency }`, `fragments` (often donation text; may be empty).

`currency` is author convention (ISO like `RUB`/`USD` or unit `BITS`). Core does not normalize amount/currency. Not a “100₽” string instead of `Money`.

### Sub

`user_id`, `display_name`, `months`, `tier?`, `gifted`, `gifter_id?`, `gifter_name?`, `fragments` (sub message; may be empty).

### Follow

`user_id`, `display_name`.

### Raid

`from_user_id`, `from_display_name`, `viewers` (u32).

### ViewerCount

`count` (u32). Platform/channel live in `source`. Offline / no stream — `count: 0`.

Core always forces `hide_chat` + `skip_alert`, does **not** write journal and does **not** send to the UI feed; `Ready::Bus` fanout and the viewers snapshot (`viewers:update`) remain.

### Reward

Channel points / equivalent: `user_id`, `display_name`, `reward_id`, `title`, `cost` (u32, **not** `Money`), `fragments` (viewer prompt; empty if none), `image_url?`.

Bits / money stay `Donation`, not `Reward`.

On Twitch you often get a pair: EventSub `Reward` + IRC `Message` with `rewarded: true`. Core does **not** auto-hide either; feed duplicates are streamer filters / connector policy, not ABI.

`https:` in `image_url` and `Emote.url` may be picked up by Core for image cache pins.

### Moderation

A moderation **fact from the platform**, not the `chat.act` call itself.

| Field | Meaning |
| --- | --- |
| `action` | `delete` / `timeout` / `ban` / `unban` |
| `target_user_id` | target id, not nick |
| `target_display_name` | display name |
| `moderator_id?`, `moderator_name?` | who applied it |
| `message_id?` | on `delete` — message id |
| `duration_sec?` | on `timeout` |

The feed may remove rows from the event; Core journal is **not** erased. After `chat.act` something hits the bus only if the platform sent a frame and the connector did a separate `emit`.

### Custom

`Custom { kind: String, fields: Vec<(String, String)> }`.

`kind` must not be a canon name — else `custom cannot mask canon`. Example conventions (not Core ABI): `tts.request`, `obs.set-scene`.

### System (Core only)

| Field | Meaning |
| --- | --- |
| `code` | see table |
| `plugin_id?` | affected package |
| `account_id?` | auth account |
| `platform?` | platform |
| `detail?` | free-form tail |

Exact `code` strings (kebab-case):

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

## Fragments

`fragments` is an **ordered** list of pieces. Not “plain text plus separate emotes”: the connector splits the body into a sequence of `Text` / `Emote` / `Mention` / `Url`. Not HTML and not markdown from the guest.

| SDK variant | Wire `type` | Fields | Why |
| --- | --- | --- | --- |
| `Fragment::Text(s)` | `text` | `text` | ordinary text; keep spaces inside pieces |
| `Fragment::Emote(Emote { id, alt, url })` | `emote` | `id`, `alt`, `url?` | emote image; `alt` for fallback / a11y |
| `Fragment::Mention(Mention { … })` | `mention` | `user_id`, `display_name` | @mention with id |
| `Fragment::Url(href)` | `url` | `href` | link as its own piece |

Meaning example (not full code):

```text
Text("hi ") + Emote{id, alt:"Kappa", url:Some("https://…")} + Text(" there")
```

Connector author rules:

1. Split on platform emote/URL/mention boundaries; do not leave raw HTML.
2. Prefer `https:` for `Emote.url`; Core only pins `https:` URLs. Without URL the UI may use catalog/`alt`.
3. After emit usually `media_cache::ensure` on emote URLs (see connector reference).
4. `@nick` may stay in `Text` or become `Mention` when you have a stable `user_id`.
5. SDK helper is only `text_fragment(…)` → `Fragment::Text`. Emote/Mention/Url — `types` constructors.
6. Commanders and sniffers often flatten only `Text` (or emote `alt`) — do not assume every consumer reads the full list.

Where `fragments` appear: `Message`, `Donation`, `Sub`, `Reward`. Not on `Follow` / `Raid` / `ViewerCount` / `Moderation`.

## Opaque and flags

| | Rule |
| --- | --- |
| `opaque` | JSON tail; player example: `{"audio_key":"…"}` after `media_cache` |
| `flags.hide_chat` | feed may hide; bus and journal (except viewers) — yes |
| `flags.skip_alert` | alert cashier skips |
| `flags.highlight` | UI highlight; not the same as `Message.rewarded` |
| `flags.mask?` | text replacement in the feed |

## `chat.act` ≠ emit

| | `bus.emit` | `chat.act` |
| --- | --- | --- |
| What | fact already happened | request to perform an action |
| Who | connector / emitter | commander / Core composer |
| Where | bus → subscribe | Core queue → one `platform_id` connector |
| Reply | none | `chat_complete` |

Chain: `act` → park → `Ready::Act` → protocol → `complete` → fact on the bus **only** if the platform sent a frame and the connector did a separate `emit`. Details — [06-kv-act-alerts](06-kv-act-alerts.md).

Inbox 64 — [01-lifecycle-wait](01-lifecycle-wait.md).

Next chapter — [host errors](03-errors.md).
