# KV, chat.act, alerts

**Rule.** Rights — manifest + deny on call. In Core — production semantics below. In `modus dev` (S5): KV/settings — process RAM; `alert.enqueue` / `chat.act` — id + log to stderr, **not** the Core queue and not a park to a second wasm.

Compressed overview — [ref/07-host-apis](../ref/07-host-apis.md).

## `storage.kv`

Grant `storage.kv`. Feature `store`. Other KV is not visible. Do not put secrets / tokens here.

```text
get(key) -> Result<Option<String>, String>
set(key, value) -> Result<(), String>
delete(key) -> Result<(), String>
list_keys(prefix) -> Result<list<string>, String>
```

| Quota | Value |
| --- | --- |
| total | 256 KiB |
| keys | 256 |
| value | ≤ 16 KiB |
| set/delete storm | 60/s |

`dev` restart — empty. In Core persist is bound to plugin `id`. Reference: [`plugins/store`](../../../plugins/store).

## `chat.act` / `chat_complete`

Grant `chat.act` on the commander. Feature `commander`. The only guest path for send/delete/timeout/ban/unban.

```text
chat_act::act(job) -> Result<string, string>   // job id
// job: platform, channel, kind, text?, message_id?, target_user_id?, duration_sec?
```

`kind` values: `send` / `delete` / `timeout` / `ban` / `unban`.

### Flow in Core (concept)

1. Commander (or Core composer) calls `act`. Host checks grant and validates job (empty send, timeout 0, no target — rejected), fills `account_id`, **parks** the job.
2. No live connector for that `platform_id` — immediate error to caller, no bus.
3. Connector in `wait` gets `Ready::Act(req)` with `id`.
4. Runs platform protocol, calls `chat_complete::complete(&req.id, Ok(()) | Err(...))`.
5. Nothing is placed on the bus by itself. The fact appears only via a separate `bus.emit` from the protocol.

| Ceiling | Value |
| --- | --- |
| send text | ≤ 500 |
| act storm | ~10/s per plugin (Core separately ~5/s) |
| complete timeout | 15 s |

In `dev`: `act` → id + log immediately; `--act file.json` (object or array) wakes emitter/connector as `Ready::Act`. Request reference — [`plugins/commander`](../../../plugins/commander); executor — [`plugins/twitch`](../../../plugins/twitch) / simulation [`plugins/fixture`](../../../plugins/fixture).

Commander does not emit canon and does not call `complete`.

## Alerts: enqueue + play/stop

Grant `alert.enqueue`. Feature `alerter`.

```text
enqueue(job) -> Result<string, string>   // job-id
complete(job_id, outcome) -> Result<(), string>
```

Job: `event_id`, `priority` (`follow`/`sub`/`raid`/`donation`/`reward`), `duration_ms`, `title`, `body`.

### Cashier concept (Core)

1. Plugin places a ticket with `enqueue` after an interesting `Ready::Bus` (or recovery via `history.read`).
2. **Cashier is Core**: queue, priorities, skip, overlay conflicts. Guest does not run the queue.
3. When it is time to show — Core wakes alerter with `Ready::AlertPlay { job_id, event_id, duration_ms }`.
4. Plugin runs its `ui.slot` web (post JSON) / SFX; when done — `complete`.
5. Early skip — `Ready::AlertStop` with the same job.

In `dev`: enqueue/complete → stderr, **without** `AlertPlay`/`AlertStop` and without the queue of 32. Do not confuse with production behavior.

Reference: [`plugins/alerter`](../../../plugins/alerter). Voice — separate `player` (`media.audio`) or `custom` `tts.request`, not “Core speaks”.

Next chapter — [slots and panel](07-ui-slots-panel.md).
