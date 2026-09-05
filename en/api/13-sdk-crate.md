# Crate `modus-sdk`

**Rule.** The public author path is one Cargo role feature + `export!`. WIT and `wit_bindgen::generate` are not written in the plugin. Crate major = ABI (`2.0.0` ↔ `"abi": 2`).

Contract — [ref/00-contract](../ref/00-contract.md). WIT as an appendix — [ref/11-wit](../ref/11-wit.md).

## Features = one role

In the plugin `Cargo.toml`:

```toml
[dependencies]
# sibling of modus-sdk clone: ../modus-sdk/guest
# under product/examples tree: ../../modus-sdk/guest
modus-sdk = { path = "../modus-sdk/guest", features = ["consumer"] }
```

| Feature | Preset |
| --- | --- |
| `consumer` | base + listen |
| `emitter` | + `bus_emit`, `chat_complete`, canon helpers, `media_cache` |
| `connector` | + auth, net, emit, cache, complete |
| `provider` | + http/ws, cache, catalog |
| `widget` | + `ui_slot` (`new panel` too) |
| `reader` | + `history_read` |
| `player` | + `media_audio`, `media_cache` |
| `bridge` | + `net_bridge` |
| `embedder` | + `media_embed`, `ui_slot` |
| `rates` | + `net_http`, `rates_publish`, `rates` |
| `alerter` | + enqueue, ui, history, rates convert |
| `commander` | + `chat_act` |
| `store` | + `storage_kv` |

Exactly **one** feature. Two at once — `compile_error!("modus-sdk: ровно одна role-feature")`.

WIT world is always **`plugin`** (full import-set). Feature does not narrow the world — only re-exports modules and helpers. Rights are cut by manifest + host.

## `export!` and `Guest`

```rust
use modus_sdk::{export, Guest, wait::{self, Ready}, log::{self, Level}};

struct Plugin;

impl Guest for Plugin {
    fn init() {
        wait::subscribe();
    }
    fn run() {
        loop {
            match wait::wait() {
                Ready::Stop => return,
                Ready::Bus(ev) => log::log(Level::Info, &format!("{:?}", ev.payload)),
                _ => {}
            }
        }
    }
    fn shutdown() {}
}

export!(Plugin);
```

The macro expands into a bindgen `lifecycle` export inside the SDK. There is no `wit_bindgen::generate` in plugin `src`.

## `HostError` and backoff

```rust
use modus_sdk::{
    HostError, wait_backoff, next_backoff_ms,
    BACKOFF_START_MS, BACKOFF_MAX_MS,
};
```

| Symbol | Purpose |
| --- | --- |
| `HostError::classify` / `is_stop` | [03-errors](03-errors.md) |
| `wait_backoff(ms) -> bool` | timer + wait; true = Stop |
| `BACKOFF_START_MS` | 1000 |
| `BACKOFF_MAX_MS` | 30000 |
| `next_backoff_ms` | ×2 up to ceiling |

On `Resume` backoff returns `false` (immediate retry). During backoff `Act` → complete with `no connection` (emitter/connector).

## Canon helpers

With feature `consumer` / `emitter` / `connector`:

- `text_message`, `donation`, `follow`, `reward`, `viewer_count`
- `money`, `text_fragment`
- `sanitize_name_color` (always from crate root when built with a role)

Full canon — [02-canon-bus](02-canon-bus.md).

Base always: `self_info`, `log`, `clock`, `assets`, `settings`, `wait`, `types`, `set_label_i18n`.

## Do not mix with raw bindgen

| | Rule |
| --- | --- |
| Host | accepts a valid component with raw bindgen |
| `pack` / `check` of a directory with SDK | reject if `src/**/*.rs` contains `wit_bindgen::generate`: `manual WIT plus SDK — dual bindgen` |
| New package | SDK feature only |
| Truth when SDK vs WIT disagree | WIT (host); fix the bug in SDK |

WASI is not mixed into the SDK. `wasi:*` in the component — pack/load reject.

CLI: [modus-sdk](https://github.com/CaptainGnome/modus-sdk) (`cli/`). Docs — [modus-docs](https://github.com/CaptainGnome/modus-docs). Runnable dummies — [modus-examples](https://github.com/CaptainGnome/modus-examples); walkthroughs — [examples/](../examples/overview.md).
