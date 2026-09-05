# Panel

Native panel in the Core layout: same `widget` feature and `ui.slot` grant, `panel` slot. The plugin does not create a window — only `assets/panel.json` + `ui_slot::post` of state and parsing `Ready::Ui`.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `widget` (`modus new panel`) |
| Required grants | `ui.slot` + `"slots": ["panel"]` |
| Modules | `ui_slot` |
| Reference mode | native (`panel.json`), not web |
| Map | [ref/01-roles](../ref/01-roles.md) |

Reference: [`plugins/panel`](../../../plugins/panel). Web panel: `modus new panel --mode web`.

## Manifest

```json
{
  "id": "com.modus.panel",
  "name": "Panel",
  "version": "0.1.0",
  "author": "modus",
  "abi": 2,
  // post/Ui channel for native panel blocks
  "capabilities": ["ui.slot"],
  // native Core side panel (assets/panel.json), not web overlay
  "slots": ["panel"]
}
```

## Code

**State → post.** Name queue from the bus + table notes — one JSON for native UI.

```rust
fn post_state() {
    // shape mirrors panel.json block ids: status / queue / notes
    // status.text, queue.items[], notes.rows[{title,done}]
    let body = format!(
        "{{\"status\":{{\"text\":\"{} в очереди\"}},\"queue\":{{\"items\":[{}]}},\
         \"notes\":{{\"rows\":[{}]}}}}",
        items.len(), // how many names waiting
        list,        // JSON array of queue item strings
        rows         // JSON array of note rows
    );
    // host patches native UI from this blob — ignore post errors in demo
    let _ = ui_slot::post(body.as_bytes());
}
```

**Bus → queue.** Message/follow add `display_name` (cap 32).

```rust
Ready::Bus(event) => {
    // only chat Message and Follow carry a display name we queue
    let name = match &event.payload {
        Payload::Message(msg) => msg.display_name.clone(),
        Payload::Follow(follow) => follow.display_name.clone(),
        _ => continue, // donation/reward/… — skip for this panel
    };
    // push name (cap 32) then post_state() so list refreshes
}
```

**Ui: buttons and table ops.** `skip`/`clear` by `id`; `notes` block — `op` add/remove/set/action.

```rust
fn on_ui(payload: &[u8]) {
    // "op"+"block":"notes" → edit NOTES table in place
    // else button id "skip"|"clear" → mutate QUEUE
    // always re-post so native UI matches wasm state
    post_state();
}
```

## Assets

| Path | Purpose |
| --- | --- |
| [`assets/panel.json`](../../../plugins/panel/assets/panel.json) | label, list, editable table, buttons |
| [`assets/i18n/ru.json`](../../../plugins/panel/assets/i18n/ru.json) | block labels |

Schema fragment:

```json
{
  // panel schema version Core understands
  "version": 2,
  "blocks": [
    // static/i18n label — wasm overwrites .text via post
    { "id": "status", "type": "label", "text": { "key": "panel.queue", "fallback": "Очередь" } },
    // list of queue names from bus
    { "id": "queue", "type": "list" },
    // editable notes table — Ui ops come back as Ready::Ui
    { "id": "notes", "type": "table", "editable": true, "max_rows": 16 },
    // action bar — click ids "skip" / "clear" land in on_ui
    { "id": "bar", "type": "buttons", "items": [
      { "id": "skip", "label": { "key": "panel.skip", "fallback": "Пропустить" } },
      { "id": "clear", "label": { "key": "panel.clear", "fallback": "Очистить" } }
    ]}
  ]
}
```

## How to run

```powershell
modus new panel --id com.you.panel --dir panel
modus new panel --id com.you.panelweb --dir panelweb --mode web
modus dev ../../../plugins/panel --ui skip.json
```

`--ui` with `{"id":"skip"}` or table-op JSON. Visually the panel shows in Core, not bare CLI.

## Typical host errors

| Situation | String |
| --- | --- |
| slot/grant mismatch | `slots требуют грант ui.slot` / `ui.slot требует слот web или panel` |
| no `panel.json` for native | `check`/`pack` refuse (assets) |
| post without grant | `нет гранта ui.slot` |
