# Bridge, history, rates, catalog

**Правило.** Эти API — отдельные capability. Не шина канона: catalog/rates — снимки у Core; history — страницы журнала; bridge — loopback WS к локальному софту (`net.bridge`).

Эталоны: `modus new bridge`, `modus new reader`, `modus new rates`, `modus new provider`, convert — `modus new alerter`.

## `net.bridge`

Грант `net.bridge`. Feature `bridge`. Тот же ABI, что `net.ws`, но **только loopback**.

```text
net_bridge::connect(url) -> Result<u32, string>
net_bridge::send_text(handle, message) -> Result<(), string>
net_bridge::close(handle) -> Result<(), string>
```

| | `net.ws` | `net.bridge` |
| --- | --- | --- |
| URL | `wss://` + hosts ∩ whitelist | только `ws://` на `127.0.0.1` / `::1` / localhost |
| Кадры | opaque text → `Ready::WsText` / `WsClosed` | то же |
| Протокол | в wasm | в wasm (OBS/VTS — не в Core) |

Сырой TCP и `net.ws` на loopback — запрещены. Endpoint (host/port/пароль) — settings плагина. В `dev` без живого софта — отказ connect / лог.

## `history.read`

Грант `history.read`. Feature `reader` / также alerter.

```text
read(cursor?, limit) -> Result<Page, string>
```

`Page`:

| Поле | Смысл |
| --- | --- |
| `events` | список тех же `wait::Event` (канон + flags) |
| `next` | курсор следующей страницы или пусто |
| `alert_shown` | `event-id` с этой страницы, уже успешно shown **этим** `plugin_id`. Пишется в таблицу Core `alert_shown` только после `alert_enqueue::complete(..., Ok(()))`. Payload событий не меняется (не mangling канона). Retention ~1 ч / cap ~2000. В `dev` таблица не ведётся |

Это **не** replay в `Ready::Bus`. `wait` историю не отдаёт. Alerter использует read + `alert_shown` для recovery после рестарта / `Resume` — подробнее [алерты](06-kv-act-alerts.md#показанные-алерты-alert_shown).

## `rates.publish` / `rates.convert`

Два гранта:

| Грант | Модуль | Роль |
| --- | --- | --- |
| `rates.publish` | `rates_publish` | feature `rates` — таблица курсов |
| `rates.convert` | `rates` | feature `alerter` (+ rates) — чтение |

```text
rates_publish::publish(list<{from, to, value}>) -> Result<(), string>

rates::base() -> string
rates::convert_to_base(amount, from) -> Result<f64, string>
```

| Вызов | Правило |
| --- | --- |
| `publish` | пары валют → Core FX table |
| `base` | ISO-4217 база из настроек Core |
| `convert_to_base` | `amount` в `from` → base, floor до minor; нет курса → `Err` |

Курс в `opaque` канона не кладут. Эталон publish — `modus new rates`.

## `catalog.publish`

Грант `catalog.publish`. Feature `provider`. Манифест `provides` / `depends` / `consumes` — [00-manifest](00-manifest.md).

```text
publish(name, payload: list<u8>) -> Result<(), string>
unpublish(name) -> Result<(), string>
```

Сейчас имя `emotes`, схема `modus.emotes.v1` (байты — JSON снимка по схеме). Это **не** `bus.emit`: словарь у Core для UI/других плагинов с `consumes`.

| Потолок | Значение |
| --- | --- |
| размер снимка | 256 KiB |
| эмоутов | 2048 |
| publish | 10/с |

В `dev`: publish → stderr. Эталон — `modus new provider` (+ `media.cache` для картинок).

Следующая глава — [пакет и подпись](10-package-signing.md).
