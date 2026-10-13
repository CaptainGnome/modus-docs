# Emit, auth, сеть

**Правило.** Секрет приложения и refresh — у Core (или брокера), не в wasm и не в git. Гость получает короткий access через `auth.token` и ходит в сеть только через хост. Emit — грант + `platform_id`.

Сжатый обзор — [ref/06-net-auth](../ref/06-net-auth.md). Эталон: `modus new connector`, каркас `modus new connector`.

## `bus.emit`

См. полный канон — [02-canon-bus](02-canon-bus.md).

```text
bus_emit::emit(channel, payload, opaque?) -> Result<(), String>
```

Кратко: штамп Core; `system` запрещён гостю; тело > 64 KiB → `TooLarge`; no grant → `no grant bus.emit`.

## `auth.token`

Грант `auth.token`. Модуль SDK: `auth_token`.

```text
list_accounts() -> list<string>
token(account_id) -> Result<string, string>
```

| Ситуация | Поведение |
| --- | --- |
| no grant / стоп | пустой список; `token` → отказ |
| чужой `account_id` | `foreign account` (`HostError::Revoked`) |
| refresh revoked | `refresh revoked` |
| успешный логин в Core | инстанс **reload**, `run` с нуля |
| нет аккаунта | каркас ждёт `Stop`, чат не выдумывать |

### Режимы манифеста (концепт)

| `auth_mode` | Кто держит секрет | Что видит гость |
| --- | --- | --- |
| `broker` | брокер + Core | access после verified пакета |
| `pkce` | Core (public client) | access после браузерного логина |
| `device` | Core | access после device code |
| `api` | стример вставляет токен в UI | access из сейфа |
| `custom` | по полям URL | access после оболочки Core |

Поля URL/client_id — [00-manifest](00-manifest.md). В `dev`: `--token` / `--token-file` + `--account` (по умолчанию `dev`) — фейковый access **только процесса CLI**, в `.mplug` не попадает.

## Allowlist хостов

Концепт для гостя (`net.http` / `net.ws` / `net.grpc`):

1. URL/`authority` должен быть TLS-схемой (`https://` / `wss://` / gRPC `:443`).
2. Hostname ∈ `hosts` манифеста (для embed iframe — `embed_hosts`).
3. Hostname ∈ whitelist политики Core.
4. Литеральный IP, loopback, private, link-local — отказ.

Редиректы HTTP: до **5** hop; каждый hop до connect — https, манифест ∩ whitelist, pinned DNS. Кросс-origin снимает все гостевые заголовки (включая `Authorization`). Гость не задаёт hop-by-hop (`Host`, `Content-Length`, `Transfer-Encoding`, `Connection`, …). Ошибки класса `Network` — [03-errors](03-errors.md).

Исключение: локальный софт — только [`net.bridge`](#netbridge) (plain `ws://` на loopback), не `net.ws`.

`new connector` **не** подставляет официальный Twitch `client_id`, `broker` и хосты Twitch — автор площадки пишет сам.

## `net.http`

Грант `net.http`.

```text
fetch(method, url, headers, body) -> Result<HttpResponse, String>
```

Ответ: `status`, `headers`, `body`.

| Потолок | Значение |
| --- | --- |
| схема | только https |
| тело запроса / ответа | 1 MiB |
| таймаут | 15 s |
| inflight | ≤ 4 |
| 429 | хост **не** ретраит |

В `dev` без сети: `--http-file` — JSON-карта ответов, ключ = URL **без** query.

## `net.ws`

Грант `net.ws`.

```text
connect(url) -> Result<u32, String>   // handle
send_text(handle, message) -> Result<(), String>
close(handle) -> Result<(), String>
```

Кадры приходят как `Ready::WsText { handle, text }` / `Ready::WsClosed(handle)`. Ping/pong закрывает хост. Стоп рвёт TCP.

| Потолок | Значение |
| --- | --- |
| схема | только wss |
| сокетов | ≤ 2 |

В `dev`: `--replay file` (текстовые кадры по строке) **или** один live `wss://` из `hosts` (не private).

### WH auto-bind

Если в манифесте есть `wh_url` (host ∈ `hosts`) и `connect` идёт на этот host (path `/v1/wh/ws`), Core **до** upgrade:

1. attestation подписанного `.mplug`;
2. `POST /v1/wh/bind` → one-shot ticket;
3. connect уже на `…/v1/wh/ws?ticket=`.

Guest bind не вызывает и ticket не знает. Unsigned / без trusted key — bind и OAuth broker недоступны. Поле и override — [00-manifest § WH](00-manifest.md#wh-труба-wh_url).

## `net.grpc`

Грант `net.grpc`. Транспорт сырых protobuf bytes; decode/encode — в wasm. Пакет WIT `modus:abi@2.1.0`.

```text
call(authority, path, headers, request) -> Result<GrpcResponse, String>
open-stream(authority, path, headers, request) -> Result<u32, String>  // handle
cancel(handle) -> Result<(), String>
```

`GrpcResponse`: `status` (gRPC code, `0` = OK), `message`, `body` (пусто при `status != 0`).

| Режим | Поведение |
| --- | --- |
| unary `call` | один request → один response; блокирует guest-вызов (как `net.http` fetch); без `wait` |
| server-stream `open-stream` | кадры `Ready::GrpcMsg { handle, bytes }` / `Ready::GrpcClosed { handle, status, message }` |

| Потолок | Значение |
| --- | --- |
| TLS | обязателен |
| authority | hostname ∈ `hosts` ∩ whitelist; порт по умолчанию 443 |
| request / message | 1 MiB |
| concurrent streams | как квота WS (≤ 2) |
| unary timeout | как HTTP (15 s) |
| metadata | без псевдо-заголовков (`:…`) и без `grpc-*`; `Authorization` ок |

Не в срезе: client-streaming, bidi, gRPC-Web. Stop/resume рвут открытые streams.

Эталон: `plugins/youtube` (`StreamList`).

## `net.bridge`

Грант `net.bridge`. Feature `bridge`. Тот же ABI, что `net.ws`, но **только loopback** — путь к OBS/VTS и прочему local soft. Протокол софта — в wasm, не в Core.

```text
net_bridge::connect(url) -> Result<u32, string>
net_bridge::send_text(handle, message) -> Result<(), string>
net_bridge::close(handle) -> Result<(), string>
```

| | `net.ws` | `net.bridge` |
| --- | --- | --- |
| URL | `wss://` + hosts ∩ whitelist | только `ws://` на `127.0.0.1` / `::1` / localhost |
| Кадры | opaque text → `Ready::WsText` / `WsClosed` | то же |
| Протокол | в wasm | в wasm (OBS/VTS — не в Core) |

| Потолок | Значение |
| --- | --- |
| схема | только `ws` (без TLS в срезе) |
| сокетов | ≤ 2 (отдельный пул от `net.ws`) |

Сырой TCP и `net.ws` на loopback — запрещены. Endpoint (host/port/пароль) — settings плагина. В `dev` без живого софта — отказ connect / лог. Эталон: `modus new bridge`, `plugins/obs-bridge`.

## Следствие

Импорт без гранта — soft-link ок; вызов без cap — `no grant …`. Сеть в обход хоста (WASI / свой сокет) — `pack` отказ. Расхождение `dev` и Core по сети = баг SDK.

Следующая глава — [KV, act, алерты](06-kv-act-alerts.md).
