# Ошибки хоста

**Правило.** Строки ошибок — часть ABI 2. В коде: `HostError::classify(err)`, не парсить литералы своими `contains`. `is_stop()` — не глотать в реконнект.

Сжатый обзор — [ref/04-errors](../ref/04-errors.md). Эталон выхода из backoff: `modus new connector`.

## Classify

```rust
use modus_sdk::HostError;

match HostError::classify(&err) {
    HostError::Stopped | HostError::Revoked => { /* выйти из run */ }
    HostError::Grant => { /* нет capability */ }
    HostError::Network => { /* backoff / другой URL */ }
    HostError::Other(_) => { /* остальное */ }
}
```

| Вариант | Как определяется | Типичные строки |
| --- | --- | --- |
| `Stopped` | точное равенство | `stopped` |
| `Grant` | префикс | `no grant …` (`bus.emit`, `net.ws`, …) |
| `Revoked` | точное равенство | `refresh revoked`, `foreign account` |
| `Network` | фиксированный набор / подстроки | см. таблицу ниже |
| `Other` | всё остальное | `no platform_id`, `system is Core-only`, `TooLarge`, валидации job, … |

`is_stop()` = `Stopped` | `Revoked`. Также работает `HostError::from(err_str)`.

## Network: точные совпадения и шаблоны

| Строка / шаблон | Смысл |
| --- | --- |
| `https/wss only` | схема не https/wss |
| `http quota` / `ws quota` | inflight / лимит сокетов |
| `body too large` / `response too large` | > 1 MiB |
| `literal IP forbidden` | URL с IP вместо DNS |
| `no tcp for ws` | WS без транспорта |
| содержит `not in manifest` | хост не в `hosts` / `embed_hosts` |
| содержит `not in Core whitelist` | политика Core |
| начинается с `forbidden address ` | private / loopback / link-local |

## Частые строки (Other и общие)

| Строка | Смысл |
| --- | --- |
| `stopped` | выкл / удаление / стоп инстанса / Ctrl+C в `dev` |
| `no grant …` | нет capability |
| `no platform_id` | канон/auth без поля в манифесте |
| `system is Core-only` | плагин эмитит `system` |
| `custom cannot mask canon` | `custom.kind` занял имя канона |
| `opaque is not JSON` | хвост не разобрать |
| `foreign account` | `token` не вашего аккаунта |
| `refresh revoked` | нужен перелогин |
| `plugin id: reverse-DNS required (com.publisher.name)` | короткий id |
| `client_secret forbidden in manifest` | секрет в пакете |
| `api mode: paste token` | api без токена в UI |
| `host X not in manifest` / `not in Core whitelist` | сеть |
| `TooLarge` | событие шины > 64 KiB |
| `platform_id … already taken` | второй живой плагин площадки |
| `no connection` | `chat_complete` во время backoff SDK |
| `manual WIT plus SDK — dual bindgen` | `pack`/`check` каталога |

Новые строки без мажора SDK, попавшие в `Other`, — нормально; `classify` расширяют только согласованно с ABI.

Следующая глава — [базовые host API](04-base-host.md).
