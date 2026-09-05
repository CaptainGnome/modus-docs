# Network and auth

If this is your first plugin — replay in the [connector tutorial](../start/07-connector.md). If you need the `auth.token` / `net.*` contract — this chapter.

**Rule.** App secret and refresh live at Core (or the broker), not in wasm and not in plugin git. The guest gets a short access via `auth.token` and reaches the network only through the host.

## Auth

Grant `auth.token`. SDK module: `auth_token`.

```text
list-accounts() -> list<string>
token(account-id) -> result<string, string>
```

- Without grant / on stop — empty list; `token` → refuse.
- Foreign id → `чужой аккаунт` (`HostError::Revoked`).
- Refresh revoked → `refresh отозван`.
- After successful login in Core the plugin **restarts**: `run` sees accounts again.
- No account → scaffold waits for `Stop`; do not invent chat.

Manifest modes (`auth_mode`): `broker` / `pkce` / `device` / `api` / `custom`. `client_secret` in the manifest is forbidden. In `dev` — `--token` / `--token-file` (fake access), not Core's vault.

Core drives the OAuth shell. Platform protocol — the plugin's via `net.*` + `token`.

Reference: `modus new connector`, scaffold `modus new connector`.

## HTTP

Grant `net.http`. Only `https://`. Literal IP, loopback, private, link-local — refuse. Host ∈ manifest `hosts` ∩ Core whitelist. Redirect: up to 5 hops, each checked.

Limits: body 1 MiB, timeout 15 s, ≤4 inflight. Host does not retry 429.

In `dev`: without network — `--http-file` (JSON, key = URL without query).

## WebSocket

Grant `net.ws`. Only `wss://`. ≤2 sockets. Frames — `Ready::WsText` / `WsClosed`. Stop tears TCP.

In `dev`: `--replay` (file lines) or one live URL from `hosts`.

## Consequence

Import without grant — soft-link ok; call without cap — `нет гранта …`. Network bypassing the host (WASI / own socket) — `pack` refuse.

Next chapter — [settings / KV / act / alerts / slots](07-host-apis.md).
