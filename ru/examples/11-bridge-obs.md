# Bridge / OBS

Грант `net.bridge` — loopback WS. Протокол OBS WebSocket v5 (Hello → Identify → Request) живёт в wasm, не в Core. Эталон на follow / `custom` `obs.set-scene` шлёт `SetCurrentProgramScene`.

## Feature и гранты

| | |
| --- | --- |
| SDK feature | `bridge` |
| Обязательные | `net.bridge` |
| База | `settings` (host/port/password, `follow_scene`) |

Карта — [ref/01-roles](../ref/01-roles.md). API — [api/09-bridge-history-rates-catalog](../api/09-bridge-history-rates-catalog.md).

## Манифест

```json
{
  "id": "com.modus.obs-bridge",
  "name": "OBS Bridge",
  "version": "0.1.0",
  "abi": 2,
  "capabilities": ["net.bridge"]
}
```

`hosts` / `bridge_requests` не нужны: endpoint — settings; только `ws://` на loopback.

## Код

**Connect.** URL из settings → `net_bridge::connect`.

```rust
let url = format!("ws://{host}:{port}");
let handle = net_bridge::connect(&url)?;
```

**Identify.** Кадры приходят как `Ready::WsText`. `op:0` (Hello) → `send_text` с Identify (`op:1`); `op:2` → identified.

```rust
Ready::WsText(frame) => {
    if frame.handle != session.handle { continue; }
    // Hello (op 0) → Identify; Identified (op 2) → session.identified = true
    on_ws_text(&mut session, &frame.text);
}
```

**Bus → сцена.** Follow / `obs.set-scene` → Request (`op:6`) через `net_bridge::send_text`.

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

## Ассеты

| Путь | Назначение |
| --- | --- |
| `assets/settings.json` | host, port, password (secret), `follow_scene`, label `status` |

`net.ws` на loopback и сырой TCP — запрещены; только `net.bridge`.

## Запуск

```powershell
modus new bridge --id com.you.obs
modus dev <dir>
```

Без живого OBS на loopback connect откажет. Эталон: [`modus new bridge`](modus new bridge) / `plugins/obs-bridge`.

## Типичные ошибки хоста

| Строка / ситуация | Смысл |
| --- | --- |
| `no grant net.bridge` | вызов без capability |
| non-loopback / не `ws://` | отказ connect |
| no connection / неверные settings | ошибка → status |
| свой TCP / `net.ws` на loopback | `forbidden import` / network |

См. [ref/04-errors](../ref/04-errors.md), [ref/06-net-auth](../ref/06-net-auth.md).
