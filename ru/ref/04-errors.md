# Ошибки хоста

Если это первый плагин — стоп на пальцах в [туториале `dev`](../start/03-dev.md). Если нужна таблица строк — эта глава.

**Правило.** Строки ошибок — часть ABI 2. В коде: `HostError::classify(err)`, не парсить литералы своими `contains`. `is_stop()` — не глотать в реконнект.

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
| `Stopped` | `stopped` |
| `Grant` | `no grant …` |
| `Revoked` | `refresh revoked`, `foreign account` |
| `Network` | `https/wss only`, `http quota` / `ws quota`, `body/response too large`, `… not in manifest`, `… not in Core whitelist`, `literal IP forbidden`, `forbidden address …` |
| `Other` | всё остальное (в т.ч. `no platform_id`, `system is Core-only`, `TooLarge`) |

`is_stop()` = `Stopped` | `Revoked`. Каркас коннектора и `modus new connector` так выходят из `wait_backoff`.

## Частые строки

| Строка | Смысл |
| --- | --- |
| `stopped` | выкл / удаление / стоп инстанса / Ctrl+C в `dev` |
| `no grant …` | нет capability |
| `no platform_id` | канон без поля в манифесте |
| `system is Core-only` | плагин эмитит `system` |
| `custom cannot mask canon` | `custom.kind` занял имя канона |
| `opaque is not JSON` | хвост не разобрать |
| `foreign account` | `token` не вашего аккаунта |
| `refresh revoked` | перелогин |
| `plugin id: reverse-DNS required (com.publisher.name)` | короткий id вроде `twitch` |
| `client_secret forbidden in manifest` | секрет в пакете |
| `api mode: paste token` | api не через «Войти» в браузер |
| `host X not in manifest` / `not in Core whitelist` | сеть |
| `TooLarge` | событие шины > 64 KiB |

Следующая глава — [CLI](05-cli.md).
