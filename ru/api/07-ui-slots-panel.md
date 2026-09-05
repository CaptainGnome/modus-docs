# UI: слоты, post, panel

**Правило.** Поверхность UI — манифест `ui.slot` + `slots: ["web"]` и/или `["panel"]`. Канал wasm ↔ поверхность: `ui_slot::post` / `Ready::Ui`. Окна плагин не создаёт: web — OBS/browser source; panel — док раскладки Core.

Эталоны: [`modus-examples/widget`](../../../modus-examples/widget), `modus new panel`, overlay — `modus new alerter`.

## Манифест

```json
{
  "capabilities": ["ui.slot"],
  "slots": ["web"]
}
```

| Ошибка | Когда |
| --- | --- |
| `slots требуют грант ui.slot` | слоты без cap |
| `ui.slot требует слот web или panel` | cap без слота |
| `слот … не поддерживается` | не `web`/`panel` |

Опционально `"user_theme": true` — импорт темы стримером (нужен web или panel).

Глухой web без канала: `consumer` + `"slots": ["web"]` (статика; wasm в DOM не пишет). Канал — роль `widget` / `embedder` / `alerter` с грантом.

## `ui_slot::post` / `Ready::Ui`

```text
post(payload: list<u8>) -> Result<(), String>
```

| Потолок | Значение |
| --- | --- |
| размер кадра | 64 KiB |
| шторм | 10/с |

Страница шлёт кадры в wasm → `Ready::Ui(bytes)`. Формат payload — договорённость плагина (часто UTF-8 JSON). Кадр `plugin` только своему `plugin_id`.

В `dev`: `--ui file` → один/несколько `Ready::Ui`; `post` → лог stderr.

## Web / OBS

Ассеты: `assets/web/**`, вход `assets/web/index.html`. Posix-пути, без `../`.

### CSP (база для гостя)

Концепт, не полная политика браузера Core:

| Тема | Правило |
| --- | --- |
| скрипты/стили | свои ассеты пакета (`'self'`) |
| картинки | `'self'` и `cache/{key}` из `media.cache` |
| iframe | без `media.embed` / пустых `embed_hosts` — `frame-src 'none'` |
| чужой origin в iframe | роль `embedder` + `media.embed` + `embed_hosts` |

Несколько `web` слотов сразу ок. Сырой fetch на произвольный CDN из страницы — не обход `hosts` wasm; для бинарников используйте cache-key.

## Panel native: `panel.json`

Файл `assets/panel.json`, ≤ 32 KiB. HTML в текстах — отказ. Вместе с `assets/panel/index.html` — отказ (выберите native **или** web panel).

```json
{
  "version": 2,
  "blocks": [
    { "id": "status", "type": "label", "text": { "key": "panel.queue", "fallback": "Очередь" } },
    { "id": "queue", "type": "list" },
    {
      "id": "notes",
      "type": "table",
      "editable": true,
      "columns": [
        { "id": "title", "label": { "fallback": "Заметка" }, "type": "string" }
      ]
    },
    { "id": "bar", "type": "buttons", "items": [
      { "id": "skip", "label": { "fallback": "Пропустить" }, "icon": "forward" }
    ]}
  ]
}
```

### Version

| | v1 | v2 |
| --- | --- | --- |
| label / list / table (readonly) / buttons | да | да |
| editable table, `layout`, `row_drawer` | нет | да |
| `drawer` (вложенность depth 1) | нет | да |
| поля `color` / `select` / `number` / `toggle` / `string` | нет | да |

### Потолки дерева (ориентир)

| Что | Макс |
| --- | --- |
| blocks | 24 |
| nest depth | 1 |
| drawer children / rows | 12 |
| row cells | 4 |
| buttons / actions | 8 |
| columns | 10 |
| table rows | 64 |
| enum options | 32 |
| label / help | 128 / 256 |

Иконки — фиксированный набор Core (`plus`, `trash`, `play`, …). Labels — plain или `{ key, fallback }` + i18n.

Канал с native panel тот же: `post` / `Ready::Ui` (состояние таблицы, клики кнопок — JSON по договору плагина).

`modus new panel` / `modus new panel --mode web`. Feature всегда `widget`.

## Panel web

Каталог `assets/panel/` (index.html) **или** переиспользование `assets/web/`. CSP как у web-слота.

Следующая глава — [media, cache, audio, embed](08-media-cache-audio-embed.md).
