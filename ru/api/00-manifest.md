# Манифест

**Правило.** Файл `manifest` (без расширения) — JSON в корне crate и в корне `.mplug`. Хост читает его до wasm. Нет поля — нет права, кроме базы. `client_secret` в манифесте — всегда отказ.

Каркас пишет `modus new`. Полная проверка — `modus check` / `pack`. Эталоны: `modus new connector`, [`modus-examples/widget`](../../../modus-examples/widget), `modus new provider`.

## Обязательные поля

| Поле | Тип | Смысл |
| --- | --- | --- |
| `id` | string | reverse-DNS ≥3 сегмента, ≤128 символов (`com.publisher.name`). Смена `id` = другой плагин (KV/settings не переносятся). Короткий `twitch` — отказ: `plugin id: нужен reverse-DNS …` |
| `name` | string **или** `{ "key", "fallback" }` | имя в UI. Plain — как есть; key — i18n (см. ниже) |
| `version` | string | версия **пакета** (`0.1.0`), не ABI |
| `author` | string | подпись автора |
| `abi` | number | только **`2`**. Иначе: `ABI N не поддерживается (нужен 2)` |

Минимум consumer:

```json
{
  "id": "com.you.bus",
  "name": "bus",
  "version": "0.1.0",
  "author": "author",
  "abi": 2
}
```

## Capabilities

Массив строк. Пустой / отсутствует — только база (`wait`, settings, assets, log, …). Импорт WIT без гранта — soft-link ок; вызов без cap — `нет гранта …`.

| Capability | Зачем |
| --- | --- |
| `bus.emit` | класть канон на шину; **требует** непустой `platform_id` |
| `auth.token` | `list-accounts` / `token`; нужен при любом `auth_mode` |
| `net.http` | HTTPS через хост |
| `net.ws` | WSS через хост |
| `alert.enqueue` | талон в кассу алертов |
| `storage.kv` | приватное KV инстанса |
| `chat.act` | send/delete/timeout/ban/unban |
| `ui.slot` | канал wasm ↔ web/panel; **требует** `slots` |
| `media.cache` | pin URL/байт в кэше Core |
| `media.audio` | play/stop звука |
| `media.embed` | iframe allowlist + `embed_hosts` |
| `catalog.publish` | снимок словаря (эмоуты и т.п.) |
| `history.read` | страницы журнала (не replay `wait`) |
| `bridge.obs` | OBS invoke; список типов — `bridge_requests` |
| `rates.publish` | таблица курсов |
| `rates.convert` | convert → base currency Core |

Карта роль × грант × эталон — [ref/01-roles](../ref/01-roles.md).

## `platform_id` / `platform_logo`

| Поле | Правило |
| --- | --- |
| `platform_id` | короткое имя площадки (`twitch`), **не** `id` пакета. Обязателен при `bus.emit` и при любом `auth_mode`. Один живой плагин на значение; второй — `platform_id … уже занят` |
| `platform_logo` | путь **относительно** `assets/` (без префикса `assets/`, без `..`, без `\`). Расширения: svg/png/webp/jpg. Требует `platform_id`. Файл ≤ 128 KiB |

## `slots` / `user_theme`

| Поле | Правило |
| --- | --- |
| `slots` | `"web"` и/или `"panel"`. Дубль / неизвестный слот — отказ. Есть слоты без `ui.slot` — `slots требуют грант ui.slot`. Грант без слота — `ui.slot требует слот web или panel` |
| `user_theme` | `true` — стример может подменить тему zip поверх web/panel. Требует `ui.slot` и слот web или panel |

Ассеты: web — `assets/web/`; panel native — `assets/panel.json`; panel web — `assets/panel/` **или** те же `assets/web/`. Вместе `panel.json` и `panel/index.html` — отказ. Подробнее — [07-ui-slots-panel](07-ui-slots-panel.md).

## Хосты сети

| Поле | Правило |
| --- | --- |
| `hosts` | allowlist DNS для `net.http` / `net.ws` и URL auth. Формат: hostname или `host:port`. Пересечение с whitelist Core. Литеральный IP / private — отказ на вызове |
| `embed_hosts` | allowlist для iframe (`media.embed`). Пустой + нет cap — CSP `frame-src 'none'`. Непустой без `media.embed` — `embed_hosts требует capability media.embed`. Дубликаты — отказ |
| `bridge_requests` | типы OBS-запросов. Без `bridge.obs` — отказ. Denylist Core: `GetStreamServiceSettings`, `SetStreamServiceSettings` |

Концепт: манифест ∩ политика Core. Гость URL сам не «открывает» — хост проверяет. Сеть — [05-emit-auth-net](05-emit-auth-net.md).

## Auth (`auth_mode`)

Без `auth_mode` поля `auth_url` / `token_url` / `device_url` ставить нельзя (`нужен auth.mode`). С режимом обязательны грант `auth.token` и `platform_id`.

| Режим | Обязательно | Опционально |
| --- | --- | --- |
| `broker` | `client_id`, `auth_url`, `broker_url`; URL ∈ `hosts` | `token_url`, `userinfo_url`, `scopes` |
| `pkce` | `client_id`, `auth_url`, `token_url` | `userinfo_url`, `scopes` |
| `device` | `client_id`, `device_url`, `token_url` | `userinfo_url`, `scopes` |
| `api` | (токен вставляет стример в UI) | `userinfo_url` |
| `custom` | `token_url` и хотя бы один из `auth_url` / `device_url` | `userinfo_url`, `scopes` |

`client_secret` — запрещён. Оболочку OAuth гоняет Core; wasm видит только короткий access через `auth.token`. В `dev` — `--token` / `--token-file`, не сейф Core.

`api` без вставленного токена: `режим api: вставьте токен`. Broker в проде требует verified подпись пакета — [10-package-signing](10-package-signing.md).

## Catalog: `provides` / `depends` / `consumes`

| Поле | Правило |
| --- | --- |
| `provides` | список `{ "name", "schema" }`. Сейчас имя `emotes` → схема строго `modus.emotes.v1`. Дубль имени — отказ |
| `depends` | `{ "platform": "twitch" }` — площадка, без которой каталог бессмысленен. Пустой `platform` — отказ |
| `consumes` | имена чужих provides; сейчас только `"emotes"` |

Публикация снимка — грант `catalog.publish` ([09-bridge-history-rates-catalog](09-bridge-history-rates-catalog.md)). Эталон: `modus new provider`.

## i18n в labels

`name` (и тексты panel/settings) могут быть:

```json
"name": { "key": "plugin.title", "fallback": "Мой плагин" }
```

- `key` — плоский ключ в `assets/i18n/{locale}.json` (латиница, ≤128).
- `fallback` — если нет локали / ключа.
- При любом `label.key` в пакете обязателен **`assets/i18n/en.json`**.
- Файл локали ≤ 32 KiB; значение ≤ 512; объект ключ→строка, без вложенности.
- Локаль: `en`, `ru` или `en-US` (два нижних + опционально `-` + два верхних).

Runtime label в форме settings: `settings::set_label_i18n` / `modus_sdk::set_label_i18n` — Core подставляет строку из каталога.

## Запреты манифеста

| Ошибка | Когда |
| --- | --- |
| `client_secret запрещён в манифесте` | поле есть |
| `нет platform_id` | `bus.emit` или auth без поля |
| `auth.mode требует грант auth.token` | режим без cap |
| `нужен auth.mode` | URL auth без режима |
| `slots требуют грант ui.slot` / обратное | рассинхрон слотов и cap |
| `user_theme требует …` | theme без ui surface |
| `provides: неизвестное имя` / плохая схема | catalog |
| `bridge_requests: тип … в denylist Core` | запрещённый OBS request |

Следующая глава — [lifecycle и wait](01-lifecycle-wait.md).
