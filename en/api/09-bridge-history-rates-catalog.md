# History, rates, catalog

**Rule.** These APIs are separate capabilities. Not the canon bus: catalog/rates are Core snapshots; history is journal pages. Loopback WS (`net.bridge`) — in [network](05-emit-auth-net.md#netbridge).

References: `modus new reader`, `modus new rates`, `modus new provider`, convert — `modus new alerter`.

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
| `alert_shown` | `event-id`s from this page already successfully shown by **this** `plugin_id`. Written to Core table `alert_shown` only after `alert_enqueue::complete(..., Ok(()))`. Event payloads are unchanged (no canon mangling). Retention ~1 h / cap ~2000. In `dev` the table is not kept |

This is **not** replay into `Ready::Bus`. `wait` does not return history. Alerter uses read + `alert_shown` for recovery after restart / `Resume` — see [alerts](06-kv-act-alerts.md#shown-alerts-alert_shown).

## `rates.publish` / `rates.convert`

Two grants:

| Grant | Module | Role |
| --- | --- | --- |
| `rates.publish` | `rates_publish` | feature `rates` — rates table |
| `rates.convert` | `rates` | feature `alerter` (+ rates) — read |

```text
rates_publish::publish(list<{from, to, value}>) -> Result<(), string>

rates::base() -> string
rates::convert_to_base(amount, from) -> Result<f64, string>
```

| Call | Rule |
| --- | --- |
| `publish` | currency pairs → Core FX table |
| `base` | ISO-4217 base from Core FX settings |
| `convert_to_base` | `amount` in `from` → base, floor to minor; missing rate → `Err` |

Do not put rates in canon `opaque`. Publish reference — `modus new rates`.

## `catalog.publish`

Grant `catalog.publish`. Feature `provider`. Manifest `provides` / `depends` / `consumes` — [00-manifest](00-manifest.md).

```text
publish(name, payload: list<u8>) -> Result<(), string>
unpublish(name) -> Result<(), string>
```

Currently name `emotes`, schema `modus.emotes.v1` (bytes — JSON snapshot). This is **not** `bus.emit`: a Core dictionary for UI/other plugins with `consumes`.

| Cap | Value |
| --- | --- |
| snapshot size | 256 KiB |
| emotes | 2048 |
| publish | 10/s |

In `dev`: publish → stderr. Reference — `modus new provider` (+ `media.cache` for images).

Next chapter — [package and signing](10-package-signing.md).
