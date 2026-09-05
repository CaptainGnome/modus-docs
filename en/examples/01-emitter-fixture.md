# Emitter / fixture

Role emits canon onto the bus without platform login. Fixture is a tutorial “fake chat”: messages, donations, follow, reward, viewers, and replies to `chat.act` via `chat_complete`.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `emitter` |
| Required grants | `bus.emit` (+ non-empty `platform_id`) |
| Also in reference | `media.cache` (voice in donation opaque) |
| Modules | `bus_emit`, `chat_complete` |
| Map | [ref/01-roles](../ref/01-roles.md) |

Reference: [`modus-examples/emitter`](../../../modus-examples/emitter).

## Manifest

```json
{
  "id": "com.modus.fixture",
  "name": "Fixture",
  "version": "0.1.0",
  "author": "modus",
  "abi": 2,
  // bus.emit = write canon; media.cache = pin voice bytes for donation opaque
  "capabilities": ["bus.emit", "media.cache"],
  // platform label stamped on every emit — required, else host refuses
  "platform_id": "fixture"
}
```

| Field | Why |
| --- | --- |
| `capabilities` | right to write the bus (+ audio cache for voice donation) |
| `platform_id` | platform label in canon; without it emit refuses |

## Code

**Batch emit in `init`.** Host is ready; SDK helpers build `Payload`, channel `"dev"`.

```rust
fn init() {
    // build a chat Message payload (user/login/text; optional color/badges = None)
    let message = text_message("fixture", "fixture", "fixture hello", None, None);
    // push onto bus channel "dev" — consumers with subscribe see Ready::Bus
    let _ = bus_emit::emit("dev", &message, None);
    // donation helper: amount/currency + text fragments as body
    let donation = donation(
        "fixture", "fixture", 5.0, "USD",
        vec![text_fragment("thanks for the stream!")],
    );
    let _ = bus_emit::emit("dev", &donation, None);
    // follow / reward / viewer_count — same emit pattern, different helpers
}
```

**Voice donation via assets + cache.** Bytes from package → cache key → JSON in `opaque`.

```rust
fn emit_voice_donation() -> Result<(), String> {
    // read packaged audio from assets/ (not network)
    let bytes = assets::read("sfx.mp3")?;
    // pin bytes in host cache → opaque key other plugins (player) can play
    let key = media_cache::put("audio/mpeg", &bytes)?;
    // opaque JSON: fixture marker + cache key + kind for consumers
    let opaque = format!(
        r#"{{"fixture":"voice","audio_key":"{key}","audio_kind":"voice"}}"#
    );
    let payload = donation("fixture", "fixture-voice", 42.0, "USD",
        vec![text_fragment("voice donation")]);
    // Some(opaque) attaches side-channel metadata; canon body stays clean
    bus_emit::emit("dev", &payload, Some(&opaque))
}
```

**Act reply.** Commander sends a job → host wakes `Ready::Act` → fixture emits canon and calls `complete`.

```rust
fn handle_act(req: ActRequest) {
    // run ban/timeout/say locally (fixture fakes the platform)
    match execute(&req) {
        // always complete — commander waits on this ack
        Ok(()) => chat_complete::complete(&req.id, Ok(())),
        Err(err) => chat_complete::complete(&req.id, Err(err.as_str())),
    }
}
```

## Assets

| Path | Purpose |
| --- | --- |
| [`assets/sfx.mp3`](../../../modus-examples/emitter/assets/sfx.mp3) | short sound for `media_cache::put` in voice donation |

No settings / web / panel on fixture.

## How to run

```powershell
modus new emitter --id com.you.fixture --dir fixture
modus dev ../modus-examples/emitter
```

A consumer beside it will see `fixture hello`. Act check: `modus dev … --act <json>` ([api/11-cli-dev](../api/11-cli-dev.md)).

## Typical host errors

| Situation | String |
| --- | --- |
| No `bus.emit` | `no grant bus.emit` |
| Empty / missing `platform_id` | `no platform_id` |
| Second live plugin for same platform | `platform_id … already taken` |
| Emit `system` | `system is Core-only` |
| Event > 64 KiB | `TooLarge` |
