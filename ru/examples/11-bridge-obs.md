# Bridge / OBS

Роль не открывает сокет к OBS сама: RPC идёт через Core (`bridge.obs`) по allowlist типов из манифеста. Эталон на follow (или `custom` `obs.set-scene`) вызывает `SetCurrentProgramScene`.

## Feature и гранты

| | |
| --- | --- |
| SDK feature | `bridge` |
| Обязательные | `bridge.obs` + непустой `bridge_requests` |
| База | `settings` (host/port/password UI, сцена follow) |

Карта — [ref/01-roles](../ref/01-roles.md). API — [api/09-bridge-history-rates-catalog](../api/09-bridge-history-rates-catalog.md).

## Манифест

```json
{
  "id": "com.modus.obs-bridge",
  "name": "OBS Bridge",
  "version": "0.1.0",
  "abi": 2,
  /* RPC только через Core; свой TCP к OBS запрещён */
  "capabilities": ["bridge.obs"],
  /* whitelist типов OBS WebSocket; иное → отказ */
  "bridge_requests": ["SetCurrentProgramScene"]
  /* Get/SetStreamServiceSettings и пр. — denylist Core даже из списка */
}
```

| Поле | Зачем |
| --- | --- |
| `bridge.obs` | `bridge::invoke` |
| `bridge_requests` | whitelist типов OBS; иное — отказ |
| denylist Core | в т.ч. `Get/SetStreamServiceSettings` — даже из манифеста нельзя |

## Код

**Init.** Подписка и label статуса.

```rust
fn init() {
    // follow / custom приходят как Ready::Bus
    wait::subscribe();
    // label status в settings UI
    refresh_status("ожидание событий");
}
```

**Bus → invoke.** Follow → имя сцены из settings; `custom` kind `obs.set-scene` → поле `scene` в `fields`. Payload — JSON для OBS.

```rust
Ready::Bus(event) => {
    let scene = match &event.payload {
        // follow → settings.follow_scene (пусто = не переключать)
        Payload::Follow(_) => follow_scene(),
        // custom kind от другого плагина / inject
        Payload::Custom(c) if c.kind == "obs.set-scene" => scene_from_fields(&c.fields),
        _ => None,
    };
    let Some(scene) = scene else { continue; };
    // тело OBS request SetCurrentProgramScene
    let payload = format!("{{\"sceneName\":\"{}\"}}", escape_json(&scene));
    // "obs" = id цели у Core; тип обязан быть в bridge_requests
    match bridge::invoke("obs", "SetCurrentProgramScene", payload.as_bytes()) {
        Ok(_) => refresh_status(&format!("сцена: {scene}")),
        Err(err) => { log::log(Level::Warn, &err); refresh_status(&err); }
    }
}
```

**Settings.** `follow_scene` — строка имени сцены OBS; пусто → на follow не переключать. `host` / `port` / `password` читает Core для соединения, гость их в сокет не кладёт.

```rust
fn follow_scene() -> Option<String> {
    // имя сцены OBS из формы; Core само читает host/port/password
    let scene = settings::get("follow_scene").unwrap_or_default();
    let scene = scene.trim();
    // пусто → на Follow не звать invoke
    if scene.is_empty() { None } else { Some(scene.to_string()) }
}
```

Первый аргумент `invoke` (`"obs"`) — id цели у Core, как заведено в UI хоста.

## Ассеты

| Путь | Назначение |
| --- | --- |
| `assets/settings.json` | host, port, password (secret), `follow_scene`, label `status` |

Сырой WASI/`net` на private IP к OBS — запрещён; только bridge.

## Запуск

```powershell
modus dev plugins/obs-bridge
```

В `dev` bridge — заглушка/лог, не живой OBS WebSocket. Полный crate: [`../../../plugins/obs-bridge`](../../../plugins/obs-bridge).

## Типичные ошибки хоста

| Строка / ситуация | Смысл |
| --- | --- |
| `нет гранта bridge.obs` | вызов без capability |
| тип не в `bridge_requests` | whitelist манифеста |
| denylist Core | чувствительные OBS request |
| нет соединения / неверные settings | ошибка от Core → в status |
| попытка своего TCP к OBS | запрещённый импорт / сеть |

См. [ref/04-errors](../ref/04-errors.md), [ref/06-net-auth](../ref/06-net-auth.md).
