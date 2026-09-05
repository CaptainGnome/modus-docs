# Consumer

Role with no grants: listen to bus canon and log it. Use when the plugin has nothing to emit and nowhere to go on the network — only subscribe and react to others’ events.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `consumer` |
| Required grants | none |
| Base | `wait`, `log`, `types` (and other no-cap APIs) |
| Map | [ref/01-roles](../ref/01-roles.md) |

Reference: [`modus-examples/consumer`](../../../modus-examples/consumer).

## Manifest

Minimal passport — no `capabilities`, `platform_id`, or slots:

```json
{
  // reverse-DNS package id — stable identity for pack/load
  "id": "com.modus.consumer",
  // human-readable name in Core UI / CLI lists
  "name": "Consumer",
  // semver of this plugin build (not the ABI)
  "version": "0.1.0",
  // optional author string shown in metadata
  "author": "modus",
  // guest contract version the host must speak (currently 2)
  "abi": 2
  // no capabilities / platform_id / slots — pure bus listener
}
```

| Field | Why |
| --- | --- |
| `id` | reverse-DNS package id |
| `abi` | guest contract version (currently `2`) |

## Code

**Subscribe in `init`.** Without `subscribe`, tutorial `dev` letters and foreign canon never appear in `Ready::Bus`.

```rust
fn init() {
    // announce boot so CLI/Core logs show the guest started
    log::log(Level::Info, "consumer init");
    // open the bus mailbox BEFORE run — otherwise Ready::Bus stays empty
    wait::subscribe();
}
```

**`run` loop.** Sleep in `wait`; handle only `Stop` and `Bus`. Other `Ready` variants are empty for a typical consumer.

```rust
fn run() {
    loop {
        // block until host wakes us (Stop, Bus, or noise we ignore)
        match wait::wait() {
            // host shutting down / Ctrl+C — exit cleanly
            Ready::Stop => return,
            // foreign or tutorial canon arrived — dump it
            Ready::Bus(event) => log_bus(&event),
            // Ws / Act / Ui / Timer / … — not this role's job
            _ => {}
        }
    }
}
```

**Payload dump.** The reference prints kind, source, flags, and fragment text — a handy bus sniffer when debugging a connector.

```rust
fn log_bus(event: &Event) {
    // flatten fragments / donation text into one line for the sniffer
    let text = payload_text(&event.payload);
    log::log(
        Level::Info,
        &format!(
            // kind + who emitted + which channel + payload preview
            "bus {} {}:{} … {}",
            payload_kind(&event.payload),   // Message / Donation / …
            event.source.plugin_id,         // emitter package id
            event.source.channel,           // platform channel label
            text
        ),
    );
}
```

## How to run

```powershell
modus new consumer --id com.you.bus --dir bus
modus dev ../modus-examples/consumer
```

Your scaffold: `modus dev bus`. With no flags, `dev` injects tutorial `message` / `donation` / `reward` right after `init`. See [start/03-dev](../start/03-dev.md); flags — [api/11-cli-dev](../api/11-cli-dev.md).

## Typical host errors

| Situation | String / effect |
| --- | --- |
| emit / network call without grant | `нет гранта …` (`HostError::Grant`) |
| Ctrl+C / shutdown | `остановлен` → `Ready::Stop` |
| Forgot `subscribe` | log shows `emit … fixture hello`, no `bus message …` |

Full list — [api/03-errors](../api/03-errors.md).
