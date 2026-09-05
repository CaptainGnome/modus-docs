# Карта ролей

Если это первый плагин — роли `new` в [туториале](../start/02-roles.md). Если нужен feature × грант × эталон — эта глава. Подробный разбор кода эталонов — [examples/](../examples/README.md).

**Правило.** Гость всегда на world **`plugin`** (полный guest API). Права — только манифест + апрув + deny на вызове. Soft-link: известный modus-импорт без гранта — `pack`/load ок; вызов без cap — `Err`. `wasi:*` / чужое — всегда отказ (`запрещённый импорт …` / `лишний импорт …`).

SDK: **одна** Cargo feature = пресет кода (helpers / re-export), не другой WIT-world. Хост — world `runtime` (тот же суперсет); гость его не выбирает.

Имена ниже — модули SDK (`net_ws`), не пакеты WIT. Соответствие capability → WIT — приложение справочника.

## База (грант не нужен)

Есть у любого пакета: `self_info`, `log`, `wait`, `types`, `clock`, `settings`, `assets`. Слушать шину после `subscribe` — база, не `bus.emit`.

`chat_complete` — без гранта (часть полного `plugin`).

## По гранту

| Грант | Модуль SDK (типичный re-export feature) | Примечание |
| --- | --- | --- |
| `bus.emit` | `bus_emit` (`emitter` / `connector`) | |
| `auth.token` | `auth_token` (`connector`) | |
| `net.http` | `net_http` | |
| `net.ws` | `net_ws` | |
| `alert.enqueue` | `alert_enqueue` (`alerter`) | |
| `storage.kv` | `storage_kv` (`store`) | |
| `chat.act` | `chat_act` (`commander`) | |
| `ui.slot` | `ui_slot` + слот `web` и/или `panel` | |
| `media.cache` | `media_cache` | |
| `media.audio` | `media_audio` (`player`) | |
| `bridge.obs` | `bridge` (`bridge`) | |
| `media.embed` | `media_embed` (`embedder`) | |
| `catalog.publish` | `catalog` (`provider`) | |
| `history.read` | `history_read` | |
| `rates.publish` | `rates_publish` (`rates`) | |
| `rates.convert` | `rates` (`alerter`) | convert → base; таблица курсов — Core / `rates.publish` |

`bus.emit` в манифесте требует непустой `platform_id`. Канон без поля — `нет platform_id`. Один живой плагин на `platform_id`; второй — `platform_id … уже занят`. `platform_id` — короткое имя площадки, не `id` пакета.

## Роли

| Роль | Feature `new` | Обязательные гранты | Типичные модули сверх базы | Эталон | Не делает |
| --- | --- | --- | --- | --- | --- |
| `consumer` | `consumer` | нет | — | [`plugins/consumer`](../../../plugins/consumer), SDK | emit, сеть, `chat.act` |
| `emitter` | `emitter` | `bus.emit` | `bus_emit`, `chat_complete` | [`plugins/fixture`](../../../plugins/fixture), SDK | логин и сокет площадки |
| `connector` | `connector` | обычно `auth.token` + `net.http` + `net.ws` + `bus.emit` + `media.cache` | `auth_token`, `net_http`, `net_ws`, `bus_emit`, `chat_complete`, `media_cache` | [`plugins/twitch`](../../../plugins/twitch), SDK | рисовать UI, KV, очередь алертов |
| `provider` | `provider` | `net.http` + `net.ws` + `media.cache` + `catalog.publish` | `net_http`, `net_ws`, `media_cache`, `catalog` | [`plugins/7tv`](../../../plugins/7tv), SDK | `platform_id`, канон, `bus.emit` |
| `widget` | `widget` | `ui.slot` + `"slots": ["web"]` и/или `["panel"]` | `ui_slot` | [`plugins/web-slot`](../../../plugins/web-slot), [`plugins/panel`](../../../plugins/panel), SDK | сеть, emit |
| `commander` | `commander` | `chat.act` | `chat_act` | [`plugins/commander`](../../../plugins/commander), SDK | emit канона, сеть |
| `alerter` | `alerter` | `alert.enqueue`, `ui.slot`, `history.read` (+ `rates.convert` для donation FX) | enqueue + web overlay + `rates` | [`plugins/alerter`](../../../plugins/alerter), SDK | касса Core; recovery через history |
| `store` | `store` | `storage.kv` | `storage_kv` + `settings` (база) | [`plugins/store`](../../../plugins/store), SDK | чужое KV, секреты |
| `reader` | `reader` | `history.read` | `history_read` | [`plugins/reader`](../../../plugins/reader), SDK | emit, сеть, replay в `wait` |
| `player` | `player` | `media.audio` + `media.cache` | `media_audio`, `media_cache` | [`plugins/player`](../../../plugins/player), SDK | открывать устройство, TTS в обход Core |
| `bridge` | `bridge` | `bridge.obs` + `bridge_requests` | `bridge` | [`plugins/obs-bridge`](../../../plugins/obs-bridge), SDK | сырой сокет в обход allowlist |
| `embedder` | `embedder` | `ui.slot` + `media.embed` + `embed_hosts` + `"slots": ["web"]` и/или `["panel"]` | `ui_slot`, `media_embed` | [`plugins/embedder`](../../../plugins/embedder), SDK | прокси MP4, `play` на хосте, youtube-dl |
| `rates` | `rates` | `net.http` + `rates.publish` | `net_http`, `rates_publish` | [`plugins/fx`](../../../plugins/fx), SDK | emit, UI, KV; курс в `opaque` |
| host | — | — | world `runtime` | нет гостя | гость этот world не ставит |

`modus new` пишет все роли из таблицы (включая `panel` → feature `widget`). Новый пакет: одна feature SDK. Сырой bindgen без SDK допустим, но не эталон.

Алертер ставит талон в кассу Core; показ — свой `web` после `alert-play`. Голос — `media.audio` (player) или `custom` `tts.request` → исполнитель с `media.audio`. Эталонный alerter без emit/audio — оверлей title/body.

Командир: `chat.act` → хост будит коннектор `Ready::Act` → `chat_complete`. Нет живого коннектора — сразу ошибка. Модерацию на шину эмитит коннектор площадки из протокола, не командир из `complete`.

## Слоты (`ui.slot`)

Манифест: `"capabilities": ["ui.slot"]` и `"slots": ["web"]` и/или `["panel"]`.

- нет гранта при непустых `slots` — `slots требуют грант ui.slot`;
- грант без слота — `ui.slot требует слот web или panel`;
- иной слот — `слот … не поддерживается`.

**Web / OBS.** Глухой слот — `consumer` + `"slots": ["web"]` (статика, wasm в DOM не пишет). Канал wasm ↔ страница — грант `ui.slot` + `ui_slot::post` (роль `widget`). Эталон: [`plugins/web-slot`](../../../plugins/web-slot). Ассеты `assets/web/`. Несколько `web` сразу ок. Картинки — `'self'` / `cache/{key}`. Кадр `plugin` только своему `plugin_id`. Чужой origin в iframe — роль `embedder` + грант `media.embed` + `embed_hosts`; без `embed_hosts` CSP `frame-src 'none'`; вызов без гранта — отказ.

**Panel.** Док в раскладке Core, плагин окна не создаёт. Режим один: native (`assets/panel.json`) или web (`assets/panel/` либо те же `assets/web/`). Эталон native: [`plugins/panel`](../../../plugins/panel). `modus new panel` / `modus new panel --mode web`.

## Следствие для `pack`

Полный import-set + узкий манифест — ок. Неизвестный / WASI — отказ. Грант шире feature — ок; вызов без гранта режет Core/`dev`, не pack.
