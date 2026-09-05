# Player

The role plays sound through the host (`media.audio`): Core chooses device and driver. The reference listens for donation/sub, takes `audio_key` from `opaque` or falls back to asset `sfx.mp3`, and after `MediaEnded` releases the cache pin.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `player` |
| Required | `media.audio`, `media.cache` |

Map — [ref/01-roles](../ref/01-roles.md). API — [api/08-media-cache-audio-embed](../api/08-media-cache-audio-embed.md).

## Manifest

```json
{
  "id": "com.modus.player",
  "name": "Player",
  "version": "0.1.0",
  "abi": 2,
  // play/stop + MediaEnded; release cache pins after URL tracks
  "capabilities": ["media.audio", "media.cache"]
}
```

| Field | Why |
| --- | --- |
| `media.audio` | `play` / `stop`, wake `MediaEnded` |
| `media.cache` | `release` after a URL track ends |

## Code

**Bus → play.** Donation and sub only. Spec: `Url(cache-key)` or `Asset("sfx.mp3")`. Playback id goes into `pending`.

```rust
Ready::Bus(event) => {
    // only donation/sub trigger SFX in this reference
    if !matches!(&event.payload, Payload::Donation(_) | Payload::Sub(_)) {
        continue;
    }
    // connector/fixture may stash cache key in opaque JSON
    let audio_key = audio_key_from_opaque(event.opaque.as_deref());
    let spec = match audio_key.as_ref() {
        Some(key) => Spec::Url(key.clone()),      // play pinned cache entry
        None => Spec::Asset("sfx.mp3".into()),    // fallback packaged file
    };
    match media_audio::play(&spec) {
        // remember id → optional key so MediaEnded can release
        Ok(id) => { pending.insert(id, audio_key); }
        Err(err) => log::log(Level::Warn, &err),
    }
}
```

**End / Stop.** `MediaEnded` → `media_cache::release` only if played by cache-key. On `Stop` — release all remaining.

```rust
Ready::MediaEnded(id) => {
    // Some(Some(key)) = played via Spec::Url — unpin after finish
    if let Some(Some(key)) = pending.remove(&id) {
        let _ = media_cache::release(&key);
    } else {
        // Asset playback or already gone — just drop the map entry
        pending.remove(&id);
    }
}
```

**Opaque.** Simple parse of `"audio_key":"…"` from the event's JSON tail (connector/other plugin puts the key after `media_cache::ensure`).

```rust
fn audio_key_from_opaque(opaque: Option<&str>) -> Option<String> {
    let raw = opaque?; // no opaque → caller uses Asset fallback
    let marker = "\"audio_key\"";
    // …find quote pair after marker — teaching parser, not full JSON
}
```

No TTS in this reference: `Spec::Tts` / `custom` `tts.request` — a separate path of the same grant.

## Assets

| Path | Purpose |
| --- | --- |
| `assets/sfx.mp3` | fallback `Spec::Asset` |

## Run

```powershell
modus new <role>  # scaffold, then modus dev <dir>
```

In `dev`, audio is often a stub/log — do not expect Core parity. Full crate: [`modus new player`](modus new player).

## Typical host errors

| String / situation | Meaning |
| --- | --- |
| `no grant media.audio` | `play` without capability |
| `no grant media.cache` | `release` / ensure without grant |
| URL refused | network policy / no pin in cache |
| no `MediaEnded` in `dev` | possible CLI stub |

See [ref/04-errors](../ref/04-errors.md), [ref/09-limits](../ref/09-limits.md).
