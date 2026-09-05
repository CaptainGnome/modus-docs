# Host errors

**Rule.** Error strings are part of ABI 2. In code: `HostError::classify(err)`, do not parse literals with your own `contains`. `is_stop()` — do not swallow into reconnect.

Compressed overview — [ref/04-errors](../ref/04-errors.md). Backoff exit reference: `modus new connector`.

## Classify

```rust
use modus_sdk::HostError;

match HostError::classify(&err) {
    HostError::Stopped | HostError::Revoked => { /* exit run */ }
    HostError::Grant => { /* no capability */ }
    HostError::Network => { /* backoff / other URL */ }
    HostError::Other(_) => { /* rest */ }
}
```

| Variant | How determined | Typical strings |
| --- | --- | --- |
| `Stopped` | exact equality | `stopped` |
| `Grant` | prefix | `no grant …` (`bus.emit`, `net.ws`, …) |
| `Revoked` | exact equality | `refresh revoked`, `foreign account` |
| `Network` | fixed set / substrings | see table below |
| `Other` | everything else | `no platform_id`, `system is Core-only`, `TooLarge`, job validations, … |

`is_stop()` = `Stopped` | `Revoked`. Also works: `HostError::from(err_str)`.

## Network: exact matches and patterns

| String / pattern | Meaning |
| --- | --- |
| `https/wss only` | scheme is not https/wss |
| `http quota` / `ws quota` | inflight / socket limit |
| `body too large` / `response too large` | > 1 MiB |
| `literal IP forbidden` | URL with IP instead of DNS |
| `no tcp for ws` | WS without transport |
| contains `not in manifest` | host not in `hosts` / `embed_hosts` |
| contains `not in Core whitelist` | Core policy |
| starts with `forbidden address ` | private / loopback / link-local |

## Common strings (Other and general)

| String | Meaning |
| --- | --- |
| `stopped` | disable / remove / instance stop / Ctrl+C in `dev` |
| `no grant …` | no capability |
| `no platform_id` | canon/auth without field in manifest |
| `system is Core-only` | plugin emits `system` |
| `custom cannot mask canon` | `custom.kind` took a canon name |
| `opaque is not JSON` | tail not parseable |
| `foreign account` | `token` not your account |
| `refresh revoked` | re-login required |
| `plugin id: reverse-DNS required (com.publisher.name)` | short id |
| `client_secret forbidden in manifest` | secret in package |
| `api mode: paste token` | api without token in UI |
| `host X not in manifest` / `not in Core whitelist` | network |
| `TooLarge` | bus event > 64 KiB |
| `platform_id … already taken` | second live platform plugin |
| `no connection` | `chat_complete` during SDK backoff |
| `manual WIT plus SDK — dual bindgen` | `pack`/`check` of directory |

New strings without an SDK major that land in `Other` are fine; `classify` is extended only in sync with ABI.

Next chapter — [base host APIs](04-base-host.md).
