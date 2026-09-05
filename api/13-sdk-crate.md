# Crate `modus-sdk`

**Правило.** Публичный путь автора — одна Cargo feature роли + `export!`. WIT и `wit_bindgen::generate` в плагине не пишут. Мажор crate = ABI (`2.0.0` ↔ `"abi": 2`).

Контракт — [ref/00-contract](../ref/00-contract.md). WIT как приложение — [ref/11-wit](../ref/11-wit.md).

## Features = одна роль

В `Cargo.toml` плагина:

```toml
[dependencies]
modus-sdk = { path = "../../modus-sdk/guest", features = ["consumer"] }
```

| Feature | Пресет |
| --- | --- |
| `consumer` | база + listen |
| `emitter` | + `bus_emit`, `chat_complete`, canon helpers, `media_cache` |
| `connector` | + auth, net, emit, cache, complete |
| `provider` | + http/ws, cache, catalog |
| `widget` | + `ui_slot` (`new panel` тоже) |
| `reader` | + `history_read` |
| `player` | + `media_audio`, `media_cache` |
| `bridge` | + `bridge` |
| `embedder` | + `media_embed`, `ui_slot` |
| `rates` | + `net_http`, `rates_publish`, `rates` |
| `alerter` | + enqueue, ui, history, rates convert |
| `commander` | + `chat_act` |
| `store` | + `storage_kv` |

Ровно **одна** feature. Две сразу — `compile_error!("modus-sdk: ровно одна role-feature")`.

WIT-world всегда **`plugin`** (полный import-set). Feature не сужает world — только re-export модулей и helpers. Права режет манифест + хост.

## `export!` и `Guest`

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

Макрос разворачивается в bindgen-экспорт `lifecycle` внутри SDK. В `src` плагина нет `wit_bindgen::generate`.

## `HostError` и backoff

```rust
use modus_sdk::{
    HostError, wait_backoff, next_backoff_ms,
    BACKOFF_START_MS, BACKOFF_MAX_MS,
};
```

| Символ | Назначение |
| --- | --- |
| `HostError::classify` / `is_stop` | [03-errors](03-errors.md) |
| `wait_backoff(ms) -> bool` | таймер + wait; true = Stop |
| `BACKOFF_START_MS` | 1000 |
| `BACKOFF_MAX_MS` | 30000 |
| `next_backoff_ms` | ×2 до потолка |

На `Resume` backoff возвращает `false` (немедленный retry). Во время backoff `Act` → complete с `нет соединения` (emitter/connector).

## Canon helpers

При feature `consumer` / `emitter` / `connector`:

- `text_message`, `donation`, `follow`, `reward`, `viewer_count`
- `money`, `text_fragment`
- `sanitize_name_color` (всегда из crate root при сборке с ролью)

Полный канон — [02-canon-bus](02-canon-bus.md).

База всегда: `self_info`, `log`, `clock`, `assets`, `settings`, `wait`, `types`, `set_label_i18n`.

## Не смешивать с сырым bindgen

| | Правило |
| --- | --- |
| Хост | примет валидный компонент с сырым bindgen |
| `pack` / `check` каталога с SDK | откажут, если в `src/**/*.rs` есть `wit_bindgen::generate`: `WIT вручную плюс SDK — два bindgen` |
| Новый пакет | только feature SDK |
| Правда при споре SDK vs WIT | у WIT (хост); баг чинят в SDK |

WASI SDK не подмешивает. `wasi:*` в компоненте — отказ pack/load.

CLI рядом: `modus-sdk/cli`. Документация — этот репозиторий (`modus-docs`). Эталоны: [`plugins/*`](../../plugins/consumer).
