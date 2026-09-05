# Ошибки хоста

**Правило.** Строки ошибок — часть ABI 2. В коде: `HostError::classify(err)`, не разбор русских фраз своими `contains`. `is_stop()` — не глотать в реконнект.

Сжатый обзор — [ref/04-errors](../ref/04-errors.md). Эталон выхода из backoff: [`plugins/twitch`](../../../plugins/twitch).

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
| `Stopped` | точное равенство | `остановлен` |
| `Grant` | префикс | `нет гранта …` (`bus.emit`, `net.ws`, …) |
| `Revoked` | точное равенство | `refresh отозван`, `чужой аккаунт` |
| `Network` | фиксированный набор / подстроки | см. таблицу ниже |
| `Other` | всё остальное | `нет platform_id`, `system только Core`, `TooLarge`, валидации job, … |

`is_stop()` = `Stopped` | `Revoked`. Также работает `HostError::from(err_str)`.

## Network: точные совпадения и шаблоны

| Строка / шаблон | Смысл |
| --- | --- |
| `только https/wss` | схема не https/wss |
| `квота http` / `квота ws` | inflight / лимит сокетов |
| `тело слишком большое` / `ответ слишком большой` | > 1 MiB |
| `литеральный IP запрещён` | URL с IP вместо DNS |
| `нет tcp для ws` | WS без транспорта |
| содержит `вне манифеста` | хост не в `hosts` / `embed_hosts` |
| содержит `не в whitelist Core` | политика Core |
| начинается с `запрещённый адрес ` | private / loopback / link-local |

## Частые строки (Other и общие)

| Строка | Смысл |
| --- | --- |
| `остановлен` | выкл / удаление / стоп инстанса / Ctrl+C в `dev` |
| `нет гранта …` | нет capability |
| `нет platform_id` | канон/auth без поля в манифесте |
| `system только Core` | плагин эмитит `system` |
| `custom не может маскировать канон` | `custom.kind` занял имя канона |
| `opaque не JSON` | хвост не разобрать |
| `чужой аккаунт` | `token` не вашего аккаунта |
| `refresh отозван` | нужен перелогин |
| `plugin id: нужен reverse-DNS (com.publisher.name)` | короткий id |
| `client_secret запрещён в манифесте` | секрет в пакете |
| `режим api: вставьте токен` | api без токена в UI |
| `хост X вне манифеста` / `не в whitelist Core` | сеть |
| `TooLarge` | событие шины > 64 KiB |
| `platform_id … уже занят` | второй живой плагин площадки |
| `нет соединения` | `chat_complete` во время backoff SDK |
| `WIT вручную плюс SDK — два bindgen` | `pack`/`check` каталога |

Новые строки без мажора SDK, попавшие в `Other`, — нормально; `classify` расширяют только согласованно с ABI.

Следующая глава — [базовые host API](04-base-host.md).
