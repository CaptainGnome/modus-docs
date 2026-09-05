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

Концепт для гостя:

1. URL должен быть `https://` или `wss://`.
2. Hostname ∈ `hosts` манифеста (для embed iframe — `embed_hosts`).
3. Hostname ∈ whitelist политики Core.
4. Литеральный IP, loopback, private, link-local — отказ.

Редиректы HTTP: до **5** hop, каждый hop проверяется теми же правилами. Ошибки класса `Network` — [03-errors](03-errors.md).

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

## Следствие

Импорт без гранта — soft-link ок; вызов без cap — `no grant …`. Сеть в обход хоста (WASI / свой сокет) — `pack` отказ. Расхождение `dev` и Core по сети = баг SDK.

Следующая глава — [KV, act, алерты](06-kv-act-alerts.md).
