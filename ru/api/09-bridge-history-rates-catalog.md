# Bridge, history, rates, catalog

**Правило.** Эти API — отдельные capability. Не шина канона: catalog/rates — снимки у Core; history — страницы журнала; bridge — RPC через хост к OBS (allowlist типов).

Эталоны: `modus new bridge`, `modus new reader`, `modus new rates`, `modus new provider`, convert — `modus new alerter`.

## `bridge.obs`

Грант `bridge.obs` + непустой (обычно) `bridge_requests` в манифесте. Feature `bridge`.

```text
bridge::invoke(id, request_type, payload) -> Result<list<u8>, string>
```

| Аргумент | Смысл |
| --- | --- |
| `id` | id соединения/цели у Core (как заведено в UI) |
| `request_type` | тип OBS-запроса; должен быть разрешён манифестом и не в denylist |
| `payload` | JSON/байты по договору OBS |

Denylist Core (манифест тоже режет): `GetStreamServiceSettings`, `SetStreamServiceSettings`.

Сырой TCP/WebSocket к OBS в обход bridge — запрещён (WASI/`net` на private). В `dev` — заглушка/лог, не живой OBS.

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
| `alert_shown` | `event-id` из этой страницы, уже успешно shown этим `plugin_id` (после complete) |

Это **не** replay в `Ready::Bus`. `wait` историю не отдаёт. Alerter использует read для recovery после рестарта.

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
