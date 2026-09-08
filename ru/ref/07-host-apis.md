# Settings, KV, act, алерты, слоты

Если это первый плагин — роли в [карте](01-roles.md). Если нужны потолки и эталоны — эта глава.

**Правило.** Права — манифест + deny на вызове. В `modus dev` (S5): KV/settings — RAM на процесс; `alert.enqueue` / `chat.act` — лог + id в stderr, не очередь Core и не парк до второго wasm. В Core — прод-семантика ниже.

База без гранта: `settings`, `assets`, `log`, `wait`, `self_info`, `clock`, `random`, `chat_complete`.

## Settings

Схема — `assets/settings.json` (нет файла — нет формы; битая — пакет не ставится). Core рисует UI; гость: `get` / `set_label` / `set_label_i18n`.

- `get` — без схемы / чужой ключ → `None`.
- Label — только поле `type: label`; иначе отказ.
- Save в Core → `Ready::Settings`. В `dev`: `--settings` JSON-оверлей → тот же `Ready::Settings`.

Эталон: `modus new store`.

## KV

Грант `storage.kv`. Чужое KV не видно. Секреты сюда не класть.

Квота: 256 KiB / 256 ключей / значение ≤ 16 KiB. Шторм: 60 set/delete в секунду. Рестарт `dev` — пусто (не sqlite).

Эталон: `modus new store`.

## `chat.act`

Грант `chat.act`. Единственный путь send/delete/timeout/ban/unban. В Core хост паркует вызов и будит живой коннектор `Ready::Act`; коннектор отвечает `chat_complete`. Нет коннектора — сразу ошибка. В `dev`: id + лог сразу; `--act` будит emitter/connector.

Текст send ≤ 500. Timeout 0 — отказ. Шторм: 10/с.

Эталон: `modus new commander`; исполнитель без сети — [`modus-examples/emitter`](../../../modus-examples/emitter).

## Алерты

Грант `alert.enqueue`. Плагин ставит job; касса и показ — Core + свой `ui.slot` web после `alert-play`. Job может встать с `pending-audio` (unready): касса его skip’ает до `mark-ready` или TTL (default 15s → ready без голоса). Ready сзади может сыграть раньше (не HOL). Exclusive unready не solo’ит чужие полосы до play. `replay` + `pending-audio` — отказ. Успешный `complete` → строка в `alert_shown` (не правка канона); recovery читает `history.Page.alert_shown`. В `dev`: enqueue / mark-ready / complete → stderr, без `AlertPlay`/`AlertStop`, без очереди 32 и без `alert_shown`.

Эталон: `modus new alerter`. Полный контракт — [api/06](../api/06-kv-act-alerts.md#показанные-алерты-alert_shown).

## `media.audio` / TTS

Грант `media.audio` (+ обычно `media.cache`). Core играет звук и хостовый TTS (Windows **SpVoice**); устройства гость не открывает.

- `play` / `stop` / `duration-ms`: asset, URL/cache-key, `tts` / `tts-ex`.
- Settings Core: `tts.voice`, `tts.output` = `speakers` \| `overlay` \| `both` (Speak / WAV в cache / оба).
- Prefetch: sync `render-tts` или async `start-render-tts` → `Ready::tts-rendered`; для алертов — `pending-audio` + `mark-ready` ([api/08](../api/08-media-cache-audio-embed.md), [api/06](../api/06-kv-act-alerts.md)).
- `list-voices` — тот же грант; пусто на non-Windows / null. В `dev` — stub.

Эталон: `modus new player`; голос в алертах — `modus new alerter`.

## Слоты (`ui.slot`)

Манифест: `ui.slot` + `"slots": ["web"]` и/или `["panel"]`. Канал wasm ↔ поверхность: `ui_slot::post` / `Ready::Ui`. В `dev`: `--ui` → `Ready::Ui`; `post` → лог.

Эталоны: [`modus-examples/widget`](../../../modus-examples/widget), `modus new panel`.

## Cache / catalog / audio (кратко)

- `media.cache` — pin URL/байт; эталоны коннектор / `modus new provider`.
- `media.audio` — play/TTS (SpVoice); см. выше и [api/08](../api/08-media-cache-audio-embed.md).
- `catalog.publish` — снимок словаря (не шина); в `dev` — publish в stderr. Эталон: 7tv.

Полная карта грантов — [роли](01-roles.md). Флаги `dev` — [CLI](05-cli.md).

Следующая глава — [пакет `.mplug`](08-package.md).
