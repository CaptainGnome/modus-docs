# Emit, auth, network

**Rule.** App secret and refresh live at Core (or broker), not in wasm and not in git. The guest gets a short access via `auth.token` and talks to the network only through the host. Emit — grant + `platform_id`.

Compressed overview — [ref/06-net-auth](../ref/06-net-auth.md). Reference: `modus new connector`, scaffold `modus new connector`.

## `bus.emit`

See full canon — [02-canon-bus](02-canon-bus.md).

```text
bus_emit::emit(channel, payload, opaque?) -> Result<(), String>
```

Short: Core stamp; `system` forbidden to guest; body > 64 KiB → `TooLarge`; no grant → `no grant bus.emit`.

## `auth.token`

Grant `auth.token`. SDK module: `auth_token`.

```text
list_accounts() -> list<string>
token(account_id) -> Result<string, string>
```

| Situation | Behavior |
| --- | --- |
| no grant / stop | empty list; `token` → rejected |
| foreign `account_id` | `foreign account` (`HostError::Revoked`) |
| refresh revoked | `refresh revoked` |
| successful login in Core | instance **reload**, `run` from scratch |
| no account | scaffold waits for `Stop`, do not invent chat |

### Manifest modes (concept)

| `auth_mode` | Who holds the secret | What the guest sees |
| --- | --- | --- |
| `broker` | broker + Core | access after verified package |
| `pkce` | Core (public client) | access after browser login |
| `device` | Core | access after device code |
| `api` | streamer pastes token in UI | access from the safe |
| `custom` | by URL fields | access after Core shell |

URL/client_id fields — [00-manifest](00-manifest.md). In `dev`: `--token` / `--token-file` + `--account` (default `dev`) — fake access for the **CLI process only**, not packed into `.mplug`.

## Host allowlist

Guest concept (`net.http` / `net.ws` / `net.grpc`):

1. URL/`authority` must use TLS (`https://` / `wss://` / gRPC `:443`).
2. Hostname ∈ manifest `hosts` (for embed iframe — `embed_hosts`).
3. Hostname ∈ Core policy whitelist.
4. Literal IP, loopback, private, link-local — rejected.

HTTP redirects: up to **5** hops; each hop before connect — https, manifest ∩ whitelist, pinned DNS. Cross-origin drops all guest headers (including `Authorization`). Guests must not set hop-by-hop headers (`Host`, `Content-Length`, `Transfer-Encoding`, `Connection`, …). `Network`-class errors — [03-errors](03-errors.md).

Exception: local software — only [`net.bridge`](#netbridge) (plain `ws://` on loopback), not `net.ws`.

`new connector` does **not** insert official Twitch `client_id`, `broker`, or Twitch hosts — the platform author writes them.

## `net.http`

Grant `net.http`.

```text
fetch(method, url, headers, body) -> Result<HttpResponse, String>
```

Response: `status`, `headers`, `body`.

| Ceiling | Value |
| --- | --- |
| scheme | https only |
| request / response body | 1 MiB |
| timeout | 15 s |
| inflight | ≤ 4 |
| 429 | host does **not** retry |

In `dev` without network: `--http-file` — JSON response map, key = URL **without** query.

## `net.ws`

Grant `net.ws`.

```text
connect(url) -> Result<u32, String>   // handle
send_text(handle, message) -> Result<(), String>
close(handle) -> Result<(), String>
```

Frames arrive as `Ready::WsText { handle, text }` / `Ready::WsClosed(handle)`. Host closes ping/pong. Stop tears TCP.

| Ceiling | Value |
| --- | --- |
| scheme | wss only |
| sockets | ≤ 2 |

In `dev`: `--replay file` (text frames per line) **or** one live `wss://` from `hosts` (not private).

## `net.grpc`

Grant `net.grpc`. Host transports raw protobuf bytes; decode/encode stays in wasm. WIT package `modus:abi@2.1.0`.

```text
call(authority, path, headers, request) -> Result<GrpcResponse, String>
open-stream(authority, path, headers, request) -> Result<u32, String>  // handle
cancel(handle) -> Result<(), String>
```

`GrpcResponse`: `status` (gRPC code, `0` = OK), `message`, `body` (empty when `status != 0`).

| Mode | Behavior |
| --- | --- |
| unary `call` | one request → one response; blocks the guest call (same model as `net.http` fetch); no `wait` |
| server-stream `open-stream` | frames `Ready::GrpcMsg { handle, bytes }` / `Ready::GrpcClosed { handle, status, message }` |

| Ceiling | Value |
| --- | --- |
| TLS | required |
| authority | hostname ∈ `hosts` ∩ whitelist; default port 443 |
| request / message | 1 MiB |
| concurrent streams | same as WS quota (≤ 2) |
| unary timeout | same as HTTP (15 s) |
| metadata | no pseudo-headers (`:…`) and no `grpc-*`; `Authorization` ok |

Not in this slice: client-streaming, bidi, gRPC-Web. Stop/resume tear open streams.

Reference: `plugins/youtube` (`StreamList`).

## `net.bridge`

Grant `net.bridge`. Feature `bridge`. Same ABI as `net.ws`, but **loopback only** — path to OBS/VTS and other local software. Software protocol lives in wasm, not Core.

```text
net_bridge::connect(url) -> Result<u32, string>
net_bridge::send_text(handle, message) -> Result<(), string>
net_bridge::close(handle) -> Result<(), string>
```

| | `net.ws` | `net.bridge` |
| --- | --- | --- |
| URL | `wss://` + hosts ∩ whitelist | only `ws://` to `127.0.0.1` / `::1` / localhost |
| Frames | opaque text → `Ready::WsText` / `WsClosed` | same |
| Protocol | in wasm | in wasm (OBS/VTS — not in Core) |

| Ceiling | Value |
| --- | --- |
| scheme | `ws` only (no TLS in this slice) |
| sockets | ≤ 2 (separate pool from `net.ws`) |

Raw TCP and `net.ws` on loopback are forbidden. Endpoint (host/port/password) — plugin settings. In `dev` without live software — connect fails / log. Reference: `modus new bridge`, `plugins/obs-bridge`.

## Consequence

Import without grant — soft-link ok; call without cap — `no grant …`. Network past the host (WASI / own socket) — `pack` rejects. `dev` vs Core network divergence = SDK bug.

Next chapter — [KV, act, alerts](06-kv-act-alerts.md).
