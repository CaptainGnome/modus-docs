# Жизненный цикл и `wait`

**Правило.** В `run` длинный цикл только через `wait::wait`. `Ready::Stop` и `HostError::is_stop()` выходят из цикла, не в backoff. Второго потока и колбэков из wasm нет: хост будит `wait`.

Сжатый контракт — [ref/02-wait](../ref/02-wait.md). Эталоны: [`modus-examples/consumer`](../../../modus-examples/consumer), `modus new connector`.

## Guest: три точки входа

| Метод | Поток | Что можно |
| --- | --- | --- |
| `init` | поток загрузки модуля | коротко: `log`, `subscribe`, `settings.get`, чтение assets. Не сеть в цикле. Epoch ~500 ms (50×10 ms) → trap |
| `run` | `plugin-{id}` | цикл `wait` и вызовы хоста из веток `Ready`. Вернулись — плагин молчит до `reload` (логин / вкл) |
| `shutdown` | после `run`, в т.ч. после trap | сокеты рвёт Core; гость ничего не обязан закрывать |

Экспорт:

```rust
use modus_sdk::{export, Guest, wait::{self, Ready}};

struct Plugin;
impl Guest for Plugin {
    fn init() { wait::subscribe(); }
    fn run() { /* wait loop */ }
    fn shutdown() {}
}
export!(Plugin);
```

## База wait (грант не нужен)

```text
wait::subscribe()
wait::set_timer(ms)   // один one-shot; 0 — снять
wait::wait() -> Ready
```

`subscribe` — в `init`. Без него `Ready::Bus` не придёт. В `dev` учебные события кладут сразу после `init`: подписка только в `run` — письма уже выкинули. `wait` журнал не реплеит. Прошлое — `history.read`.

## Все варианты `Ready`

| Вариант | Когда | Действие гостя |
| --- | --- | --- |
| `Stop` | выкл / удаление / Ctrl+C в `dev` | `return` из `run`. Флаг стопа важнее очереди inbox |
| `Bus(event)` | событие шины после `subscribe` | consumer / бот / alerter. Inbox **64**; полный — drop (`bus: inbox {id} full, drop`), не блок |
| `WsText` / `WsClosed` | кадр / обрыв WS | коннектор. Ping/pong закрывает хост |
| `Timer` | сработал `set_timer` | свой таймер; не путать с backoff |
| `Settings` | Core (или `dev --settings`) сохранил форму | перечитать `settings.get` |
| `Act(req)` | припаркованный `chat.act` | коннектор исполняет протокол → `chat_complete` с тем же `id`. Нет коннектора — сразу ошибка вызывающему. Не канон `Moderation` |
| `Resume` | power resume Windows | коннектор: рвать WS-сессию и retry как на `WsClosed`. Параллельно Core эмитит `system` «сеть после сна». Не replay шины. `wait_backoff` на `Resume` → `false` (сразу retry) |
| `Ui(bytes)` | кадр со страницы / panel | грант `ui.slot` + слот. В `dev`: `--ui` |
| `MediaEnded(id)` | конец трека или `media.audio` stop | роль `player`: при необходимости `media_cache::release` |
| `AlertPlay(cmd)` | касса Core выдала показ | alerter: свой overlay / SFX; потом `alert_enqueue::complete` |
| `AlertStop(cmd)` | касса сняла показ (skip / timeout) | свернуть overlay; complete если ещё не |

`alert-play` / `alert-stop`: поля `job-id`, `event-id`, `duration-ms`. Касса и очередь — **Core**, не гость. В `modus dev` (S5) enqueue пишет id в stderr **без** `AlertPlay`/`AlertStop`. Эталон показа — `modus new alerter`.

## Inbox 64

Очередь доставки в гостя на инстанс: **64** события. Переполнение — drop входящего, лог хоста, не блокировка эмиттера. Не путать с лимитом тела события 64 KiB.

## Стоп и backoff

После стопа вызовы хоста → `"stopped"` (`HostError::Stopped`). `clock::sleep_ms` смотрит стоп каждые 50 ms — не замена `wait`.

```rust
use modus_sdk::{wait_backoff, HostError, BACKOFF_START_MS, next_backoff_ms};

let mut delay = BACKOFF_START_MS;
loop {
    // … connect …
    if let Err(err) = work() {
        if HostError::classify(&err).is_stop() {
            return; // Stopped | Revoked
        }
        if wait_backoff(delay) {
            return; // Stop во время ожидания
        }
        delay = next_backoff_ms(delay);
    }
}
```

`wait_backoff(ms) -> bool`:

- ставит таймер, крутит `wait`;
- **true** — `Stop` (выйти);
- **false** — `Timer` или `Resume` (retry);
- во время backoff `Act` → `chat_complete(..., Err("no connection"))` (emitter/connector);
- прочие `Ready` глотаются до таймера/стопа.

Константы: старт 1 s, потолок 30 s, удвоение через `next_backoff_ms`.

## Trap, `dev`, память

| Тема | Поведение |
| --- | --- |
| Trap в Core | рестарт 1 s, затем 2 s; 3 падения / 60 s → карантин до ручного вкл |
| Trap в `dev` | процесс/поток; Ctrl+C = `Stop`; join 5 s (`cannot stop` — гость вне `wait`) |
| Память wasm | 16 MiB; диск гостю не виден |
| Persist | KV, settings, аккаунты, journal — у Core (в `dev` KV/settings — RAM процесса) |

Успешный логин в Core: `reload` инстанса, `run` с нуля, `list_accounts` уже не пуст. Нет аккаунта — ждать `Stop`, чат не выдумывать.

Следующая глава — [канон шины](02-canon-bus.md).
