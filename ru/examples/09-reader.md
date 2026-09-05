# Reader

Роль читает журнал канона через `history.read` и параллельно слушает живую шину. History — **не** replay в `Ready::Bus`: отдельный API для страниц и recovery (alerter так же). Эталон только логирует виды payload и flags.

## Feature и гранты

| | |
| --- | --- |
| SDK feature | `reader` |
| Обязательный грант | `history.read` |
| База | `wait` + `subscribe` для живого `Bus` |

Карта — [ref/01-roles](../ref/01-roles.md). API — [api/09-bridge-history-rates-catalog](../api/09-bridge-history-rates-catalog.md).

## Манифест

```json
{
  "id": "com.modus.reader",
  "name": "Reader",
  "version": "0.1.0",
  "abi": 2,
  /* страница журнала канона; не emit и не сеть */
  "capabilities": ["history.read"]
}
```

| Поле | Зачем |
| --- | --- |
| `history.read` | `history_read::read(cursor, limit)` |
| нет emit / сети | роль не пишет на шину и не ходит наружу |

## Код

**Dump.** В `init` и в начале `run` — страница без курсора, до 50 событий. Каждое логируется с тегом `history`.

```rust
fn dump_history() {
    // None = с начала журнала; 50 = limit страницы
    match history_read::read(None, 50) {
        Ok(page) => {
            // это НЕ Ready::Bus — отдельный снимок журнала
            for event in page.events {
                log_bus("history", &event);
            }
            // page.alert_shown эталон не трогает (см. alerter recover)
        }
        Err(err) => log::log(Level::Warn, &err),
    }
}
```

**Живая шина.** После dump — обычный `wait`; `Ready::Bus` с тем же форматтером и тегом `bus`.

```rust
fn run() {
    // сначала прошлые события из журнала
    dump_history();
    loop {
        match wait::wait() {
            Ready::Stop => return,
            // живой канон после subscribe (нужен в init)
            Ready::Bus(event) => log_bus("bus", &event),
            // остальные Ready — не наш сценарий
            // …
        }
    }
}
```

**Разбор.** `payload_kind` / `payload_text` — учебный switch по `Payload::*` и `Fragment::Text`. Flags: `hide_chat`, `skip_alert`, `highlight`, `mask`.

```rust
fn log_bus(tag: &str, event: &Event) {
    log::log(
        Level::Info,
        &format!(
            // tag отличает history-снимок от живого bus
            "{tag} {} {}:{} hide={} skip={} … {}",
            payload_kind(&event.payload),
            event.source.plugin_id,
            event.source.channel,
            // флаги канона: скрыть в чате / не алертить
            event.flags.hide_chat,
            event.flags.skip_alert,
            payload_text(&event.payload)
        ),
    );
}
```

Поле `page.alert_shown` эталон не использует — оно для alerter recovery ([07-alerter](07-alerter.md)).

## Ассеты

Нет. Только `manifest` + `src/lib.rs`.

## Запуск

```powershell
modus new <role>  # scaffold, then modus dev <dir>
```

Учебные emit от `dev` появятся и в history (если хост пишет журнал), и как `Ready::Bus`. Полный crate: [`modus new reader`](modus new reader).

## Типичные ошибки хоста

| Строка / ситуация | Смысл |
| --- | --- |
| `нет гранта history.read` | вызов без capability |
| пустая страница | журнал ещё пуст / другой инстанс |
| ожидание history в `wait` | ошибка модели: history только через `read` |

См. [ref/02-wait](../ref/02-wait.md), [ref/04-errors](../ref/04-errors.md).
