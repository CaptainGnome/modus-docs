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
| `put` | put raw bytes (`audio/mpeg` or `audio/wav`) |
| `release` | release pin (after `MediaEnded` for player) |

Key is used by web slots as `cache/{key}` in `<img>` / CSP. Not a secret store.

## `media.audio`

Grant `media.audio`. Feature `player` (+ cache usually nearby).

```text
play(spec) -> Result<string, string>   // playback id (or cache-key for overlay TTS)
stop(id) -> Result<(), string>
duration-ms(spec) -> Result<u32, string>
list-voices() -> Result<list<voice>, string>
render-tts(tts) -> Result<string, string>  // cache only; Ok = 64-hex key
start-render-tts(tts) -> Result<string, string>  // Ok = request-id; Ready::tts-rendered
```

`spec`:

| Variant | Value |
| --- | --- |
| `asset(path)` | file from package `assets/` |
| `url(https\|cache-key)` | URL via host policy / cache |
| `tts(text)` | host TTS with Core default voice |
| `tts-ex({ text, voice? })` | same; optional SpVoice token override |

Core settings (chrome): `tts.voice` (default token), `tts.output` = `speakers` \| `overlay` \| `both`.

| `tts.output` | `play(tts*)` behavior | `play` Ok |
| --- | --- | --- |
| `speakers` | Speak to default device | uuid play-id |
| `overlay` | One synth → WAV in `media.cache`; no speakers | 64-hex `audioKey` |
| `both` | Same WAV → cache + rodio speakers | 64-hex `audioKey` |

`render-tts` synthesizes into cache **without** speakers and **without** play-id / `MediaEnded`; ignores `tts.output`. Use for sync prefetch.

`start-render-tts` returns a request-id immediately and finishes on `Ready::tts-rendered { request-id, key?, error? }` (background SpVoice → cache). Prefer this on the bus path so other events keep flowing. For alerts: `enqueue` with `pending-audio` right away, then `mark-ready` on `tts-rendered` (or wait for Core pending TTL → play without voice). Opaque `audio_key` → enqueue ready (no pending). Do not hold the cashier slot until Speak finishes. `pending-audio` / `mark-ready` is a generic cashier contract: the same path works for third-party TTS (network → `media.cache.put` → `mark-ready`), not only SpVoice.

Guest posts overlay audio via `ui.slot` / `audioKey` (same as voice donations). Mute silences speakers only; overlay put still happens. `list-voices` needs the same grant; empty on non-Windows / null tests.

Track end or successful `stop` → `Ready::MediaEnded(id)`. Player releases related cache-keys.

In `dev` audio is a stub/log; `list-voices` / `render-tts` / `start-render-tts` return stubs (`tts-rendered` with empty/synthetic outcome per `dev` host).

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
