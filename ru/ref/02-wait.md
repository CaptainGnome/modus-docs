# Жизненный цикл и `wait`

Если это первый плагин — цикл на пальцах в [туториале `dev`](../start/03-dev.md). Если нужен контракт `Guest` / `Ready` — эта глава.

**Правило.** В `run` длинный цикл только через `wait::wait`. Стоп — не реконнект: `Ready::Stop` и `HostError::is_stop()` выходят из цикла, не в backoff.

## Три вызова хоста

`Guest`: `init` → `run` → `shutdown`. Других точек входа нет.

| Метод | Поток | Что можно |
| --- | --- | --- |
| `init` | тот же, что грузит модуль | коротко: `log`, `subscribe`, `settings.get`. Не сеть в цикле. Epoch ~500 ms (50 тиков × 10 ms) → trap |
| `run` | `plugin-{id}` | только `wait` (и вызовы хоста из веток `Ready`). Вернулись из `run` — плагин молчит, пока Core не `reload` (логин / вкл) |
| `shutdown` | после `run`, в т.ч. после trap | сокеты рвёт Core; гость ничего не обязан закрывать |

Второго потока из wasm нет. Колбэков нет: хост будит `wait`.

`subscribe` — в `init`. Без него `Ready::Bus` не придёт. В `dev` учебные события кладут сразу после `init`: подписка только в `run` — письма уже выкинули. `wait` историю журнала не реплеит. Прошлое — грант `history.read` (`history_read::read`), не `Ready::Bus`.

## `Ready`

База, грант не нужен:

```text
wait::subscribe()
wait::set_timer(ms)   // один one-shot; 0 — снять
wait::wait() -> Ready
```

| Вариант | Когда | Что делать |
| --- | --- | --- |
| `Stop` | выкл / удаление / Ctrl+C в `dev` | `return` из `run`. Флаг стопа важнее очереди: даже если в inbox ещё кадры |
| `Bus` | событие шины после `subscribe` | consumer / логика бота. Inbox **64**; полный — drop (`шина: inbox {id} полный, drop`), не блок |
| `WsText` / `WsClosed` | кадр / обрыв WS | коннектор. Ping/pong хост закрывает сам |
| `Timer` | сработал `set_timer` | свой таймер. Не путать с backoff |
| `Settings` | Core сохранил форму этого плагина | перечитать `settings.get`. В `init` `get` без `wait` ок |
| `Act` | припаркованный `chat.act` (send/delete/timeout/ban/unban) | коннектор исполняет протокол и зовёт `chat_complete`. Нет живого коннектора — сразу ошибка тому, кто вызвал `act`. Это не канон `Moderation` |
| `Resume` | после сна Windows (power resume) | коннектор: закрыть WS-сессию и retry, как на `WsClosed`. Параллельно Core эмитит `system` «сеть после сна» на шину (для consumer/UI). Не replay шины. `wait_backoff` на `Resume` выходит сразу (`false`) |
| `Ui` | кадр со страницы слота | грант `ui.slot` + слот |
| `MediaEnded` | конец / `stop` у `media.audio` play | роль `player`: `release` cache-key, если был |

После стопа вызовы хоста отдают `"остановлен"` (`HostError::Stopped`). `clock::sleep_ms` смотрит стоп каждые 50 ms — не замена `wait`.

Успешный логин в Core: `reload` инстанса, `run` с нуля, `list_accounts` уже не пуст. Нет аккаунта — ждать `Stop`, чат не выдумывать.

## Стоп и backoff

`HostError::classify` / `is_stop()` — [ошибки хоста](04-errors.md), подробно — [api/03-errors](../api/03-errors.md). `Stopped` и `Revoked` — не сеть.

`modus_sdk::wait_backoff(ms) -> bool`: ставит таймер, крутит `wait`, **true** если стоп (в т.ч. `Act` во время backoff закрывает job ошибкой «нет соединения»). `Resume` — как сработавший таймер: **false**, немедленный retry. Каркас `new connector` и [`plugins/twitch`](../../../plugins/twitch) так и делают. Не писать свой `sleep` + реконнект вокруг `"остановлен"`.

Константы: `BACKOFF_START_MS` 1 s, потолок `BACKOFF_MAX_MS` 30 s, `next_backoff_ms`.

## Trap, `dev`, память

Trap в `init`/`run` — дело **Core**, не `dev`: рестарт 1 s, затем 2 s; 3 падения за 60 s → карантин, пока стример не включит снова. В `dev` Ctrl+C = `Stop`, join потока 5 s (`не остановить` — гость застрял вне `wait`).

Память инстанса **16 MiB**. Диск гостю не виден. RAM wasm сгорает при выгрузке; KV, settings, аккаунты, журнал — у Core.

Эталон цикла: каркас `modus new consumer` / `new connector`, живой коннектор — [`plugins/twitch/src/lib.rs`](../../../plugins/twitch/src/lib.rs).
