# Ошибки хоста

Если это первый плагин — стоп на пальцах в [туториале `dev`](../start/03-dev.md). Если нужна таблица строк — эта глава.

**Правило.** Строки ошибок — часть ABI 2. В коде: `HostError::classify(err)`, не разбор русских фраз своими `contains`. `is_stop()` — не глотать в реконнект.

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

| Вариант | Типичные строки |
| --- | --- |
| `Stopped` | `остановлен` |
| `Grant` | `нет гранта …` |
| `Revoked` | `refresh отозван`, `чужой аккаунт` |
| `Network` | `только https/wss`, `квота http` / `квота ws`, `тело/ответ слишком большое`, `… вне манифеста`, `… не в whitelist Core`, `литеральный IP запрещён`, `запрещённый адрес …` |
| `Other` | всё остальное (в т.ч. `нет platform_id`, `system только Core`, `TooLarge`) |

`is_stop()` = `Stopped` | `Revoked`. Каркас коннектора и [`plugins/twitch`](../../plugins/twitch) так выходят из `wait_backoff`.

## Частые строки

| Строка | Смысл |
| --- | --- |
| `остановлен` | выкл / удаление / стоп инстанса / Ctrl+C в `dev` |
| `нет гранта …` | нет capability |
| `нет platform_id` | канон без поля в манифесте |
| `system только Core` | плагин эмитит `system` |
| `custom не может маскировать канон` | `custom.kind` занял имя канона |
| `opaque не JSON` | хвост не разобрать |
| `чужой аккаунт` | `token` не вашего аккаунта |
| `refresh отозван` | перелогин |
| `plugin id: нужен reverse-DNS (com.publisher.name)` | короткий id вроде `twitch` |
| `client_secret запрещён в манифесте` | секрет в пакете |
| `режим api: вставьте токен` | api не через «Войти» в браузер |
| `хост X вне манифеста` / `не в whitelist Core` | сеть |
| `TooLarge` | событие шины > 64 KiB |

Следующая глава — [CLI](05-cli.md).
