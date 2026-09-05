# Lifecycle and `wait`

**Rule.** In `run`, the long loop is only via `wait::wait`. `Ready::Stop` and `HostError::is_stop()` exit the loop, not into backoff. There is no second thread and no callbacks from wasm: the host wakes `wait`.

Compressed contract — [ref/02-wait](../ref/02-wait.md). References: [`modus-examples/consumer`](../../../modus-examples/consumer), `modus new connector`.

## Guest: three entry points

| Method | Thread | What is allowed |
| --- | --- | --- |
| `init` | module load thread | short: `log`, `subscribe`, `settings.get`, reading assets. No network in a loop. Epoch ~500 ms (50×10 ms) → trap |
| `run` | `plugin-{id}` | `wait` loop and host calls from `Ready` branches. Returned — plugin stays silent until `reload` (login / enable) |
| `shutdown` | after `run`, including after trap | Core tears sockets; guest need not close anything |

Export:

```rust
use modus_sdk::{export, Guest, wait::{self, Ready}};

struct Plugin;
impl Guest for Plugin {
    fn init() { wait::subscribe(); }
    fn run() { /* wait loop */ }
    fn shutdown() {}
}
export!(Plugin);
```

## Wait base (no grant needed)

```text
wait::subscribe()
wait::set_timer(ms)   // one one-shot; 0 — clear
wait::wait() -> Ready
```

`subscribe` — in `init`. Without it `Ready::Bus` will not arrive. In `dev`, tutorial events are placed right after `init`: subscribe only in `run` — mail already discarded. `wait` does not replay the journal. Past — `history.read`.

## All `Ready` variants

| Variant | When | Guest action |
| --- | --- | --- |
| `Stop` | disable / remove / Ctrl+C in `dev` | `return` from `run`. Stop flag outranks the inbox queue |
| `Bus(event)` | bus event after `subscribe` | consumer / bot / alerter. Inbox **64**; full — drop (`bus: inbox {id} full, drop`), no block |
| `WsText` / `WsClosed` | frame / WS disconnect | connector. Host closes ping/pong |
| `Timer` | `set_timer` fired | own timer; do not confuse with backoff |
| `Settings` | Core (or `dev --settings`) saved the form | re-read `settings.get` |
| `Act(req)` | parked `chat.act` | connector runs protocol → `chat_complete` with the same `id`. No connector — immediate error to caller. Not canon `Moderation` |
| `Resume` | Windows power resume | connector: tear WS session and retry as on `WsClosed`. In parallel Core emits `system` “network after sleep”. Not bus replay. `wait_backoff` on `Resume` → `false` (immediate retry) |
| `Ui(bytes)` | frame from page / panel | grant `ui.slot` + slot. In `dev`: `--ui` |
| `MediaEnded(id)` | track end or `media.audio` stop | role `player`: `media_cache::release` if needed |
| `AlertPlay(cmd)` | Core cashier issued a show | alerter: own overlay / SFX; then `alert_enqueue::complete` |
| `AlertStop(cmd)` | cashier cleared the show (skip / timeout) | collapse overlay; `alert_enqueue::complete` if not already called |

`alert-play` / `alert-stop`: fields `job-id`, `event-id`, `duration-ms`. Cashier and queue are **Core**, not guest. In `modus dev` (S5) enqueue writes id to stderr **without** `AlertPlay`/`AlertStop`. Show reference — `modus new alerter`.

## Inbox 64

Delivery queue into the guest per instance: **64** events. Overflow — drop incoming, host log, no emitter block. Do not confuse with the 64 KiB event body limit.

## Stop and backoff

After stop, host calls → `"stopped"` (`HostError::Stopped`). `clock::sleep_ms` polls stop every 50 ms — not a `wait` replacement.

```rust
use modus_sdk::{wait_backoff, HostError, BACKOFF_START_MS, next_backoff_ms};

let mut delay = BACKOFF_START_MS;
loop {
    // … connect …
    if let Err(err) = work() {
        if HostError::classify(&err).is_stop() {
            return; // Stopped | Revoked
        }
        if wait_backoff(delay) {
            return; // Stop during wait
        }
        delay = next_backoff_ms(delay);
    }
}
```

`wait_backoff(ms) -> bool`:

- sets a timer, spins `wait`;
- **true** — `Stop` (exit);
- **false** — `Timer` or `Resume` (retry);
- during backoff `Act` → `chat_complete(..., Err("no connection"))` (emitter/connector);
- other `Ready` variants are swallowed until timer/stop.

Constants: start 1 s, ceiling 30 s, doubling via `next_backoff_ms`.

## Trap, `dev`, memory

| Topic | Behavior |
| --- | --- |
| Trap in Core | restart 1 s, then 2 s; 3 crashes / 60 s → quarantine until manual enable |
| Trap in `dev` | process/thread; Ctrl+C = `Stop`; join 5 s (`cannot stop` — guest outside `wait`) |
| Wasm memory | 16 MiB; disk not visible to guest |
| Persist | KV, settings, accounts, journal — at Core (in `dev` KV/settings — process RAM) |

Successful login in Core: instance `reload`, `run` from scratch, `list_accounts` no longer empty. No account — wait for `Stop`, do not invent chat.

Next chapter — [bus canon](02-canon-bus.md).
