# Settings, KV, act, alerts, slots

If this is your first plugin — roles in the [map](01-roles.md). If you need ceilings and references — this chapter.

**Rule.** Rights — manifest + deny on the call. In `modus dev` (S5): KV/settings — RAM per process; `alert.enqueue` / `chat.act` — log + id to stderr, not Core queue and not park to a second wasm. In Core — prod semantics below.

Base without grant: `settings`, `assets`, `log`, `wait`, `self_info`, `clock`, `chat_complete`.

## Settings

Schema — `assets/settings.json` (no file — no form; broken — package will not install). Core draws the UI; guest: `get` / `set_label` / `set_label_i18n`.

- `get` — no schema / foreign key → `None`.
- Label — only field `type: label`; else refuse.
- Save in Core → `Ready::Settings`. In `dev`: `--settings` JSON overlay → same `Ready::Settings`.

Reference: `modus new store`.

## KV

Grant `storage.kv`. Others' KV is invisible. Do not put secrets here.

Quota: 256 KiB / 256 keys / value ≤ 16 KiB. Storm: 60 set/delete per second. `dev` restart — empty (not sqlite).

Reference: `modus new store`.

## `chat.act`

Grant `chat.act`. Only path for send/delete/timeout/ban/unban. In Core the host parks the call and wakes the live connector with `Ready::Act`; connector answers `chat_complete`. No connector — immediate error. In `dev`: id + log immediately; `--act` wakes emitter/connector.

Send text ≤ 500. Timeout 0 — refuse. Storm: 10/s.

Reference: `modus new commander`; performer without network — [`modus-examples/emitter`](../../../modus-examples/emitter).

## Alerts

Grant `alert.enqueue`. Plugin places a job; queue and display — Core + own `ui.slot` web after `alert-play`. Successful `complete` → row in `alert_shown` (canon untouched); recovery reads `history.Page.alert_shown`. In `dev`: enqueue/complete → stderr, no `AlertPlay`/`AlertStop`, no queue of 32, no `alert_shown`.

Reference: `modus new alerter`. Full contract — [api/06](../api/06-kv-act-alerts.md#shown-alerts-alert_shown).

## Slots (`ui.slot`)

Manifest: `ui.slot` + `"slots": ["web"]` and/or `["panel"]`. Wasm ↔ surface channel: `ui_slot::post` / `Ready::Ui`. In `dev`: `--ui` → `Ready::Ui`; `post` → log.

References: [`modus-examples/widget`](../../../modus-examples/widget), `modus new panel`.

## Cache / catalog (brief)

- `media.cache` — pin URL/bytes; references connector / `modus new provider`.
- `catalog.publish` — dictionary snapshot (not bus); in `dev` — publish to stderr. Reference: 7tv.

Full grant map — [roles](01-roles.md). `dev` flags — [CLI](05-cli.md).

Next chapter — [`.mplug` package](08-package.md).
