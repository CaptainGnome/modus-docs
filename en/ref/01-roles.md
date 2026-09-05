# Role map

If this is your first plugin — `new` roles in the [tutorial](../start/02-roles.md). If you need feature × grant × reference — this chapter. Code walkthroughs — [examples/](../examples/overview.md).

**Rule.** Roles do **not** split WIT worlds. Every guest uses one world — **`plugin`** (full guest API). What you may call is only manifest + approve + deny on the call.

- Soft-link: a known modus import without a grant — `pack`/load ok; call without cap — `Err`.
- `wasi:*` / foreign — always refuse (`forbidden import …` / `extra import …`).
- `modus new <role>` = one Cargo **feature** (helpers / re-export preset) + a manifest template. Not a separate world.

Names below are SDK modules (`net_ws`), not WIT packages. Capability → WIT — [appendix](11-wit.md).

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

`bus.emit` in the manifest requires a non-empty `platform_id`. Canon without the field — `no platform_id`. One live plugin per `platform_id`; a second — `platform_id … already taken`. `platform_id` is a short platform name, not the package `id`.

## Roles (`modus new`)

Every row is a preset of the same world `plugin`. Feature column = `new` argument / `Cargo.toml` feature.

| Role | Feature | Required grants | Typical modules beyond base | Reference | Does not |
| --- | --- | --- | --- | --- | --- |
| `consumer` | `consumer` | none | — | [`modus-examples/consumer`](https://github.com/CaptainGnome/modus-examples/tree/master/consumer) | emit, network, `chat.act` |
| `emitter` | `emitter` | `bus.emit` | `bus_emit`, `chat_complete` | [`modus-examples/emitter`](https://github.com/CaptainGnome/modus-examples/tree/master/emitter) | platform login and socket |
| `connector` | `connector` | usually `auth.token` + `net.http` + `net.ws` + `bus.emit` + `media.cache` | `auth_token`, `net_http`, `net_ws`, `bus_emit`, `chat_complete`, `media_cache` | [`connector-replay`](https://github.com/CaptainGnome/modus-examples/tree/master/connector-replay), `modus new connector` | UI, KV, alert queue |
| `provider` | `provider` | `net.http` + `net.ws` + `media.cache` + `catalog.publish` | `net_http`, `net_ws`, `media_cache`, `catalog` | `modus new provider` | `platform_id`, canon, `bus.emit` |
| `widget` | `widget` | `ui.slot` + `"slots": ["web"]` and/or `["panel"]` | `ui_slot` | [`modus-examples/widget`](https://github.com/CaptainGnome/modus-examples/tree/master/widget) | network, emit |
| `panel` | `widget` | same as `widget`, panel assets | `ui_slot` | `modus new panel` / `--mode web` | network, emit |
| `commander` | `commander` | `chat.act` | `chat_act` | `modus new commander` | emit canon, network |
| `alerter` | `alerter` | `alert.enqueue`, `ui.slot`, `history.read` (+ `rates.convert` for donation FX) | enqueue + web overlay + `rates` | `modus new alerter` | Core till; recovery via history |
| `store` | `store` | `storage.kv` | `storage_kv` + `settings` (base) | `modus new store` | others' KV, secrets |
| `reader` | `reader` | `history.read` | `history_read` | `modus new reader` | emit, network, replay in `wait` |
| `player` | `player` | `media.audio` + `media.cache` | `media_audio`, `media_cache` | `modus new player` | open device, TTS bypassing Core |
| `bridge` | `bridge` | `bridge.obs` + `bridge_requests` | `bridge` | `modus new bridge` | raw socket bypassing allowlist |
| `embedder` | `embedder` | `ui.slot` + `media.embed` + `embed_hosts` + `"slots": ["web"]` and/or `["panel"]` | `ui_slot`, `media_embed` | `modus new embedder` | proxy MP4, host `play`, youtube-dl |
| `rates` | `rates` | `net.http` + `rates.publish` | `net_http`, `rates_publish` | `modus new rates` | emit, UI, KV; rate in `opaque` |

New package: **one** SDK feature. Two features at once — `compile_error`. Raw bindgen without SDK is allowed, but not the reference.

The alerter places a ticket in Core's till; display — its own `web` after `alert-play`. Voice — `media.audio` (player) or `custom` `tts.request` → performer with `media.audio`. Reference alerter without emit/audio — overlay title/body.

Commander: `chat.act` → host wakes the connector with `Ready::Act` → `chat_complete`. No live connector — immediate error. Moderation on the bus is emitted by the platform connector from the protocol, not by the commander from `complete`.

## Slots (`ui.slot`)

Manifest: `"capabilities": ["ui.slot"]` and `"slots": ["web"]` and/or `["panel"]`.

- slots without grant — `slots require grant ui.slot`;
- grant without a slot — `ui.slot requires web or panel slot`;
- other slot — `slot … is not supported`.

**Web / OBS.** Deaf slot — `consumer` + `"slots": ["web"]` (static; wasm does not write into the DOM). Wasm ↔ page channel — grant `ui.slot` + `ui_slot::post` (role `widget`). Reference: [`modus-examples/widget`](https://github.com/CaptainGnome/modus-examples/tree/master/widget). Assets `assets/web/`. Several `web` at once ok. Images — `'self'` / `cache/{key}`. Frame `plugin` only to its own `plugin_id`. Foreign origin in an iframe — role `embedder` + grant `media.embed` + `embed_hosts`; without `embed_hosts` CSP `frame-src 'none'`; call without grant — refuse.

**Panel.** Dock in Core layout; the plugin does not create an OS window. One mode: native (`assets/panel.json`) or web (`assets/panel/` or the same `assets/web/`). `modus new panel` / `modus new panel --mode web`.

## Consequence for `pack`

Full import-set + narrow manifest — ok. Unknown / WASI — refuse. Grant wider than feature — ok; call without grant is cut by Core/`dev`, not pack.
