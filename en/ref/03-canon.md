# Bus canon

First time listening — [tutorial](../start/03-dev.md) `dev`. Emitting canon — this chapter plus the full contract [api/02-canon-bus](../api/02-canon-bus.md). Grants and roles — [role map](01-roles.md). Delivery — [`wait`](02-wait.md) / `Ready::Bus`.

**Rule.** The guest passes `channel`, `payload`, optional `opaque`. Core stamps `id`, `ts`, `source.plugin_id` and `source.platform` ← manifest `platform_id`. `system` is Core-only. Platform canon without a non-empty `platform_id` is refused.

## Call

Grant `bus.emit`, SDK feature `emitter` / `connector` (not consumer).

```text
bus_emit::emit(channel, &payload, opaque) -> Result<(), String>
```

- `channel` — platform channel, not plugin id.
- `payload` — `types::Payload`.
- `opaque` — empty or **JSON text** (side-channel next to payload, not canon). Else `opaque is not JSON`. No secrets. Known Core keys: `audio_key` / `audio_kind`. Examples — [api § Opaque](../api/02-canon-bus.md#opaque).

No grant — `no grant bus.emit`. Stamp > 64 KiB JSON — drop, `TooLarge`. Forging `plugin_id` is impossible. One live plugin per `platform_id`.

Helpers: `text_message`, `donation`, `follow`, `reward`, `viewer_count`, `money`, `text_fragment`, `sanitize_name_color`. Emit reference — [`modus-examples/emitter`](../../../modus-examples/emitter); live platform — `modus new connector`.

## Who emits which payload

| Payload | `platform_id` | Who |
| --- | --- | --- |
| `Message` / `Donation` / `Sub` / `Follow` / `Raid` / `ViewerCount` / `Reward` / `Moderation` | required | connector / emitter of that platform |
| `Custom` | not required | anyone with `bus.emit` |
| `System` | — | Core only |

`platform_id` is a short platform name (`twitch`), not package `id`. It labels the canon source in `source.platform`, not “connector role only”.

## Fields (short)

On `Ready::Bus` the guest sees: `id`, `ts`, `source`, `payload`, `opaque?`, `flags`. No separate `kind` or `audio_key` (`audio_key` lives in opaque / Core UI).

- **Message:** `user_id`, `display_name`, `fragments`, `name_color?` (`#`+6 hex or Core drops it), `message_id?`, `rewarded` (channel points on IRC). No badges in canon.
- **Donation:** user + `Money { amount, currency }` + `fragments`. Currency is convention (`RUB`, `BITS`, …); Core does not normalize.
- **Sub:** user, `months`, `tier?`, `gifted`, `gifter_*?`, `fragments`.
- **Follow:** user.
- **Raid:** `from_user_id`, `from_display_name`, `viewers`.
- **ViewerCount:** `count`. Core: `hide_chat`+`skip_alert`, no journal and no feed; fanout and viewers snapshot remain.
- **Reward:** `reward_id`, `title`, `cost` (u32), prompt `fragments`, `image_url?`. Bits → `Donation`. Pairing with `Message.rewarded` on Twitch is fine; Core does not auto-hide.
- **Moderation:** fact from the platform (`delete`/`timeout`/`ban`/`unban`), not `chat.act` itself. Feed may remove rows; journal is kept.
- **Custom:** `kind` + `fields`; `kind` ≠ a canon name.
- **System:** kebab codes (`plugin-crashed`, `auth-revoked`, `ws-closed`, …) — full list in api.

## Fragments

Ordered list, not HTML: `Text` / `Emote { id, alt, url? }` / `Mention` / `Url`. Connector splits the body on emote and link boundaries. SDK helper — only `text_fragment`; rest via `types`. Prefer `https:` in `Emote.url` for cache pin. Details — [api](../api/02-canon-bus.md#fragments).

## Flags

After filters: `hide_chat`, `skip_alert`, `highlight`, `mask?`. **Payload is raw.** `hide_chat` ≠ “event never happened”. `highlight` ≠ `Message.rewarded`.

## `chat.act` — not emit

| | `bus.emit` | `chat.act` |
| --- | --- | --- |
| What | fact already happened | request send/delete/timeout/ban/unban |
| Who | connector / emitter | commander / Core composer |
| Where | bus → subscribe | queue → `platform_id` connector |
| Reply | none | `chat_complete` |

Chain: `act` → park → `Ready::Act` → protocol → `complete` → bus only via a separate platform-fact `emit`. Commander does not `complete`/emit canon. [`modus-examples/emitter`](../../../modus-examples/emitter) emitting after `Act` is a `dev` platform simulation.

Storm: 10 `act`/s per plugin, 5/s at Core. Send text ≤ 500. Reference: `modus new commander` + `modus new connector`.

Inbox 64 — [wait](02-wait.md). Listener: [`modus-examples/consumer`](../../../modus-examples/consumer).
