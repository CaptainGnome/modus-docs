# Embedder

The role embeds a foreign origin in a slot iframe: grant `media.embed` + `embed_hosts` in the manifest. Wasm picks the URL and checks `allowed`; the page mounts an iframe only for an allowed host. Not youtube-dl and not host `play` of a foreign MP4.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `embedder` |
| Required | `ui.slot`, `media.embed` |
| Manifest | `"slots": ["web", "panel"]`, `embed_hosts`, optional `user_theme` |

Map — [ref/01-roles](../ref/01-roles.md). API — [api/08-media-cache-audio-embed](../api/08-media-cache-audio-embed.md), slots — [api/07-ui-slots-panel](../api/07-ui-slots-panel.md).

## Manifest

```json
{
  "id": "com.modus.embedder",
  "abi": 2,
  // post to overlay/panel + ask host whether URL may iframe
  "capabilities": ["ui.slot", "media.embed"],
  "slots": ["web", "panel"],
  // Core theme CSS vars on the web page
  "user_theme": true,
  // CSP frame-src allowlist — empty means 'none'
  "embed_hosts": ["www.youtube.com"]
}
```

| Field | Why |
| --- | --- |
| `ui.slot` + `slots` | `ui_slot::post` → overlay / panel |
| `media.embed` | `allowed` / `hosts` |
| `embed_hosts` | CSP `frame-src`; empty → `'none'` |
| `user_theme` | Core theme on the web page |

## Code

**Start.** Rickroll as embed URL; post JSON with `embedUrl` and status.

```rust
fn init() {
    wait::subscribe(); // Bus commands + Ui panel clicks
    // default track: build embed URL + label, then post
    post_url(&Track::Rickroll.embed_url(), Track::Rickroll.label());
}

fn post_url(url: &str, label: &str) {
    // host checks URL host against embed_hosts BEFORE we tell the page
    if !media_embed::allowed(url) {
        log::log(Level::Warn, "embed url not allowed");
        return; // do not post — page must not iframe a refused origin
    }
    // overlay mounts iframe when embedUrl is non-empty
    let body = format!(
        "{{\"embedUrl\":\"{}\",\"status\":{{\"text\":\"{}\"}}}}",
        json_escape(url),
        json_escape(label),
    );
    let _ = ui_slot::post(body.as_bytes());
}
```

**Chat and panel.** `Ready::Bus` Message → commands `!play` / `!pause` / `!stop` / `!skip` / YouTube id. `Ready::Ui` — panel clicks (`rickroll`, `play`, …).

```rust
Ready::Bus(event) => {
    // parse !play / !pause / YouTube id from Message text
    if let Some(action) = action_from_bus(&event) {
        state.apply(action); // may call post_url / post_cmd
    }
}
Ready::Ui(payload) => {
    // panel button id → same Action enum as chat
    if let Some(action) = action_from_ui(&click_id(&payload)) {
        state.apply(action);
    }
}
```

**Custom URL.** Before mount — `allowed` again; otherwise warn and return.

```rust
Action::Custom { id, label } => {
    // build YouTube embed URL under allowed host
    let url = format!("https://www.youtube.com/embed/{id}?{EMBED_QUERY}");
    if !media_embed::allowed(&url) { /* warn; return */ }
    post_url(&url, &label); // only posts after second allowed check
}
```

Play/pause without changing URL — `post_cmd("play"|"pause")`; the page postMessages into the YouTube iframe. Stop → `embedUrl: ""`.

## Assets

| Path | Purpose |
| --- | --- |
| `assets/web/` | `index.html`, `overlay.js`, `overlay.css` — mount iframe / stub |
| `assets/panel.json` | track buttons and transport |

Without `embed_hosts` or without the grant the iframe will not open (CSP / API refuse).

## Run

```powershell
modus new embedder  # then: modus dev <dir> --ui
```

Needs a message emitter with commands (fixture/twitch) or panel clicks. Full crate: [`modus new embedder`](modus new embedder).

## Typical host errors

| String / situation | Meaning |
| --- | --- |
| `нет гранта media.embed` | call without capability |
| `allowed` = false / warn in log | host not in `embed_hosts` |
| `slots требуют грант ui.slot` | slots without grant |
| duplicates in `embed_hosts` | manifest refuse at pack/load |
| CSP `frame-src 'none'` | empty allowlist |

See [ref/04-errors](../ref/04-errors.md), [ref/01-roles](../ref/01-roles.md#слоты-uislot).
