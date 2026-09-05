# Bridge / OBS

The role does not open a socket to OBS itself: RPC goes through Core (`bridge.obs`) with an allowlist of types from the manifest. On follow (or `custom` `obs.set-scene`) the reference calls `SetCurrentProgramScene`.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `bridge` |
| Required | `bridge.obs` + non-empty `bridge_requests` |
| Base | `settings` (host/port/password UI, follow scene) |

Map — [ref/01-roles](../ref/01-roles.md). API — [api/09-bridge-history-rates-catalog](../api/09-bridge-history-rates-catalog.md).

## Manifest

```json
{
  "id": "com.modus.obs-bridge",
  "name": "OBS Bridge",
  "version": "0.1.0",
  "abi": 2,
  // invoke OBS RPC via Core — never raw TCP from guest
  "capabilities": ["bridge.obs"],
  // whitelist of OBS request types this plugin may call
  "bridge_requests": ["SetCurrentProgramScene"]
  // Core still denylists sensitive types even if listed here
}
```

| Field | Why |
| --- | --- |
| `bridge.obs` | `bridge::invoke` |
| `bridge_requests` | OBS type whitelist; anything else — refuse |
| Core denylist | incl. `Get/SetStreamServiceSettings` — even from the manifest |

## Code

**Init.** Subscribe and status label.

```rust
fn init() {
    wait::subscribe(); // need Bus for follow / custom scene
    refresh_status("ожидание событий"); // settings label until first invoke
}
```

**Bus → invoke.** Follow → scene name from settings; `custom` kind `obs.set-scene` → `scene` field in `fields`. Payload — JSON for OBS.

```rust
Ready::Bus(event) => {
    let scene = match &event.payload {
        // follow → scene name from settings "follow_scene"
        Payload::Follow(_) => follow_scene(),
        // custom canon from another plugin: kind + fields.scene
        Payload::Custom(c) if c.kind == "obs.set-scene" => scene_from_fields(&c.fields),
        _ => None, // ignore chat/donation/…
    };
    let Some(scene) = scene else { continue; };
    // OBS WebSocket v5 body for SetCurrentProgramScene
    let payload = format!("{{\"sceneName\":\"{}\"}}", escape_json(&scene));
    // "obs" = Core target id; type must be in bridge_requests
    match bridge::invoke("obs", "SetCurrentProgramScene", payload.as_bytes()) {
        Ok(_) => refresh_status(&format!("сцена: {scene}")),
        Err(err) => { log::log(Level::Warn, &err); refresh_status(&err); }
    }
}
```

**Settings.** `follow_scene` — OBS scene name string; empty → do not switch on follow. `host` / `port` / `password` are read by Core for the connection; the guest does not put them on a socket.

```rust
fn follow_scene() -> Option<String> {
    let scene = settings::get("follow_scene").unwrap_or_default();
    let scene = scene.trim();
    // empty setting → never auto-switch on Follow
    if scene.is_empty() { None } else { Some(scene.to_string()) }
}
```

The first `invoke` argument (`"obs"`) is the target id at Core, as set in the host UI.

## Assets

| Path | Purpose |
| --- | --- |
| `assets/settings.json` | host, port, password (secret), `follow_scene`, label `status` |

Raw WASI/`net` to a private IP toward OBS is forbidden; bridge only.

## Run

```powershell
modus new <role>  # scaffold, then modus dev <dir>
```

In `dev`, bridge is a stub/log, not a live OBS WebSocket. Full crate: [`modus new bridge`](modus new bridge).

## Typical host errors

| String / situation | Meaning |
| --- | --- |
| `нет гранта bridge.obs` | call without capability |
| type not in `bridge_requests` | manifest whitelist |
| Core denylist | sensitive OBS request |
| no connection / bad settings | error from Core → status |
| own TCP to OBS | `запрещённый импорт` / network |

See [ref/04-errors](../ref/04-errors.md), [ref/06-net-auth](../ref/06-net-auth.md).
