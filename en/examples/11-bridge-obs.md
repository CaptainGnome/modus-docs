# Bridge / OBS

Grant `net.bridge` — loopback WS. OBS WebSocket v5 (Hello → Identify → Request) lives in wasm, not Core. On follow / `custom` `obs.set-scene` the reference sends `SetCurrentProgramScene`.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `bridge` |
| Required | `net.bridge` |
| Base | `settings` (host/port/password, `follow_scene`) |

Map — [ref/01-roles](../ref/01-roles.md). API — [api/09-bridge-history-rates-catalog](../api/09-bridge-history-rates-catalog.md).

## Manifest

```json
{
  "id": "com.modus.obs-bridge",
  "name": "OBS Bridge",
  "version": "0.1.0",
  "abi": 2,
  "capabilities": ["net.bridge"]
}
```

No `hosts` / `bridge_requests`: endpoint is settings; `ws://` on loopback only.

## Code

**Connect.** URL from settings → `net_bridge::connect`.

```rust
let url = format!("ws://{host}:{port}");
let handle = net_bridge::connect(&url)?;
```

**Identify.** Frames arrive as `Ready::WsText`. `op:0` (Hello) → `send_text` Identify (`op:1`); `op:2` → identified.

```rust
Ready::WsText(frame) => {
    if frame.handle != session.handle { continue; }
    // Hello (op 0) → Identify; Identified (op 2) → session.identified = true
    on_ws_text(&mut session, &frame.text);
}
```

**Bus → scene.** Follow / `obs.set-scene` → Request (`op:6`) via `net_bridge::send_text`.

```rust
Ready::Bus(event) => {
    let Some(scene) = scene_from_event(&event) else { continue; };
    if !session.identified { continue; }
    let msg = format!(
        r#"{{"op":6,"d":{{"requestType":"SetCurrentProgramScene","requestId":"{id}","requestData":{{"sceneName":"{}"}}}}}}"#,
        escape_json(&scene)
    );
    net_bridge::send_text(session.handle, &msg)?;
}
```

## Assets

| Path | Purpose |
| --- | --- |
| `assets/settings.json` | host, port, password (secret), `follow_scene`, label `status` |

`net.ws` on loopback and raw TCP are forbidden; `net.bridge` only.

## Run

```powershell
modus new bridge --id com.you.obs
modus dev <dir>
```

Without a live OBS on loopback, connect fails. Reference: [`modus new bridge`](modus new bridge) / `plugins/obs-bridge`.

## Typical host errors

| String / situation | Meaning |
| --- | --- |
| `no grant net.bridge` | call without capability |
| non-loopback / not `ws://` | connect refused |
| no connection / bad settings | error → status |
| own TCP / `net.ws` on loopback | `forbidden import` / network |

See [ref/04-errors](../ref/04-errors.md), [ref/06-net-auth](../ref/06-net-auth.md).
