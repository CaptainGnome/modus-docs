# Panel

Native-панель в раскладке Core: тот же feature `widget` и грант `ui.slot`, слот `panel`. Плагин окна не создаёт — только `assets/panel.json` + `ui_slot::post` состояния и разбор `Ready::Ui`.

## Feature и гранты

| | |
| --- | --- |
| Feature SDK | `widget` (`modus new panel`) |
| Обязательные гранты | `ui.slot` + `"slots": ["panel"]` |
| Модули | `ui_slot` |
| Режим эталона | native (`panel.json`), не web |
| Карта | [ref/01-roles](../ref/01-roles.md) |

Эталон: [`plugins/panel`](../../../plugins/panel). Web-panel: `modus new panel --mode web`.

## Манифест

```json
{
  "id": "com.modus.panel",
  "name": "Panel",
  "version": "0.1.0",
  "author": "modus",
  "abi": 2,
  /* канал post/Ui для native блоков из panel.json */
  "capabilities": ["ui.slot"],
  /* слот panel (не web): схема в assets/panel.json */
  "slots": ["panel"]
}
```

## Код

**Состояние → post.** Очередь имён с шины + заметки таблицы — один JSON для native UI.

```rust
fn post_state() {
    // ключи JSON = id блоков из panel.json:
    // status.text, queue.items[], notes.rows[{title,done}]
    let body = format!(
        "{{\"status\":{{\"text\":\"{} в очереди\"}},\"queue\":{{\"items\":[{}]}},\
         \"notes\":{{\"rows\":[{}]}}}}",
        items.len(), list, rows
    );
    // один post обновляет все блоки native UI сразу
    let _ = ui_slot::post(body.as_bytes());
}
```

**Шина → очередь.** Message/follow добавляют `display_name` (cap 32).

```rust
Ready::Bus(event) => {
    // только message/follow дают имя в очередь; остальное — skip
    let name = match &event.payload {
        Payload::Message(msg) => msg.display_name.clone(),
        Payload::Follow(follow) => follow.display_name.clone(),
        _ => continue,
    };
    // push в QUEUE (cap 32) + сразу post_state() в панель
}
```

**Ui: кнопки и table ops.** `skip`/`clear` по `id`; блок `notes` — `op` add/remove/set/action.

```rust
fn on_ui(payload: &[u8]) {
    // JSON от native UI:
    // "op"+"block":"notes" → правка NOTES (add/remove/set/action)
    // иначе id "skip"|"clear" → QUEUE
    // после мутации — всегда свежий post_state()
    post_state();
}
```

## Assets

| Путь | Назначение |
| --- | --- |
| [`assets/panel.json`](../../../plugins/panel/assets/panel.json) | label, list, editable table, buttons |
| [`assets/i18n/ru.json`](../../../plugins/panel/assets/i18n/ru.json) | подписи блоков |

Фрагмент схемы:

```json
{
  /* версия схемы native panel */
  "version": 2,
  "blocks": [
    /* label — текст статуса; text.key → i18n */
    { "id": "status", "type": "label", "text": { "key": "panel.queue", "fallback": "Очередь" } },
    /* list — очередь имён; items приходят post_state */
    { "id": "queue", "type": "list" },
    /* editable table — клики/ops → Ready::Ui с block notes */
    { "id": "notes", "type": "table", "editable": true, "max_rows": 16 },
    /* buttons: id уходит в Ui payload как {"id":"skip"} */
    { "id": "bar", "type": "buttons", "items": [
      { "id": "skip", "label": { "key": "panel.skip", "fallback": "Пропустить" } },
      { "id": "clear", "label": { "key": "panel.clear", "fallback": "Очистить" } }
    ]}
  ]
}
```

## Как запустить

```powershell
modus new panel --id com.you.panel --dir panel
modus new panel --id com.you.panelweb --dir panelweb --mode web
modus dev ../../../plugins/panel --ui skip.json
```

`--ui` с `{"id":"skip"}` или table-op JSON. Визуально панель видна в Core, не в голом CLI.

## Типичные ошибки хоста

| Ситуация | Строка |
| --- | --- |
| слот/грант несогласованы | `slots требуют грант ui.slot` / `ui.slot требует слот web или panel` |
| нет `panel.json` при native | отказ `check`/`pack` (ассеты) |
| post без гранта | `нет гранта ui.slot` |
