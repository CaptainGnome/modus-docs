# Base host APIs

**Rule.** These imports exist for any package on world `plugin`. No grant in the manifest is needed. Soft-link is full; deny only on stop / argument validation.

SDK modules (with any role-feature): `self_info`, `log`, `clock`, `random`, `assets`, `settings`, `wait`, `types`, `plugins`. `chat_complete` — no grant, but re-exported under feature `emitter` / `connector`.

## `self_info`

```text
plugin_id() -> string
version()   -> string
```

| Call | Value |
| --- | --- |
| `plugin_id` | `id` from the manifest |
| `version` | `version` from the manifest |

For logs and debugging; forging another id is impossible.

## `plugins`

```text
list() -> Result<list<entry>, String>
```

Read-only snapshot of **installed non-quarantine** plugins: `plugin_id`, `name`, `enabled`, optional `platform_id`, `emits`, `emits_custom`. **No grant.** Storm **2/s** (`plugins too frequent`). Disabled plugins appear with `enabled: false`; quarantine is omitted.

On install / enable / disable / uninstall / quarantine Core emits `system` with code `plugins-changed` (refresh without Core restart). Helper: `modus_sdk::platforms_with_kind(entries, kind)`.

Chrome mirrors the same snapshot via IPC `plugin_registry`.

## `log`

```text
log(level, message)
```

Levels: `debug` / `info` / `warn` / `error`. Cap **20 messages/s** per instance; excess is dropped by the host. Do not write tokens and refresh into the message (in `dev` redact is weaker than Core).

## `clock`

```text
sleep_ms(ms)
now_ms() -> s64
```

| Call | Behavior |
| --- | --- |
| `sleep_ms` | Blocking sleep with stop poll ~every 50 ms. **Not** a `wait` replacement for connector loops: on stop exit via `Ready::Stop` / `wait_backoff`, else join in `dev` waits 5 s. |
| `now_ms` | UTC unix time in milliseconds since 1970-01-01. No grant, no storm. Same clock as Core event stamps (`db::now_ms`). Use for catch-up waterlines (e.g. ignore chat history before plugin attach). |

`modus dev` implements the same import as Core. ABI **2** additive — old packages that only call `sleep_ms` keep working.

## `random`

```text
fill(len: u32) -> Result<list<u8>, String>
```

Host CSPRNG (no WASI). `len` **1…256**; `0` / `>256` → err. Storm **20 calls/s** → `random too frequent`.

The lottery / wheel / giveaway winner is chosen in **wasm** after `fill`. Overlay only animates an already-chosen result.

SDK sugar (outside WIT):

```rust
use modus_sdk::random;

let bytes = random::fill(16)?;
let n = random::u64()?;       // 8 bytes LE
let unit = random::f64()?;    // [0, 1)
```

`modus dev` links the same import as Core.

## `assets.read`

```text
read(path) -> Result<Vec<u8>, String>
```

Read a file from the package relative to `assets/`. No `..`, no absolute paths, no escape from the asset tree. Typical: default JSON, sounds for `media.audio` spec `asset`, static for verification.

Streamer disk and other packages are not visible. Persist — Core KV / settings.

## Settings

Schema — `assets/settings.json`. No file — no form in UI. Broken / > 32 KiB — package is not installed. Schema ceilings: 8 sections, 32 fields. Drawn by **Core**; guest reads values / writes labels.

```text
get(key) -> Option<String>
set_label(key, text) -> Result<(), String>
set_label_i18n(key, label_key, params?) -> Result<(), String>
```

| Call | Rule |
| --- | --- |
| `get` | no schema / foreign key → `None`. In `init` without `wait` ok |
| `set_label` | only field `type: label` in schema; else rejected |
| `set_label_i18n` | Core resolves `label_key` from `assets/i18n/{locale}.json`; `params` — optional JSON object (`{"err":"boom"}`) for substitutions |

SDK wrapper: `modus_sdk::set_label_i18n(...)`.

Save in Core → `Ready::Settings`. In `dev`: `--settings file.json` — value overlay + one `Ready::Settings` after `init`. Unknown key in file — rejected at `dev` start.

Reference: `modus new store`.

## `chat_complete`

```text
complete(id, outcome: Result<(), String>)
```

No grant. Called by the **connector/emitter** that received `Ready::Act`, with the same job `id`. Foreign id — rejected. No `complete` within **15 s** — error to whoever called `chat.act`.

Commander does not call `complete`. `Err` outcome — text goes to the act caller; it is not placed on the bus by itself.

Act link — [06-kv-act-alerts](06-kv-act-alerts.md). Lifecycle — [01-lifecycle-wait](01-lifecycle-wait.md).

Next chapter — [emit, auth, network](05-emit-auth-net.md).
