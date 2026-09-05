# Media: cache, audio, embed

**Rule.** Binaries and sound go through the host. The guest does not open devices and does not download files with its own socket past `net.*` / cache. Embed — iframe allowlist only, not youtube-dl and not `play` of a foreign MP4 on the host.

References: cache/catalog — `modus new provider`; audio — `modus new player`; embed — `modus new embedder`.

## `media.cache`

Grant `media.cache`. Typically connector / provider / player.

```text
lookup(url) -> Option<string>          // cache-key or None
ensure(url) -> Result<string, string>  // download/pin → key
put(mime, bytes) -> Result<string, string>
release(key) -> Result<(), string>
```

| Call | Meaning |
| --- | --- |
| `lookup` | already in cache? |
| `ensure` | host fetches URL (https + allowlist like network) and pins |
| `put` | put raw bytes with mime |
| `release` | release pin (after `MediaEnded` for player) |

Key is used by web slots as `cache/{key}` in `<img>` / CSP. Not a secret store.

## `media.audio`

Grant `media.audio`. Feature `player` (+ cache usually nearby).

```text
play(spec) -> Result<string, string>   // playback id
stop(id) -> Result<(), string>
```

`spec`:

| Variant | Value |
| --- | --- |
| `asset(path)` | file from package `assets/` |
| `url(https)` | URL via host policy / cache |
| `tts(text)` | host-side synthesis (if available) |

Track end or successful `stop` → `Ready::MediaEnded(id)`. Player releases related cache-keys. Output device is chosen by Core, not the plugin.

TTS request from the bus: another plugin may emit `custom` kind `tts.request`; executor with `media.audio` plays. Reference alerter without audio — overlay only.

In `dev` audio is a stub/log as far as CLI allows; do not expect driver parity with Core.

## `media.embed`

Grant `media.embed` + manifest `embed_hosts` + usually `ui.slot` + web/panel `slots`. Feature `embedder`.

```text
hosts() -> list<string>     // copy of manifest allowlist
allowed(url) -> bool        // whether this URL may go in iframe
```

| Topic | Rule |
| --- | --- |
| `embed_hosts` empty / no cap | CSP `frame-src 'none'` |
| call without grant | rejected |
| guest job | decide which URL to insert; page sets iframe only if `allowed` |
| does not | proxy MP4, download, bypass wasm `hosts` |

Duplicates in `embed_hosts` — manifest reject. Host format same as `hosts`.

Link to slots — [07-ui-slots-panel](07-ui-slots-panel.md). Network — [05-emit-auth-net](05-emit-auth-net.md).

Next chapter — [history, rates, catalog](09-bridge-history-rates-catalog.md).
