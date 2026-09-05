# UI: slots, post, panel

**Rule.** UI surface — manifest `ui.slot` + `slots: ["web"]` and/or `["panel"]`. wasm ↔ surface channel: `ui_slot::post` / `Ready::Ui`. The plugin does not create windows: web — OBS/browser source; panel — Core layout dock.

References: [`modus-examples/widget`](../../../modus-examples/widget), `modus new panel`, overlay — `modus new alerter`.

## Manifest

```json
{
  "capabilities": ["ui.slot"],
  "slots": ["web"]
}
```

| Error | When |
| --- | --- |
| `slots требуют грант ui.slot` | slots without cap |
| `ui.slot требует слот web или panel` | cap without slot |
| `слот … не поддерживается` | not `web`/`panel` |

Optional `"user_theme": true` — streamer theme import (needs web or panel).

Deaf web without a channel: `consumer` + `"slots": ["web"]` (static; wasm does not write into DOM). Channel — role `widget` / `embedder` / `alerter` with grant.

## `ui_slot::post` / `Ready::Ui`

```text
post(payload: list<u8>) -> Result<(), String>
```

| Ceiling | Value |
| --- | --- |
| frame size | 64 KiB |
| storm | 10/s |

Page sends frames to wasm → `Ready::Ui(bytes)`. Payload format — plugin agreement (often UTF-8 JSON). A `plugin` frame only to its own `plugin_id`.

In `dev`: `--ui file` → one/several `Ready::Ui`; `post` → stderr log.

## Web / OBS

Assets: `assets/web/**`, entry `assets/web/index.html`. Posix paths, no `../`.

### CSP (guest base)

Concept, not the full Core browser policy:

| Topic | Rule |
| --- | --- |
| scripts/styles | own package assets (`'self'`) |
| images | `'self'` and `cache/{key}` from `media.cache` |
| iframe | without `media.embed` / empty `embed_hosts` — `frame-src 'none'` |
| foreign origin in iframe | role `embedder` + `media.embed` + `embed_hosts` |

Several `web` slots at once are ok. Raw fetch to an arbitrary CDN from the page is not a bypass of wasm `hosts`; for binaries use a cache-key.

## Panel native: `panel.json`

File `assets/panel.json`, ≤ 32 KiB. HTML in texts — rejected. Together with `assets/panel/index.html` — rejected (choose native **or** web panel).

```json
{
  "version": 2,
  "blocks": [
    { "id": "status", "type": "label", "text": { "key": "panel.queue", "fallback": "Queue" } },
    { "id": "queue", "type": "list" },
    {
      "id": "notes",
      "type": "table",
      "editable": true,
      "columns": [
        { "id": "title", "label": { "fallback": "Note" }, "type": "string" }
      ]
    },
    { "id": "bar", "type": "buttons", "items": [
      { "id": "skip", "label": { "fallback": "Skip" }, "icon": "forward" }
    ]}
  ]
}
```

### Version

| | v1 | v2 |
| --- | --- | --- |
| label / list / table (readonly) / buttons | yes | yes |
| editable table, `layout`, `row_drawer` | no | yes |
| `drawer` (nesting depth 1) | no | yes |
| fields `color` / `select` / `number` / `toggle` / `string` | no | yes |

### Tree ceilings (guide)

| What | Max |
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

Icons — fixed Core set (`plus`, `trash`, `play`, …). Labels — plain or `{ key, fallback }` + i18n.

Channel with native panel is the same: `post` / `Ready::Ui` (table state, button clicks — JSON per plugin agreement).

`modus new panel` / `modus new panel --mode web`. Feature is always `widget`.

## Panel web

Directory `assets/panel/` (index.html) **or** reuse of `assets/web/`. CSP same as the web slot.

Next chapter — [media, cache, audio, embed](08-media-cache-audio-embed.md).
