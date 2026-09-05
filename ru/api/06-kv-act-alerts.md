# KV, chat.act, алерты

**Правило.** Права — манифест + deny на вызове. В Core — прод-семантика ниже. В `modus dev` (S5): KV/settings — RAM на процесс; `alert.enqueue` / `chat.act` — id + лог в stderr, **не** очередь Core и не парк до второго wasm.

Сжатый обзор — [ref/07-host-apis](../ref/07-host-apis.md).

## `storage.kv`

Грант `storage.kv`. Feature `store`. Чужое KV не видно. Секреты / токены сюда не класть.

```text
get(key) -> Result<Option<String>, String>
set(key, value) -> Result<(), String>
delete(key) -> Result<(), String>
list_keys(prefix) -> Result<list<string>, String>
```

| Квота | Значение |
| --- | --- |
| суммарно | 256 KiB |
| ключей | 256 |
| значение | ≤ 16 KiB |
| шторм set/delete | 60/с |

Рестарт `dev` — пусто. В Core persist привязан к `id` плагина. Эталон: [`plugins/store`](../../../plugins/store).

## `chat.act` / `chat_complete`

Грант `chat.act` у командира. Feature `commander`. Единственный путь send/delete/timeout/ban/unban из гостя.

```text
chat_act::act(job) -> Result<string, string>   // id job
// job: platform, channel, kind, text?, message_id?, target_user_id?, duration_sec?
```

Виды `kind`: `send` / `delete` / `timeout` / `ban` / `unban`.

### Поток в Core (концепт)

1. Командир (или композер Core) зовёт `act`. Хост проверяет грант и валидирует job (пустое send, timeout 0, нет цели — отказ), подставляет `account_id`, **паркует** job.
2. Нет живого коннектора этой `platform_id` — сразу ошибка вызывающему, шины нет.
3. Коннектор в `wait` получает `Ready::Act(req)` с `id`.
4. Исполняет протокол площадки, зовёт `chat_complete::complete(&req.id, Ok(()) | Err(...))`.
5. На шину само ничего не кладётся. Факт появится только отдельным `bus.emit` из протокола.

| Потолок | Значение |
| --- | --- |
| текст send | ≤ 500 |
| шторм act | ~10/с на плагин (у Core отдельно ~5/с) |
| таймаут complete | 15 s |

В `dev`: `act` → id + лог сразу; `--act file.json` (объект или массив) будит emitter/connector как `Ready::Act`. Эталон заявки — [`plugins/commander`](../../../plugins/commander); исполнитель — [`plugins/twitch`](../../../plugins/twitch) / имитация [`plugins/fixture`](../../../plugins/fixture).

Командир канон не эмитит и `complete` не вызывает.

## Алерты: enqueue + play/stop

Грант `alert.enqueue`. Feature `alerter`.

```text
enqueue(job) -> Result<string, string>   // job-id
complete(job_id, outcome) -> Result<(), string>
```

Job: `event_id`, `priority` (`follow`/`sub`/`raid`/`donation`/`reward`), `duration_ms`, `title`, `body`.

### Концепт кассы (Core)

1. Плагин ставит талон `enqueue` после интересного `Ready::Bus` (или recovery через `history.read`).
2. **Касса — Core**: очередь, приоритеты, skip, конфликт оверлеев. Гость очередь не ведёт.
3. Когда пора показать — Core будит alerter `Ready::AlertPlay { job_id, event_id, duration_ms }`.
4. Плагин гоняет свой `ui.slot` web (post JSON) / SFX; по окончании — `complete`.
5. Досрочный skip — `Ready::AlertStop` с тем же job.

В `dev`: enqueue/complete → stderr, **без** `AlertPlay`/`AlertStop` и без очереди 32. Не путать с прод-поведением.

Эталон: [`plugins/alerter`](../../../plugins/alerter). Голос — отдельный `player` (`media.audio`) или `custom` `tts.request`, не «Core говорит».

Следующая глава — [слоты и panel](07-ui-slots-panel.md).
