# Base host APIs

**Rule.** These imports exist for any package on world `plugin`. No grant in the manifest is needed. Soft-link is full; deny only on stop / argument validation.

SDK modules (with any role-feature): `self_info`, `log`, `clock`, `assets`, `settings`, `wait`, `types`. `chat_complete` — no grant, but re-exported under feature `emitter` / `connector`.

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

## `log`

```text
log(level, message)
```

Levels: `debug` / `info` / `warn` / `error`. Cap **20 messages/s** per instance; excess is dropped by the host. Do not write tokens and refresh into the message (in `dev` redact is weaker than Core).

## `clock`

```text
sleep_ms(ms)
```

Blocking sleep with stop poll ~every 50 ms. **Not** a `wait` replacement for connector loops: on stop exit via `Ready::Stop` / `wait_backoff`, else join in `dev` waits 5 s.

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
