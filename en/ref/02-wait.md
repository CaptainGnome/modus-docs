# Lifecycle and `wait`

If this is your first plugin — the cycle in plain terms in the [`dev` tutorial](../start/03-dev.md). If you need the `Guest` / `Ready` contract — this chapter.

**Rule.** In `run`, a long loop only through `wait::wait`. Stop is not reconnect: `Ready::Stop` and `HostError::is_stop()` exit the loop, not into backoff.

## Three host calls

`Guest`: `init` → `run` → `shutdown`. No other entry points.

| Method | Thread | What is allowed |
| --- | --- | --- |
| `init` | same as loads the module | short: `log`, `subscribe`, `settings.get`. No network in a loop. Epoch ~500 ms (50 ticks × 10 ms) → trap |
| `run` | `plugin-{id}` | only `wait` (and host calls from `Ready` branches). Returned from `run` — plugin is silent until Core `reload` (login / enable) |
| `shutdown` | after `run`, including after trap | Core tears sockets; guest need not close anything |

No second thread from wasm. No callbacks: the host wakes `wait`.

`subscribe` — in `init`. Without it `Ready::Bus` will not arrive. In `dev`, tutorial events are placed right after `init`: subscribe only in `run` — messages already dropped. `wait` does not replay journal history. Past — grant `history.read` (`history_read::read`), not `Ready::Bus`.

## `Ready`

Base, no grant needed:

```text
wait::subscribe()
wait::set_timer(ms)   // one one-shot; 0 — clear
wait::wait() -> Ready
```

| Variant | When | What to do |
| --- | --- | --- |
| `Stop` | disable / remove / Ctrl+C in `dev` | `return` from `run`. Stop flag beats the queue: even if inbox still has frames |
| `Bus` | bus event after `subscribe` | consumer / bot logic. Inbox **64**; full — drop (`bus: inbox {id} full, drop`), not block |
| `WsText` / `WsClosed` | frame / WS break | connector. Host closes ping/pong itself |
| `Timer` | `set_timer` fired | your timer. Do not confuse with backoff |
| `Settings` | Core saved this plugin's form | re-read `settings.get`. In `init`, `get` without `wait` is ok |
| `Act` | parked `chat.act` (send/delete/timeout/ban/unban) | connector runs the protocol and calls `chat_complete`. No live connector — immediate error to who called `act`. This is not canon `Moderation` |
| `Resume` | after Windows sleep (power resume) | connector: close WS session and retry, as on `WsClosed`. In parallel Core emits `system` “network after sleep” on the bus (for consumer/UI). Not bus replay. `wait_backoff` on `Resume` exits immediately (`false`) |
| `Ui` | frame from the slot page | grant `ui.slot` + slot |
| `MediaEnded` | end / `stop` of `media.audio` play | role `player`: `release` cache-key if any |

After stop, host calls return `"stopped"` (`HostError::Stopped`). `clock::sleep_ms` checks stop every 50 ms — not a substitute for `wait`.

Successful login in Core: instance `reload`, `run` from scratch, `list_accounts` no longer empty. No account — wait for `Stop`; do not invent chat.

## Stop and backoff

`HostError::classify` / `is_stop()` — [host errors](04-errors.md); detail — [api/03-errors](../api/03-errors.md). `Stopped` and `Revoked` are not network.

`modus_sdk::wait_backoff(ms) -> bool`: sets a timer, spins `wait`, **true** if stop (including `Act` during backoff closing the job with “no connection”). `Resume` — like a fired timer: **false**, immediate retry. Scaffold `new connector` and `modus new connector` do this. Do not write your own `sleep` + reconnect around `"stopped"`.

Constants: `BACKOFF_START_MS` 1 s, cap `BACKOFF_MAX_MS` 30 s, `next_backoff_ms`.

## Trap, `dev`, memory

Trap in `init`/`run` is **Core**'s business, not `dev`: restart 1 s, then 2 s; 3 crashes in 60 s → quarantine until the streamer enables again. In `dev` Ctrl+C = `Stop`, thread join 5 s (`cannot stop` — guest stuck outside `wait`).

Instance memory **16 MiB**. Disk is invisible to the guest. Wasm RAM dies on unload; KV, settings, accounts, journal — at Core.

Loop reference: scaffold `modus new consumer` / `new connector`; live connector — `modus new connector`.
