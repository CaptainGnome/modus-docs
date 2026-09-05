# Host errors

If this is your first plugin — stop in plain terms in the [`dev` tutorial](../start/03-dev.md). If you need the string table — this chapter.

**Rule.** Error strings are part of ABI 2. In code: `HostError::classify(err)`, do not parse literals with your own `contains`. `is_stop()` — do not swallow into reconnect.

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

| Variant | Typical strings |
| --- | --- |
| `Stopped` | `stopped` |
| `Grant` | `no grant …` |
| `Revoked` | `refresh revoked`, `foreign account` |
| `Network` | `https/wss only`, `http quota` / `ws quota`, `body/response too large`, `… not in manifest`, `… not in Core whitelist`, `literal IP forbidden`, `forbidden address …` |
| `Other` | everything else (incl. `no platform_id`, `system is Core-only`, `TooLarge`) |

`is_stop()` = `Stopped` | `Revoked`. Connector scaffold and `modus new connector` exit `wait_backoff` this way.

## Common strings

| String | Meaning |
| --- | --- |
| `stopped` | disable / remove / instance stop / Ctrl+C in `dev` |
| `no grant …` | no capability |
| `no platform_id` | canon without the field in the manifest |
| `system is Core-only` | plugin emits `system` |
| `custom cannot mask canon` | `custom.kind` took a canon name |
| `opaque is not JSON` | tail cannot be parsed |
| `foreign account` | `token` not of your account |
| `refresh revoked` | re-login |
| `plugin id: reverse-DNS required (com.publisher.name)` | short id like `twitch` |
| `client_secret forbidden in manifest` | secret in the package |
| `api mode: paste token` | api not via browser “Sign in” |
| `host X not in manifest` / `not in Core whitelist` | network |
| `TooLarge` | bus event > 64 KiB |

Next chapter — [CLI](05-cli.md).
