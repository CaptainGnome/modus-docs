# Settings, KV, act, алерты, слоты

Если это первый плагин — роли в [карте](01-roles.md). Если нужны потолки и эталоны — эта глава.

**Правило.** Права — манифест + deny на вызове. В `modus dev` (S5): KV/settings — RAM на процесс; `alert.enqueue` / `chat.act` — лог + id в stderr, не очередь Core и не парк до второго wasm. В Core — прод-семантика ниже.

База без гранта: `settings`, `assets`, `log`, `wait`, `self_info`, `clock`, `chat_complete`.

## Settings

Схема — `assets/settings.json` (нет файла — нет формы; битая — пакет не ставится). Core рисует UI; гость: `get` / `set_label` / `set_label_i18n`.

- `get` — без схемы / чужой ключ → `None`.
- Label — только поле `type: label`; иначе отказ.
- Save в Core → `Ready::Settings`. В `dev`: `--settings` JSON-оверлей → тот же `Ready::Settings`.

Эталон: [`plugins/store`](../../../plugins/store).

## KV

Грант `storage.kv`. Чужое KV не видно. Секреты сюда не класть.

Квота: 256 KiB / 256 ключей / значение ≤ 16 KiB. Шторм: 60 set/delete в секунду. Рестарт `dev` — пусто (не sqlite).

Эталон: [`plugins/store`](../../../plugins/store).

## `chat.act`

Грант `chat.act`. Единственный путь send/delete/timeout/ban/unban. В Core хост паркует вызов и будит живой коннектор `Ready::Act`; коннектор отвечает `chat_complete`. Нет коннектора — сразу ошибка. В `dev`: id + лог сразу; `--act` будит emitter/connector.

Текст send ≤ 500. Timeout 0 — отказ. Шторм: 10/с.

Эталон: [`plugins/commander`](../../../plugins/commander); исполнитель без сети — [`plugins/fixture`](../../../plugins/fixture).

## Алерты

Грант `alert.enqueue`. Плагин ставит job; касса и показ — Core + свой `ui.slot` web после `alert-play`. В `dev`: enqueue/complete → stderr, без `AlertPlay`/`AlertStop` и без очереди 32.

Эталон: [`plugins/alerter`](../../../plugins/alerter).

## Слоты (`ui.slot`)

Манифест: `ui.slot` + `"slots": ["web"]` и/или `["panel"]`. Канал wasm ↔ поверхность: `ui_slot::post` / `Ready::Ui`. В `dev`: `--ui` → `Ready::Ui`; `post` → лог.

Эталоны: [`plugins/web-slot`](../../../plugins/web-slot), [`plugins/panel`](../../../plugins/panel).

## Cache / catalog (кратко)

- `media.cache` — pin URL/байт; эталоны коннектор / [`plugins/7tv`](../../../plugins/7tv).
- `catalog.publish` — снимок словаря (не шина); в `dev` — publish в stderr. Эталон: 7tv.

Полная карта грантов — [роли](01-roles.md). Флаги `dev` — [CLI](05-cli.md).

Следующая глава — [пакет `.mplug`](08-package.md).
