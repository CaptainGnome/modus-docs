# Bridge, history, rates, catalog

**Rule.** These APIs are separate capabilities. Not the canon bus: catalog/rates — snapshots at Core; history — journal pages; bridge — RPC through the host to OBS (type allowlist).

References: `modus new bridge`, `modus new reader`, `modus new rates`, `modus new provider`, convert — `modus new alerter`.

## `bridge.obs`

Grant `bridge.obs` + non-empty (usually) `bridge_requests` in the manifest. Feature `bridge`.

```text
bridge::invoke(id, request_type, payload) -> Result<list<u8>, string>
```

| Argument | Meaning |
| --- | --- |
| `id` | connection/target id at Core (as set up in UI) |
| `request_type` | OBS request type; must be allowed by manifest and not in denylist |
| `payload` | JSON/bytes per OBS agreement |

Core denylist (manifest also cuts): `GetStreamServiceSettings`, `SetStreamServiceSettings`.

Raw TCP/WebSocket to OBS past bridge — forbidden (WASI/`net` to private). In `dev` — stub/log, not a live OBS.

## `history.read`

Grant `history.read`. Feature `reader` / also alerter.

```text
read(cursor?, limit) -> Result<Page, string>
```

`Page`:

| Field | Meaning |
| --- | --- |
| `events` | list of the same `wait::Event` (canon + flags) |
| `next` | next page cursor or empty |
| `alert_shown` | `event-id` values on this page already successfully shown by **this** `plugin_id`. Written to Core table `alert_shown` only after `alert_enqueue::complete(..., Ok(()))`. Event payloads stay untouched (no canon mangling). Retention ~1 h / cap ~2000. Not tracked in `dev` |

This is **not** replay into `Ready::Bus`. `wait` does not return history. Alerter uses read + `alert_shown` for recovery after restart / `Resume` — details in [alerts](06-kv-act-alerts.md#shown-alerts-alert_shown).

## `rates.publish` / `rates.convert`

Two grants:

| Grant | Module | Role |
| --- | --- | --- |
| `rates.publish` | `rates_publish` | feature `rates` — rate table |
| `rates.convert` | `rates` | feature `alerter` (+ rates) — read |

```text
rates_publish::publish(list<{from, to, value}>) -> Result<(), string>

rates::base() -> string
rates::convert_to_base(amount, from) -> Result<f64, string>
```

| Call | Rule |
| --- | --- |
| `publish` | currency pairs → Core FX table |
| `base` | ISO-4217 base from Core settings |
| `convert_to_base` | `amount` in `from` → base, floor to minor; no rate → `Err` |

Do not put the rate in canon `opaque`. Publish reference — `modus new rates`.

## `catalog.publish`

Grant `catalog.publish`. Feature `provider`. Manifest `provides` / `depends` / `consumes` — [00-manifest](00-manifest.md).

```text
publish(name, payload: list<u8>) -> Result<(), string>
unpublish(name) -> Result<(), string>
```

Currently name `emotes`, schema `modus.emotes.v1` (bytes — JSON snapshot per schema). This is **not** `bus.emit`: dictionary at Core for UI/other plugins with `consumes`.

| Ceiling | Value |
| --- | --- |
| snapshot size | 256 KiB |
| emotes | 2048 |
| publish | 10/s |

In `dev`: publish → stderr. Reference — `modus new provider` (+ `media.cache` for images).

Next chapter — [package and signing](10-package-signing.md).
