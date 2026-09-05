# Consumer

Роль без грантов: слушать канон шины и логировать. Нужна, когда плагину нечего эмитить и некуда ходить по сети — только подписка и реакция на чужие события.

## Feature и гранты

| | |
| --- | --- |
| Feature SDK | `consumer` |
| Обязательные гранты | нет |
| База | `wait`, `log`, `types` (и прочее без cap) |
| Карта | [ref/01-roles](../ref/01-roles.md) |

Эталон: [`modus-examples/consumer`](../../../modus-examples/consumer).

## Манифест

Минимальный паспорт — без `capabilities`, `platform_id`, слотов:

```json
{
  /* reverse-DNS id пакета — уникален в Core */
  "id": "com.modus.consumer",
  /* человекочитаемое имя в UI */
  "name": "Consumer",
  "version": "0.1.0",
  "author": "modus",
  /* версия ABI гостя; сейчас контракт = 2 */
  "abi": 2
  /* capabilities / platform_id / slots — намеренно нет:
     роль только слушает, ничего не эмитит и не рисует */
}
```

| Поле | Зачем |
| --- | --- |
| `id` | reverse-DNS пакета |
| `abi` | версия контракта гостя (сейчас `2`) |

## Код

**Подписка в `init`.** Без `subscribe` учебные письма `dev` и чужой канон в `Ready::Bus` не попадут.

```rust
fn init() {
    // лог при загрузке модуля хостом
    log::log(Level::Info, "consumer init");
    // открыть ящик шины ДО run — иначе Ready::Bus пустой
    wait::subscribe();
}
```

**Цикл `run`.** Спим в `wait`; обрабатываем только `Stop` и `Bus`. Остальные `Ready` у consumer в типичном сценарии пустые.

```rust
fn run() {
    loop {
        // блокируемся, пока хост не разбудит (Stop / Bus / …)
        match wait::wait() {
            // Ctrl+C / выкл плагина — выходим из run чисто
            Ready::Stop => return,
            // чужой канон с шины (после subscribe)
            Ready::Bus(event) => log_bus(&event),
            // Ws / Act / Ui / Alert* — у consumer обычно пусто, игнор
            _ => {}
        }
    }
}
```

**Разбор payload.** Эталон печатает kind, источник, флаги и текст фрагментов — удобный «сниффер» шины при отладке коннектора.

```rust
fn log_bus(event: &Event) {
    // склеить Fragment::Text из payload (эмодзи/mention пропускаем)
    let text = payload_text(&event.payload);
    log::log(
        Level::Info,
        &format!(
            // kind = message|donation|…; plugin_id:channel — кто эмитил
            "bus {} {}:{} … {}",
            payload_kind(&event.payload),
            event.source.plugin_id,
            event.source.channel,
            text
        ),
    );
}
```

## Как запустить

```powershell
modus new consumer --id com.you.bus --dir bus
modus dev ../modus-examples/consumer
```

Свой каркас: `modus dev bus`. Без флагов `dev` кладёт учебные `message` / `donation` / `reward` сразу после `init`. См. [start/03-dev](../start/03-dev.md), флаги — [api/11-cli-dev](../api/11-cli-dev.md).

## Типичные ошибки хоста

| Ситуация | Строка / эффект |
| --- | --- |
| Вызов emit / сети без гранта | `no grant …` (`HostError::Grant`) |
| Ctrl+C / выкл | `stopped` → `Ready::Stop` |
| Забыли `subscribe` | в логе есть `emit … fixture hello`, нет `bus message …` |

Полный список — [api/03-errors](../api/03-errors.md).
