# Host errors

If this is your first plugin — stop in plain terms in the [`dev` tutorial](../start/03-dev.md). If you need the string table — this chapter.

**Rule.** Error strings are part of ABI 2. In code: `HostError::classify(err)`, not parsing Russian phrases with your own `contains`. `is_stop()` — do not swallow into reconnect.

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
| `Stopped` | `остановлен` |
| `Grant` | `нет гранта …` |
| `Revoked` | `refresh отозван`, `чужой аккаунт` |
| `Network` | `только https/wss`, `квота http` / `квота ws`, `тело/ответ слишком большое`, `… вне манифеста`, `… не в whitelist Core`, `литеральный IP запрещён`, `запрещённый адрес …` |
| `Other` | everything else (incl. `нет platform_id`, `system только Core`, `TooLarge`) |

`is_stop()` = `Stopped` | `Revoked`. Connector scaffold and `modus new connector` exit `wait_backoff` this way.

## Common strings

| String | Meaning |
| --- | --- |
| `остановлен` | disable / remove / instance stop / Ctrl+C in `dev` |
| `нет гранта …` | no capability |
| `нет platform_id` | canon without the field in the manifest |
| `system только Core` | plugin emits `system` |
| `custom не может маскировать канон` | `custom.kind` took a canon name |
| `opaque не JSON` | tail cannot be parsed |
| `чужой аккаунт` | `token` not of your account |
| `refresh отозван` | re-login |
| `plugin id: нужен reverse-DNS (com.publisher.name)` | short id like `twitch` |
| `client_secret запрещён в манифесте` | secret in the package |
| `режим api: вставьте токен` | api not via browser “Sign in” |
| `хост X вне манифеста` / `не в whitelist Core` | network |
| `TooLarge` | bus event > 64 KiB |

Next chapter — [CLI](05-cli.md).
