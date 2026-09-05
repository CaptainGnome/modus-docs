# Rates / FX

The role publishes a rate table to Core (`rates.publish`) without putting rates into canon `opaque`. The reference fetches a snapshot over allowlisted HTTP, inverts pairs toward the chosen base, and calls `publish`. Convert for alerts is another grant (`rates.convert`) on the alerter.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `rates` |
| Required | `net.http`, `rates.publish` |
| Manifest | `hosts` — where `fetch` is allowed |

Map — [ref/01-roles](../ref/01-roles.md). API — [api/09-bridge-history-rates-catalog](../api/09-bridge-history-rates-catalog.md), network — [api/05-emit-auth-net](../api/05-emit-auth-net.md).

## Manifest

```json
{
  "id": "com.modus.fx",
  "name": "FX Rates",
  "version": "0.1.0",
  "abi": 2,
  // fetch snapshot + push pair table into Core FX
  "capabilities": ["net.http", "rates.publish"],
  // only this origin may be fetched — else «вне манифеста»
  "hosts": ["open.er-api.com"]
  // no UI / KV / emit — role is rate table only
}
```

| Field | Why |
| --- | --- |
| `net.http` | `net_http::fetch` |
| `rates.publish` | pair snapshot → Core FX table |
| `hosts` | origin allowlist; else `… вне манифеста` |
| no UI / KV / emit | role is rate table only |

## Code

**Loop.** Refresh → timer by `interval_hours` (1…168 h, minimum 60 s). Wake: Timer / Settings / Resume.

```rust
fn run() {
    loop {
        refresh(); // fetch + publish once per cycle
        // settings interval (hours), clamp to 1…168, default 6
        let hours = settings::get("interval_hours")
            .and_then(|v| v.parse::<f64>().ok())
            .unwrap_or(6.0)
            .clamp(1.0, 168.0);
        // host timer floor is 60s even if hours round down
        let ms = ((hours as u64).saturating_mul(HOUR_MS)).max(60_000) as u32;
        wait::set_timer(ms);
        match wait::wait() {
            Ready::Stop => return,
            // timer tick, form edit, or resume → loop back to refresh
            Ready::Timer | Ready::Settings | Ready::Resume => {}
            // ignore Bus / Act / …
        }
    }
}
```

**Fetch + publish.** Base from settings (default `RUB`). URL strictly under `hosts`.

```rust
fn refresh() {
    // ISO base currency from settings (default RUB)
    let base = /* settings "base" or "RUB" */;
    // must stay under hosts allowlist
    let url = format!("https://open.er-api.com/v6/latest/{base}");
    match net_http::fetch("GET", &url, NONE, &[]) {
        Ok(resp) if (200..300).contains(&resp.status) => {
            // invert API “1 base = N code” → Core “1 code = 1/N base”
            let rates = parse_rates(&resp.body, &base)?;
            rates_publish::publish(&rates)?; // Core FX table for convert
            // status label: "ok N pairs"
        }
        Ok(resp) => { /* non-2xx → status with http code */ }
        Err(err) => { /* network / grant / allowlist → status */ }
    }
}
```

**Parse.** The API gives “1 base = value × code”; Core needs pairs `from=code → to=base` with `value = 1/value`.

```rust
rates.push(Rate {
    from: code,              // foreign currency code
    to: base.to_string(),    // streamer's base
    value: 1.0 / value,      // invert so convert_to_base works
});
```

Convert consumer — [07-alerter](07-alerter.md) (`rates::convert_to_base`).

## Assets

| Path | Purpose |
| --- | --- |
| `assets/settings.json` | `base` (ISO), `interval_hours`, label `status` |

## Run

```powershell
modus dev plugins/fx
```

Needs network + host whitelist (and Core allowlist if stricter than the manifest). Full crate: [`../../../plugins/fx`](../../../plugins/fx).

In `dev`, publish often goes to stderr; convert in another plugin depends on whether the teaching host kept the table.

## Typical host errors

| String / situation | Meaning |
| --- | --- |
| `нет гранта net.http` / `rates.publish` | no capability |
| `хост … вне манифеста` / `не в whitelist Core` | URL not in allowlist |
| `только https/wss` | scheme |
| `квота http` | rate limit |
| empty snapshot / `нет rates` | broken response JSON |
| convert without publish | alerter `Err` on donation FX |

See [ref/04-errors](../ref/04-errors.md), [ref/06-net-auth](../ref/06-net-auth.md).
