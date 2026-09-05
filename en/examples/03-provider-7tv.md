# Provider / 7TV

A provider does not emit chat canon: it pulls a third-party catalog over HTTP/WS, puts media in cache, and publishes a slice via `catalog.publish`. 7TV — emotes for a Twitch channel.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `provider` |
| Required grants | `net.http` + `net.ws` + `media.cache` + `catalog.publish` |
| Modules | `net_http`, `net_ws`, `media_cache`, `catalog` |
| Does not | `platform_id`, `bus.emit` |
| Map | [ref/01-roles](../ref/01-roles.md) |

Reference: [`plugins/7tv`](../../../plugins/7tv).

## Manifest

```json
{
  "id": "com.modus.7tv",
  // HTTP sets + events WS + CDN pins + catalog slice publish
  "capabilities": ["net.http", "net.ws", "media.cache", "catalog.publish"],
  // allowlist: API, CDN images, realtime events
  "hosts": ["7tv.io", "cdn.7tv.app", "events.7tv.io"],
  // named slice consumers declare via "consumes"
  "provides": [{ "name": "emotes", "schema": "modus.emotes.v1" }],
  // soft link: if settings channel empty, take channel from Twitch bus
  "depends": [{ "platform": "twitch" }]
}
```

| Field | Why |
| --- | --- |
| `hosts` | API / CDN / events WS allowlist |
| `provides` | catalog slice name + schema for consumers (`consumes`) |
| `depends` | soft link: channel from Twitch bus if settings empty |

## Code

**Channel: settings or bus.** Subscribe so you can pick up `event.source.channel` from Twitch.

```rust
fn init() {
    // need Bus wakes to discover Twitch channel when settings empty
    wait::subscribe();
    // i18n status label in settings form (key → assets/i18n)
    let _ = modus_sdk::set_label_i18n("status", "status.start", None);
}

fn resolve_channel() -> String {
    // prefer explicit settings; normalize for 7TV API
    settings::get("channel").unwrap_or_default().trim().to_ascii_lowercase()
}
```

**Refresh → pin → publish.** HTTP sets → `media_cache::ensure` → JSON body → `catalog::publish("emotes", …)`.

```rust
fn refresh(channel: &str) -> Result<Vec<String>, String> {
    // global + user sets → chosen emotes (PIN_MAX caps how many we pin)
    for emote in chosen {
        // download/pin CDN image → opaque cache key for overlay <img>
        let key = media_cache::ensure(&cdn_url(&emote.id))?;
        // one catalog row: name + id + cache key (+ …)
        published.push(json!({ "name": emote.name, "id": emote.id, "key": key, … }));
    }
    // schema body: which channel, platforms, emote list
    let body = json!({ "channel": channel, "platforms": ["twitch"], "emotes": published });
    // publish named slice "emotes" — widgets with consumes=["emotes"] see it
    catalog::publish("emotes", &serde_json::to_vec(&body)?)?;
    Ok(set_ids) // set ids used to subscribe on events WS
}
```

**Events WS.** Heartbeat + subscribe on set id; set change → another `refresh`.

```rust
// connect to 7TV events (host must be in manifest hosts)
let handle = net_ws::connect(EVENTS_URL)?;
// op 1 → subscribe_body(set_id); op 0 emote_set change → refresh; Timer → {"op":2} heartbeat
```

## Assets

| Path | Purpose |
| --- | --- |
| [`assets/settings.json`](../../../plugins/7tv/assets/settings.json) | `channel` field + `status` label |
| [`assets/i18n/ru.json`](../../../plugins/7tv/assets/i18n/ru.json) | status / label strings |

Empty `channel` → status `status.need_twitch`, wait for bus or `--settings`.

## How to run

```powershell
modus new provider --id com.you.7tv --dir seventv
modus dev ../../../plugins/7tv --settings channel.json
```

`channel.json` — settings key overlay (see [api/11-cli-dev](../api/11-cli-dev.md)). For network without internet — `--http-file` / `--replay`. A live/fixture Twitch beside it helps if the channel comes from the bus.

## Typical host errors

| Situation | String |
| --- | --- |
| No `catalog.publish` | `нет гранта catalog.publish` |
| CDN/API outside `hosts` | `… вне манифеста` |
| Quota / size | `квота http`, `тело слишком большое` |
| Stop | `остановлен` → do not spin `Retry` |
| Canon emit from provider | roles do not; no `bus.emit` grant |
