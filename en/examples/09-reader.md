# Reader

The role reads the canon journal via `history.read` and listens to the live bus in parallel. History is **not** a replay into `Ready::Bus`: a separate API for pages and recovery (alerter does the same). The reference only logs payload kinds and flags.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `reader` |
| Required grant | `history.read` |
| Base | `wait` + `subscribe` for live `Bus` |

Map — [ref/01-roles](../ref/01-roles.md). API — [api/09-bridge-history-rates-catalog](../api/09-bridge-history-rates-catalog.md).

## Manifest

```json
{
  "id": "com.modus.reader",
  "name": "Reader",
  "version": "0.1.0",
  "abi": 2,
  // sole grant — paginate the host canon journal
  "capabilities": ["history.read"]
  // no emit / network — role does not write the bus or go outside
}
```

| Field | Why |
| --- | --- |
| `history.read` | `history_read::read(cursor, limit)` |
| no emit / network | role does not write the bus or go outside |

## Code

**Dump.** In `init` and at the start of `run` — a page with no cursor, up to 50 events. Each is logged with the `history` tag.

```rust
fn dump_history() {
    // None cursor = newest page; limit 50 — teaching size
    match history_read::read(None, 50) {
        Ok(page) => {
            // these are NOT Ready::Bus — only API results
            for event in page.events {
                log_bus("history", &event); // tag distinguishes dump vs live
            }
        }
        Err(err) => log::log(Level::Warn, &err), // missing grant / stop
    }
}
```

**Live bus.** After dump — ordinary `wait`; `Ready::Bus` with the same formatter and the `bus` tag.

```rust
fn run() {
    dump_history(); // past journal first
    loop {
        match wait::wait() {
            Ready::Stop => return,
            // live events after subscribe — same formatter, different tag
            Ready::Bus(event) => log_bus("bus", &event),
            // ignore Act / Alert / Ui / …
        }
    }
}
```

**Parse.** `payload_kind` / `payload_text` — teaching switch over `Payload::*` and `Fragment::Text`. Flags: `hide_chat`, `skip_alert`, `highlight`, `mask`.

```rust
fn log_bus(tag: &str, event: &Event) {
    log::log(
        Level::Info,
        &format!(
            // tag | kind | plugin:channel | key flags | text preview
            "{tag} {} {}:{} hide={} skip={} … {}",
            payload_kind(&event.payload),
            event.source.plugin_id,
            event.source.channel,
            event.flags.hide_chat,  // overlay may omit from chat feed
            event.flags.skip_alert, // alerter must not enqueue
            payload_text(&event.payload)
        ),
    );
}
```

The reference does not use `page.alert_shown` — that is for alerter recovery ([07-alerter](07-alerter.md)).

## Assets

None. Only `manifest` + `src/lib.rs`.

## Run

```powershell
modus dev plugins/reader
```

Teaching emits from `dev` appear both in history (if the host writes the journal) and as `Ready::Bus`. Full crate: [`../../../plugins/reader`](../../../plugins/reader).

## Typical host errors

| String / situation | Meaning |
| --- | --- |
| `нет гранта history.read` | call without capability |
| empty page | journal still empty / other instance |
| expecting history in `wait` | model error: history only via `read` |

See [ref/02-wait](../ref/02-wait.md), [ref/04-errors](../ref/04-errors.md).
