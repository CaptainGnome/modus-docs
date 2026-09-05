# Host errors

**Rule.** Error strings are part of ABI 2. In code: `HostError::classify(err)`, not parsing Russian phrases with your own `contains`. `is_stop()` — do not swallow into reconnect.

Compressed overview — [ref/04-errors](../ref/04-errors.md). Backoff exit reference: [`plugins/twitch`](../../../plugins/twitch).

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
| `Stopped` | exact equality | `остановлен` |
| `Grant` | prefix | `нет гранта …` (`bus.emit`, `net.ws`, …) |
| `Revoked` | exact equality | `refresh отозван`, `чужой аккаунт` |
| `Network` | fixed set / substrings | see table below |
| `Other` | everything else | `нет platform_id`, `system только Core`, `TooLarge`, job validations, … |

`is_stop()` = `Stopped` | `Revoked`. Also works: `HostError::from(err_str)`.

## Network: exact matches and patterns

| String / pattern | Meaning |
| --- | --- |
| `только https/wss` | scheme is not https/wss |
| `квота http` / `квота ws` | inflight / socket limit |
| `тело слишком большое` / `ответ слишком большой` | > 1 MiB |
| `литеральный IP запрещён` | URL with IP instead of DNS |
| `нет tcp для ws` | WS without transport |
| contains `вне манифеста` | host not in `hosts` / `embed_hosts` |
| contains `не в whitelist Core` | Core policy |
| starts with `запрещённый адрес ` | private / loopback / link-local |

## Common strings (Other and general)

| String | Meaning |
| --- | --- |
| `остановлен` | disable / remove / instance stop / Ctrl+C in `dev` |
| `нет гранта …` | no capability |
| `нет platform_id` | canon/auth without field in manifest |
| `system только Core` | plugin emits `system` |
| `custom не может маскировать канон` | `custom.kind` took a canon name |
| `opaque не JSON` | tail not parseable |
| `чужой аккаунт` | `token` not your account |
| `refresh отозван` | re-login required |
| `plugin id: нужен reverse-DNS (com.publisher.name)` | short id |
| `client_secret запрещён в манифесте` | secret in package |
| `режим api: вставьте токен` | api without token in UI |
| `хост X вне манифеста` / `не в whitelist Core` | network |
| `TooLarge` | bus event > 64 KiB |
| `platform_id … уже занят` | second live platform plugin |
| `нет соединения` | `chat_complete` during SDK backoff |
| `WIT вручную плюс SDK — два bindgen` | `pack`/`check` of directory |

New strings without an SDK major that land in `Other` are fine; `classify` is extended only in sync with ABI.

Next chapter — [base host APIs](04-base-host.md).
