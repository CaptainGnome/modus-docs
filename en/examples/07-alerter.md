# Alerter

The role places a ticket in Core's queue (`alert.enqueue`); display is its own: after `Ready::AlertPlay` it posts JSON to the web overlay. Queue, priorities, and skip belong to the host; the guest does not run its own queue. Reference — [`plugins/alerter`](../../../plugins/alerter) (~1900 lines of UI/tiers; below only the flow nodes).

## Feature and grants

| | |
| --- | --- |
| SDK feature | `alerter` |
| Required | `alert.enqueue`, `ui.slot`, `history.read` |
| Slots | `"slots": ["web", "panel"]` |
| Extra in the reference | `storage.kv` (tiers/style), `media.audio` (SFX), `rates.convert` (donation → base) |

Map — [ref/01-roles](../ref/01-roles.md). Queue — [api/06-kv-act-alerts](../api/06-kv-act-alerts.md).

## Manifest

```json
{
  "id": "com.modus.alerter",
  "abi": 2,
  "capabilities": [
    "alert.enqueue",  // enqueue ticket + complete after show
    "ui.slot",        // post show/hide/style to overlay + panel
    "history.read",   // recover high-prio after restart / Resume
    "storage.kv",     // persist tiers and style across sessions
    "media.audio",    // play SFX by cache key on AlertPlay
    "rates.convert"   // donation amount → Core base currency for tiers
  ],
  // OBS overlay (web) + native settings/tiers panel
  "slots": ["web", "panel"]
}
```

| Field | Why |
| --- | --- |
| `alert.enqueue` | `enqueue` / `complete` |
| `ui.slot` + `slots` | OBS overlay (`web`) and native panel |
| `history.read` | recovery after restart / `Resume` |
| `storage.kv` | tiers and style across sessions |
| `media.audio` | SFX by cache key on play |
| `rates.convert` | match donation tier in Core's base currency |

## Code

**Loop.** Subscribe in `init`; in `run` — bus → enqueue, play/stop → overlay, UI panel, recovery on `Resume`.

```rust
fn init() {
    wait::subscribe();   // Bus + Alert* + Ui + Resume
    load_style();        // KV → colors/animations
    load_all_tiers();    // KV → donation/follow/… thresholds
    post_panel();        // sync native panel blocks
    post_style();        // push CSS vars to web overlay
    hide();              // ensure overlay starts blank
    recover();           // re-enqueue missed high-prio from history
}

fn run() {
    loop {
        match wait::wait() {
            Ready::Stop => return,
            // interesting canon → build Job and enqueue
            Ready::Bus(event) => enqueue_bus(&event),
            // Core says "show this ticket now"
            Ready::AlertPlay(cmd) => on_play(&cmd),
            // Core says "hide / skip"
            Ready::AlertStop(cmd) => on_stop(&cmd),
            // panel clicks: edit tiers, skip, style
            Ready::Ui(payload) => on_ui(&payload),
            // after pause — clear overlay and recover history again
            Ready::Resume => { hide(); recover(); }
            // other Ready variants ignored
        }
    }
}
```

**Enqueue.** On an interesting `Bus` (and not `skip_alert`) build a `Job`, cache the card by `event_id`, send the ticket to Core. Donation is converted to base before tier match.

```rust
fn enqueue_bus(event: &Event) {
    // host flag: connectors can mark events that must not alert
    if event.flags.skip_alert { return; }
    // …title/body/tier match; for donation — rates::convert_to_base first
    // stash Card locally so AlertPlay can show rich UI without re-fetch
    CARDS.with(|map| { /* Card { title, body, image_key, sfx_key } */ });
    if let Err(err) = alert_enqueue::enqueue(&Job {
        event_id: event.id.clone(), // dedupe key for Core queue
        priority,                   // from matched tier
        duration_ms,                // how long overlay stays up
        title,
        body,
    }) {
        // roll back Card + log — ticket never entered Core queue
    }
}
```

**Play / stop.** Core wakes play → SFX + `ui_slot::post` with `op: show`. Stop / hide → `complete`.

```rust
fn on_play(cmd: &AlertCommand) {
    // Card from CARDS[event_id] or fallback text-only
    if let Some(key) = sfx_key.as_ref() {
        // play pinned audio via host device (not guest decoder)
        let _ = media_audio::play(&Spec::Url(key.clone()));
    }
    // overlay.js switches on op:"show"
    let payload = format!(
        "{{\"op\":\"show\",\"jobId\":\"{}\",\"eventId\":\"{}\",\"durationMs\":{},…}}",
        /* job + event ids, duration, title/body/keys … */
    );
    let _ = ui_slot::post(payload.as_bytes());
}

fn on_stop(cmd: &AlertCommand) {
    hide(); // post {"op":"hide"} so overlay clears
    // drop Card — free memory for next jobs
    // ack Core so queue can advance
    let _ = alert_enqueue::complete(&cmd.job_id, Ok(()));
}
```

**Recovery.** Not a replay in `wait`: `history_read::read`, skip already `alert_shown`, re-enqueue high priorities.

```rust
fn recover() {
    // page of recent journal — NOT injected as Ready::Bus
    let Ok(page) = history_read::read(None, 50) else { return; };
    for event in &page.events {
        // already played while we were down — skip
        if page.alert_shown.iter().any(|id| id == &event.id) { continue; }
        // only high-prio tiers on recovery (avoid flood)
        if !is_high_prio(&event.payload) { continue; }
        enqueue_bus(event);
    }
}
```

In `modus dev`, enqueue/complete go to stderr **without** `AlertPlay`/`AlertStop` — the overlay does not run in CLI the way it does in Core.

## Assets

| Path | Purpose |
| --- | --- |
| `assets/web/` | `index.html`, `overlay.js`, `overlay.css` — WS from host, `op: show/hide/style` |
| `assets/panel.json` | native panel: tiers, colors, animations |
| `assets/i18n/{en,ru}.json` | panel labels |

The web page does not fetch the network itself: `plugin` and `cache/{key}` frames per slot CSP.

## Run

From the repo root:

```powershell
modus dev plugins/alerter
```

Full crate: [`../../../plugins/alerter`](../../../plugins/alerter). With an event emitter — fixture/twitch nearby; rates for donation FX — [13-rates-fx](13-rates-fx.md).

## Typical host errors

| String / situation | Meaning |
| --- | --- |
| `нет гранта alert.enqueue` | call without capability |
| `slots требуют грант ui.slot` / `ui.slot требует слот…` | slot manifest |
| `history.read` refused | no grant → recovery silently empty |
| `нет гранта rates.convert` / no rate | donation without convert; tier may not match |
| no play in `dev` | expected: Core queue is not emulated |

See [ref/04-errors](../ref/04-errors.md), [api/01-lifecycle-wait](../api/01-lifecycle-wait.md).
