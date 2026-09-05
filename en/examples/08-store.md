# Store

The role keeps its own KV (`storage.kv`) and reads package settings. Other plugins' keys are invisible; platform secrets do not go here — use `settings` of type `secret`. Reference — boot counter, asset read, and reaction to `Ready::Settings`.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `store` |
| Required grant | `storage.kv` |
| Base without grant | `settings`, `assets`, `wait`, `log` |

Map — [ref/01-roles](../ref/01-roles.md). API — [api/06-kv-act-alerts](../api/06-kv-act-alerts.md).

## Manifest

```json
{
  "id": "com.modus.store",
  "name": "Store",
  "version": "0.1.0",
  "abi": 2,
  // sole grant — private key/value store for this plugin id
  "capabilities": ["storage.kv"]
  // no slots / network — role draws no UI and does no HTTP
}
```

| Field | Why |
| --- | --- |
| `capabilities` | sole grant — own KV |
| no `slots` / network | role draws no UI and does no HTTP |

## Code

**Init.** Subscribe (for `Settings`), `get`/`set` the `boots` counter, read `assets/note.txt`, i18n label in settings.

```rust
fn init() {
    // Settings wake requires subscribe even if we ignore Bus
    wait::subscribe();
    // read prior boot count from private KV (None → first run)
    let n = match storage_kv::get("boots") {
        Ok(Some(value)) => value.parse::<u32>().unwrap_or(0),
        Ok(None) => 0,
        Err(err) => { log::log(Level::Warn, &err); 0 }
    };
    let next = n.saturating_add(1);
    // persist for next process (Core) — in `dev` KV is RAM-only
    let _ = storage_kv::set("boots", &next.to_string());
    // packaged file read — not KV, not settings
    match assets::read("note.txt") {
        Ok(bytes) => log::log(Level::Info, &format!("asset: {}", String::from_utf8_lossy(&bytes))),
        Err(err) => log::log(Level::Warn, &err),
    }
    // i18n status label with JSON args { "n": next }
    let _ = settings::set_label_i18n(
        "status",
        "status.boots",
        Some(&format!(r#"{{"n":{next}}}"#)),
    );
}
```

**Settings.** The host wakes `Ready::Settings` after a form change; the guest reads fields and does not parse the schema JSON itself.

```rust
fn on_settings() {
    // free-text field from assets/settings.json
    let note = settings::get("note").unwrap_or_default();
    // checkbox stored as string "true"/"false"
    let echo = settings::get("echo").as_deref() == Some("true");
    if echo {
        log::log(Level::Info, &format!("note {note}"));
    }
    // secret field — never log the value, only presence
    let secret = settings::get("token").filter(|v| !v.is_empty());
    log::log(Level::Info, &format!(
        "secret={}", if secret.is_some() { "yes" } else { "no" }
    ));
}
```

In `run` the loop waits for `Stop` / `Settings` / `Resume`; it ignores bus and alerts — the role is not a bus consumer for this demo, but `subscribe` is required for the settings wake.

## Assets

| Path | Purpose |
| --- | --- |
| `assets/settings.json` | form: `note`, `echo`, `token` (secret), `status` (label) |
| `assets/note.txt` | `assets::read` example |
| `assets/i18n/{en,ru}.json` | `status.boots` keys, field labels |

## Run

```powershell
modus new <role>  # scaffold, then modus dev <dir>
# смена настроек в CLI: modus new store  # then: modus dev <dir> --settings …
```

Full crate: [`modus new store`](modus new store).

In `dev`, KV is process RAM (after CLI restart the counter starts at zero). In Core, persist is tied to the plugin `id`.

## Typical host errors

| String / situation | Meaning |
| --- | --- |
| `no grant storage.kv` | call without capability |
| KV quota (256 KiB / 256 keys / 16 KiB value) | `set` too large |
| set/delete storm ~60/s | rate limit |
| empty KV after `dev` restart | expected for S5 |

See [ref/04-errors](../ref/04-errors.md), [ref/09-limits](../ref/09-limits.md).
