# Сеть и auth

Если это первый плагин — replay в [туториале коннектора](../start/07-connector.md). Если нужен контракт `auth.token` / `net.*` — эта глава.

**Правило.** Секрет приложения и refresh — у Core (или брокера), не в wasm и не в git плагина. Гость получает короткий access через `auth.token` и ходит в сеть только через хост.

## Auth

Грант `auth.token`. Модуль SDK: `auth_token`.

```text
list-accounts() -> list<string>
token(account-id) -> result<string, string>
```

- Без гранта / на стопе — пустой список; `token` → отказ.
- Чужой id → `foreign account` (`HostError::Revoked`).
- Refresh отозван → `refresh revoked`.
- После успешного логина в Core плагин **перезапускается**: `run` снова видит аккаунты.
- Нет аккаунта → каркас ждёт `Stop`, чат не выдумывать.

Режимы манифеста (`auth_mode`): `broker` / `pkce` / `device` / `api` / `custom`. `client_secret` в манифесте запрещён. В `dev` — `--token` / `--token-file` (фейковый access), не сейф Core.

Оболочку OAuth гоняет Core. Протокол площадки — у плагина через `net.*` + `token`.

При `auth_mode: broker` в манифесте — `broker_url` (host ∈ `hosts`). Опционально `scope_delimiter` (VK — `","`), `redirect_uri` (https-bounce брокера).

Эталон: `modus new connector`, каркас `modus new connector`.

## HTTP

Грант `net.http`. Только `https://`. Литеральный IP, loopback, private, link-local — отказ. Хост ∈ `hosts` манифеста ∩ whitelist Core. Редирект: до 5 hop, каждый до connect (манифест ∩ whitelist + pinned DNS). Кросс-origin снимает гостевые заголовки. Hop-by-hop (`Host`, `Content-Length`, …) гость задать не может.

Лимиты: тело 1 MiB, таймаут 15 s, ≤4 inflight. 429 хост не ретраит.

В `dev`: без сети — `--http-file` (JSON, ключ URL без query).

## WebSocket

Грант `net.ws`. Только `wss://`. ≤2 сокета. Кадры — `Ready::WsText` / `WsClosed`. Стоп рвёт TCP. Loopback / private — отказ.

В `dev`: `--replay` (строки файла) или один live URL из `hosts`.

### WH-труба (webhook → WS)

Площадка с web-push не достигает десктопа напрямую. Коннектор декларирует `wh_url` в манифесте (host ∈ `hosts`), затем `net.ws.connect` на `wss://<host>/v1/wh/ws`. Core делает auto-bind (attestation → ticket) без новых импортов ABI. Дальше по WS — рецепт `ingress` / `route`; кадры webhook приходят как обычный `WsText`. Dev override: `MODUS_WH_URL`.

Поля — [api/манифест](../api/00-manifest.md#wh-труба-wh_url). Контракт — [`external_apis/kick_api/broker.md`](../../../external_apis/kick_api/broker.md).

## gRPC

Грант `net.grpc` (`modus:abi@2.1.0`). Unary `call` и server-streaming `open-stream` / `cancel`. Тело — сырые protobuf bytes; TLS обязателен; authority ∈ `hosts` ∩ whitelist. Metadata: без псевдо-заголовков и без `grpc-*`. Stream-кадры — `Ready::GrpcMsg` / `GrpcClosed`. Concurrent streams — квота как у WS. Полный контракт — [api/05-emit-auth-net](../api/05-emit-auth-net.md#netgrpc).

## Bridge (loopback)

Грант `net.bridge`. Тот же ABI, что `net.ws`, но только `ws://` на loopback (`127.0.0.1` / `::1`). Путь к OBS/VTS: протокол в wasm, не в Core. `net.ws` на loopback запрещён. Endpoint — settings плагина.

Полный контракт — [api/05-emit-auth-net](../api/05-emit-auth-net.md#netbridge). Эталон: `modus new bridge`.

## Следствие

Импорт без гранта — soft-link ок; вызов без cap — `no grant …`. Сеть в обход хоста (WASI / свой сокет) — `pack` отказ.

Следующая глава — [settings / KV / act / алерты / слоты](07-host-apis.md).
