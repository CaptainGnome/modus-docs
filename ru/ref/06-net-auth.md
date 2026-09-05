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

Эталон: `modus new connector`, каркас `modus new connector`.

## HTTP

Грант `net.http`. Только `https://`. Литеральный IP, loopback, private, link-local — отказ. Хост ∈ `hosts` манифеста ∩ whitelist Core. Редирект: до 5 hop, каждый проверяется.

Лимиты: тело 1 MiB, таймаут 15 s, ≤4 inflight. 429 хост не ретраит.

В `dev`: без сети — `--http-file` (JSON, ключ URL без query).

## WebSocket

Грант `net.ws`. Только `wss://`. ≤2 сокета. Кадры — `Ready::WsText` / `WsClosed`. Стоп рвёт TCP.

В `dev`: `--replay` (строки файла) или один live URL из `hosts`.

## Следствие

Импорт без гранта — soft-link ок; вызов без cap — `no grant …`. Сеть в обход хоста (WASI / свой сокет) — `pack` отказ.

Следующая глава — [settings / KV / act / алерты / слоты](07-host-apis.md).
