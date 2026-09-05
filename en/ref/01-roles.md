# Role map

If this is your first plugin — `new` roles in the [tutorial](../start/02-roles.md). If you need feature × grant × reference — this chapter.

**Rule.** The guest is always on world **`plugin`** (full guest API). Rights — only manifest + approve + deny on the call. Soft-link: a known modus import without a grant — `pack`/load ok; call without cap — `Err`. `wasi:*` / foreign — always refuse (`запрещённый импорт …` / `лишний импорт …`).

SDK: **one** Cargo feature = code preset (helpers / re-export), not another WIT world. Host — world `runtime` (same superset); the guest does not choose it.

Names below are SDK modules (`net_ws`), not WIT packages. Capability → WIT mapping — appendix of this reference.

## Base (no grant needed)

Every package has: `self_info`, `log`, `wait`, `types`, `clock`, `settings`, `assets`. Listening on the bus after `subscribe` is base, not `bus.emit`.

`chat_complete` — no grant (part of full `plugin`).

## By grant

| Grant | SDK module (typical feature re-export) | Note |
| --- | --- | --- |
| `bus.emit` | `bus_emit` (`emitter` / `connector`) | |
| `auth.token` | `auth_token` (`connector`) | |
| `net.http` | `net_http` | |
| `net.ws` | `net_ws` | |
| `alert.enqueue` | `alert_enqueue` (`alerter`) | |
| `storage.kv` | `storage_kv` (`store`) | |
| `chat.act` | `chat_act` (`commander`) | |
| `ui.slot` | `ui_slot` + slot `web` and/or `panel` | |
| `media.cache` | `media_cache` | |
| `media.audio` | `media_audio` (`player`) | |
| `bridge.obs` | `bridge` (`bridge`) | |
| `media.embed` | `media_embed` (`embedder`) | |
| `catalog.publish` | `catalog` (`provider`) | |
| `history.read` | `history_read` | |
| `rates.publish` | `rates_publish` (`rates`) | |
| `rates.convert` | `rates` (`alerter`) | convert → base; rate table — Core / `rates.publish` |

`bus.emit` in the manifest requires a non-empty `platform_id`. Canon without the field — `нет platform_id`. One live plugin per `platform_id`; a second — `platform_id … уже занят`. `platform_id` is a short platform name, not the package `id`.

## Roles

| Role | `new` feature | Required grants | Typical modules beyond base | Reference | Does not |
| --- | --- | --- | --- | --- | --- |
| `consumer` | `consumer` | none | — | [`plugins/consumer`](../../../plugins/consumer), SDK | emit, network, `chat.act` |
| `emitter` | `emitter` | `bus.emit` | `bus_emit`, `chat_complete` | [`plugins/fixture`](../../../plugins/fixture), SDK | platform login and socket |
| `connector` | `connector` | usually `auth.token` + `net.http` + `net.ws` + `bus.emit` + `media.cache` | `auth_token`, `net_http`, `net_ws`, `bus_emit`, `chat_complete`, `media_cache` | [`plugins/twitch`](../../../plugins/twitch), SDK | draw UI, KV, alert queue |
| `provider` | `provider` | `net.http` + `net.ws` + `media.cache` + `catalog.publish` | `net_http`, `net_ws`, `media_cache`, `catalog` | [`plugins/7tv`](../../../plugins/7tv), SDK | `platform_id`, canon, `bus.emit` |
| `widget` | `widget` | `ui.slot` + `"slots": ["web"]` and/or `["panel"]` | `ui_slot` | [`plugins/web-slot`](../../../plugins/web-slot), [`plugins/panel`](../../../plugins/panel), SDK | network, emit |
| `commander` | `commander` | `chat.act` | `chat_act` | [`plugins/commander`](../../../plugins/commander), SDK | emit canon, network |
| `alerter` | `alerter` | `alert.enqueue`, `ui.slot`, `history.read` (+ `rates.convert` for donation FX) | enqueue + web overlay + `rates` | [`plugins/alerter`](../../../plugins/alerter), SDK | Core queue; recovery via history |
| `store` | `store` | `storage.kv` | `storage_kv` + `settings` (base) | [`plugins/store`](../../../plugins/store), SDK | others' KV, secrets |
| `reader` | `reader` | `history.read` | `history_read` | [`plugins/reader`](../../../plugins/reader), SDK | emit, network, replay in `wait` |
| `player` | `player` | `media.audio` + `media.cache` | `media_audio`, `media_cache` | [`plugins/player`](../../../plugins/player), SDK | open device, TTS bypassing Core |
| `bridge` | `bridge` | `bridge.obs` + `bridge_requests` | `bridge` | [`plugins/obs-bridge`](../../../plugins/obs-bridge), SDK | raw socket bypassing allowlist |
| `embedder` | `embedder` | `ui.slot` + `media.embed` + `embed_hosts` + `"slots": ["web"]` and/or `["panel"]` | `ui_slot`, `media_embed` | [`plugins/embedder`](../../../plugins/embedder), SDK | proxy MP4, host `play`, youtube-dl |
| `rates` | `rates` | `net.http` + `rates.publish` | `net_http`, `rates_publish` | [`plugins/fx`](../../../plugins/fx), SDK | emit, UI, KV; rate in `opaque` |
| host | — | — | world `runtime` | no guest | guest does not set this world |

`modus new` writes every role in the table (including `panel` → feature `widget`). New package: one SDK feature. Raw bindgen without SDK is allowed, but not the reference.

The alerter places a ticket in Core's queue; display — its own `web` after `alert-play`. Voice — `media.audio` (player) or `custom` `tts.request` → performer with `media.audio`. Reference alerter without emit/audio — overlay title/body.

Commander: `chat.act` → host wakes the connector with `Ready::Act` → `chat_complete`. No live connector — immediate error. Moderation on the bus is emitted by the platform connector from the protocol, not by the commander from `complete`.

## Slots (`ui.slot`)

Manifest: `"capabilities": ["ui.slot"]` and `"slots": ["web"]` and/or `["panel"]`.

- no grant with non-empty `slots` — `slots требуют грант ui.slot`;
- grant without a slot — `ui.slot требует слот web или panel`;
- other slot — `слот … не поддерживается`.

**Web / OBS.** Deaf slot — `consumer` + `"slots": ["web"]` (static; wasm does not write into the DOM). Wasm ↔ page channel — grant `ui.slot` + `ui_slot::post` (role `widget`). Reference: [`plugins/web-slot`](../../../plugins/web-slot). Assets `assets/web/`. Several `web` at once ok. Images — `'self'` / `cache/{key}`. Frame `plugin` only to its own `plugin_id`. Foreign origin in an iframe — role `embedder` + grant `media.embed` + `embed_hosts`; without `embed_hosts` CSP `frame-src 'none'`; call without grant — refuse.

**Panel.** Dock in Core layout; the plugin does not create a window. One mode: native (`assets/panel.json`) or web (`assets/panel/` or the same `assets/web/`). Native reference: [`plugins/panel`](../../../plugins/panel). `modus new panel` / `modus new panel --mode web`.

## Consequence for `pack`

Full import-set + narrow manifest — ok. Unknown / WASI — refuse. Grant wider than feature — ok; call without grant is cut by Core/`dev`, not pack.
