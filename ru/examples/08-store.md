# Store

Роль хранит своё KV (`storage.kv`) и читает настройки пакета. Чужие ключи не видны; секреты площадки сюда не кладут — для них `settings` типа `secret`. Эталон — счётчик загрузок, чтение ассета и реакция на `Ready::Settings`.

## Feature и гранты

| | |
| --- | --- |
| SDK feature | `store` |
| Обязательный грант | `storage.kv` |
| База без гранта | `settings`, `assets`, `wait`, `log` |

Карта — [ref/01-roles](../ref/01-roles.md). API — [api/06-kv-act-alerts](../api/06-kv-act-alerts.md).

## Манифест

```json
{
  "id": "com.modus.store",
  "name": "Store",
  "version": "0.1.0",
  "abi": 2,
  /* единственный грант — изолированное KV этого плагина */
  "capabilities": ["storage.kv"]
  /* slots / сеть / emit — нет: роль не UI и не площадка */
}
```

| Поле | Зачем |
| --- | --- |
| `capabilities` | единственный грант — своё KV |
| нет `slots` / сети | роль не рисует UI и не ходит в HTTP |

## Код

**Init.** Подписка (на `Settings`), `get`/`set` счётчика `boots`, чтение `assets/note.txt`, i18n-label в settings.

```rust
fn init() {
    // subscribe нужен для Ready::Settings (не для Bus в этом демо)
    wait::subscribe();
    // прочитать прошлый счётчик загрузок из своего KV
    let n = match storage_kv::get("boots") {
        Ok(Some(value)) => value.parse::<u32>().unwrap_or(0),
        Ok(None) => 0, // ключа ещё нет — первая загрузка
        Err(err) => { log::log(Level::Warn, &err); 0 }
    };
    let next = n.saturating_add(1);
    // persist на id плагина (в Core); в dev — RAM на процесс
    let _ = storage_kv::set("boots", &next.to_string());
    // assets::read — файлы из пакета, не KV
    match assets::read("note.txt") {
        Ok(bytes) => log::log(Level::Info, &format!("asset: {}", String::from_utf8_lossy(&bytes))),
        Err(err) => log::log(Level::Warn, &err),
    }
    // label status в форме settings: i18n + подстановка {{n}}
    let _ = settings::set_label_i18n(
        "status",
        "status.boots",
        Some(&format!(r#"{{"n":{next}}}"#)),
    );
}
```

**Settings.** Хост будит `Ready::Settings` после смены формы; гость читает поля, не парсит JSON схемы сам.

```rust
fn on_settings() {
    // поля из assets/settings.json — get по id, не парсить схему
    let note = settings::get("note").unwrap_or_default();
    let echo = settings::get("echo").as_deref() == Some("true");
    if echo {
        // опциональный «эхо» текста note в лог
        log::log(Level::Info, &format!("note {note}"));
    }
    // secret: значение есть/нет, в лог само значение не пишем
    let secret = settings::get("token").filter(|v| !v.is_empty());
    log::log(Level::Info, &format!(
        "secret={}", if secret.is_some() { "yes" } else { "no" }
    ));
}
```

В `run` цикл ждёт `Stop` / `Settings` / `Resume`; шину и алерты игнорирует — роль не consumer шины по смыслу демо, но `subscribe` нужен для settings wake.

## Ассеты

| Путь | Назначение |
| --- | --- |
| `assets/settings.json` | форма: `note`, `echo`, `token` (secret), `status` (label) |
| `assets/note.txt` | пример `assets::read` |
| `assets/i18n/{en,ru}.json` | ключи `status.boots`, подписи полей |

## Запуск

```powershell
modus dev plugins/store
# смена настроек в CLI: modus dev plugins/store --settings …
```

Полный crate: [`../../../plugins/store`](../../../plugins/store).

В `dev` KV — RAM на процесс (после рестарта CLI счётчик с нуля). В Core persist привязан к `id` плагина.

## Типичные ошибки хоста

| Строка / ситуация | Смысл |
| --- | --- |
| `нет гранта storage.kv` | вызов без capability |
| квота KV (256 KiB / 256 ключей / 16 KiB value) | слишком большой `set` |
| шторм set/delete ~60/с | rate limit |
| пустой KV после рестарта `dev` | ожидаемо для S5 |

См. [ref/04-errors](../ref/04-errors.md), [ref/09-limits](../ref/09-limits.md).
