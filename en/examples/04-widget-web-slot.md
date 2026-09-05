# Widget / web-slot

Widget with `ui.slot` grant and `web` slot: wasm ↔ overlay page via `ui_slot::post` / `Ready::Ui`. Reference — click counter over a chat feed (bus arrives in JS over the host WebSocket).

## Feature and grants

| | |
| --- | --- |
| SDK feature | `widget` |
| Required grants | `ui.slot` + `"slots": ["web"]` |
| Modules | `ui_slot` (+ base `wait`) |
| Does not | network, emit |
| Map | [ref/01-roles](../ref/01-roles.md) |

Reference: [`plugins/web-slot`](../../../plugins/web-slot). Silent web with no wasm channel — consumer + `slots: ["web"]` without `ui.slot`.

## Manifest

```json
{
  "id": "com.modus.web.slot",
  // grant to post/receive Ui frames with the page
  "capabilities": ["ui.slot"],
  // must pair with ui.slot — opens OBS/browser overlay assets/web/
  "slots": ["web"],
  // streamer theme variables injected into CSS
  "user_theme": true,
  // subscribe to provider catalog slice (7TV emotes in overlay.js)
  "consumes": ["emotes"]
}
```

| Field | Why |
| --- | --- |
| `ui.slot` + `slots` | post/Ui channel; without the pair — load refuses |
| `user_theme` | streamer theme for CSS |
| `consumes` | catalog subscription (7TV `emotes` in overlay.js) |

## Code

**Post to DOM.** Bytes go to the page as a `plugin` frame.

```rust
fn post_n(n: u32) {
    // tiny JSON the overlay.js reads as { n } for the counter HUD
    let body = format!("{{\"n\":{n}}}");
    // host wraps bytes as a plugin frame on the slot WebSocket
    if let Err(err) = ui_slot::post(body.as_bytes()) {
        log::log(Level::Warn, &err); // e.g. no grant / slot closed
    }
}
```

**Page click → `Ready::Ui`.** Button sends JSON; wasm bumps the counter and `post`s again.

```rust
fn run() {
    let mut n = 0u32; // counter lives in wasm, not in the page
    loop {
        match wait::wait() {
            Ready::Stop => return,
            // any Ui payload (button click) — bump and push new state
            Ready::Ui(_) => {
                n = n.saturating_add(1); // no wrap on spam-clicks
                post_n(n);               // page updates #count
            }
            _ => {} // bus feed is drawn in JS from host WS, not here
        }
    }
}
```

`subscribe` in `init` — if you want to listen to the bus from wasm; the feed in the reference is drawn in JS from the host WS.

## Assets

| Path | Purpose |
| --- | --- |
| [`assets/web/index.html`](../../../plugins/web-slot/assets/web/index.html) | HUD `#count` + `#inc`, `#feed` |
| [`assets/web/overlay.js`](../../../plugins/web-slot/assets/web/overlay.js) | WS: snapshot/batch/catalog/`plugin` |
| [`assets/web/overlay.css`](../../../plugins/web-slot/assets/web/overlay.css) | feed / emote styles |

Emote images — `cache/{key}` (not an arbitrary origin).

## How to run

```powershell
modus new widget --id com.you.overlay --dir overlay
modus dev ../../../plugins/web-slot --ui click.json
```

`--ui` emulates a click without a browser. Full overlay — Core / OBS browser source. See [api/07-ui-slots-panel](../api/07-ui-slots-panel.md).

## Typical host errors

| Situation | String |
| --- | --- |
| `slots` without grant | `slots требуют грант ui.slot` |
| grant without slot | `ui.slot требует слот web или panel` |
| unsupported slot | `слот … не поддерживается` |
| post without `ui.slot` | `нет гранта ui.slot` |
