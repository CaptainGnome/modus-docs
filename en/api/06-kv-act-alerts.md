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

`dev` restart — empty. In Core persist is bound to plugin `id`. Reference: `modus new store`.

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

In `dev`: `act` → id + log immediately; `--act file.json` (object or array) wakes emitter/connector as `Ready::Act`. Request reference — `modus new commander`; executor — `modus new connector` / simulation [`modus-examples/emitter`](../../../modus-examples/emitter).

Commander does not emit canon and does not call `complete`.

## Alerts: enqueue + play/stop

Grant `alert.enqueue`. Feature `alerter`.

```text
enqueue(job) -> Result<string, string>   // job-id
attach(attach-job) -> Result<string, string>
mark-ready(event-id, audio-key?, duration-ms?) -> Result<(), string>
complete(job_id, outcome) -> Result<(), string>
```

Job: `event_id`, `priority` (`follow`/`sub`/`raid`/`donation`/`reward`), `duration_ms`, `title`, `body`, `lane` (empty → `main`), `exclusive` (default true), `replay`, `pending_audio`, `pending_ttl_ms` (0 → Core default 15 s).

### Cashier concept (Core)

1. Plugin places a ticket with `enqueue` after an interesting `Ready::Bus` (or recovery via `history.read`).
2. **Cashier is Core**: per-lane queues, priorities, skip, exclusive, companions (`attach`). Guest does not run the queue.
3. Eligible play is **ready** jobs only. When it is time to show — Core wakes alerter with `Ready::AlertPlay { job_id, event_id, duration_ms }`.
4. Plugin runs its `ui.slot` web (post JSON) / SFX / voice; when done — `complete`.
5. Early skip — `Ready::AlertStop` with the same job; also `complete` (if not already called).

### Unready (`pending-audio`)

Slot appears in the cashier immediately; voice may catch up. Not HOL: a ready job behind **may** play before an unready job ahead.

| | Rule |
| --- | --- |
| `pending_audio: true` | job → `unready`; visible in UI (pending-voice badge) |
| Play | cashier **skips** unready; `AlertPlay` only after ready |
| `mark-ready` | waiting unready of the same `plugin_id` → ready; key none/empty = no voice; optional `duration_ms` update |
| TTL | `pending_ttl_ms` or default 15 s → ready **without** voice (not drop) |
| Exclusive unready | does **not** stop other lanes until real play |
| `replay` + `pending_audio` | rejected |
| Persist across restart | no |

Typical Core TTS flow: `start-render-tts` → immediate `enqueue(pending_audio)` → `Ready::tts-rendered` → `mark-ready` with key. Opaque `audio_key` → enqueue ready. Same contract for **any** async voice (third-party TTS → `media.cache` → `mark-ready`); the cashier does not know about SAPI. Details — [media.audio](08-media-cache-audio-embed.md).

### Shown alerts (`alert_shown`)

The event canon is **not** mutated: journal / bus have no “already shown” flag. Separate Core table:

| | Rule |
| --- | --- |
| When written | successful `alert_enqueue::complete(job_id, Ok(()))` |
| Key | `(event_id, plugin_id)` + `shown_at` |
| `Err` on complete | row is **not** written |
| Read path | `history_read::Page.alert_shown` — ids on this page already shown by **this** plugin |
| Why | recovery without mangling payload: alerter skips ids in `alert_shown` and does not enqueue again |
| Retention | ~1 h and ~2000-row cap (older rows pruned) |

In `dev`: enqueue / attach / mark-ready / complete → stderr, **without** `AlertPlay`/`AlertStop`, without the queue of 32, and **without** writing `alert_shown`. Do not confuse with production behavior.

Reference: `modus new alerter`. Voice: `media.audio` (`start-render-tts` / cache key) or `custom` `tts.request` + `mark-ready` — not “Core speaks into the overlay”.

Next chapter — [slots and panel](07-ui-slots-panel.md).
