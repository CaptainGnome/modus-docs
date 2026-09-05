# Embedder

Роль вставляет чужой origin в iframe слота: грант `media.embed` + `embed_hosts` в манифесте. Wasm решает URL и проверяет `allowed`; страница ставит iframe только по разрешённому хосту. Не youtube-dl и не `play` чужого MP4 на хосте.

## Feature и гранты

| | |
| --- | --- |
| SDK feature | `embedder` |
| Обязательные | `ui.slot`, `media.embed` |
| Манифест | `"slots": ["web", "panel"]`, `embed_hosts`, опционально `user_theme` |

Карта — [ref/01-roles](../ref/01-roles.md). API — [api/08-media-cache-audio-embed](../api/08-media-cache-audio-embed.md), слоты — [api/07-ui-slots-panel](../api/07-ui-slots-panel.md).

## Манифест

```json
{
  "id": "com.modus.embedder",
  "abi": 2,
  /* post в overlay/panel + проверка embed URL */
  "capabilities": ["ui.slot", "media.embed"],
  /* web = iframe оверлей; panel = кнопки треков */
  "slots": ["web", "panel"],
  /* CSS-тема Core на web-странице */
  "user_theme": true,
  /* CSP frame-src; пусто → 'none', iframe не откроется */
  "embed_hosts": ["www.youtube.com"]
}
```

| Поле | Зачем |
| --- | --- |
| `ui.slot` + `slots` | `ui_slot::post` → overlay / panel |
| `media.embed` | `allowed` / `hosts` |
| `embed_hosts` | CSP `frame-src`; пусто → `'none'` |
| `user_theme` | тема Core на web-странице |

## Код

**Старт.** Rickroll в embed URL; post JSON с `embedUrl` и status.

```rust
fn init() {
    wait::subscribe(); // Bus: !play / !skip из чата
    // дефолтный трек при загрузке
    post_url(&Track::Rickroll.embed_url(), Track::Rickroll.label());
}

fn post_url(url: &str, label: &str) {
    // хост сверяет URL с embed_hosts — иначе iframe запрещён CSP
    if !media_embed::allowed(url) {
        log::log(Level::Warn, "embed url not allowed");
        return;
    }
    // overlay.js ждёт embedUrl + status.text
    let body = format!(
        "{{\"embedUrl\":\"{}\",\"status\":{{\"text\":\"{}\"}}}}",
        json_escape(url),
        json_escape(label),
    );
    let _ = ui_slot::post(body.as_bytes());
}
```

**Чат и panel.** `Ready::Bus` Message → команды `!play` / `!pause` / `!stop` / `!skip` / id YouTube. `Ready::Ui` — клики panel (`rickroll`, `play`, …).

```rust
Ready::Bus(event) => {
    // парсер !play / !pause / !stop / !skip / youtube id
    if let Some(action) = action_from_bus(&event) {
        state.apply(action); // может вызвать post_url / post_cmd
    }
}
Ready::Ui(payload) => {
    // id кнопки из panel.json → тот же Action
    if let Some(action) = action_from_ui(&click_id(&payload)) {
        state.apply(action);
    }
}
```

**Custom URL.** Перед mount — снова `allowed`; иначе warn и выход.

```rust
Action::Custom { id, label } => {
    // собрать embed URL строго под embed_hosts
    let url = format!("https://www.youtube.com/embed/{id}?{EMBED_QUERY}");
    // повторная проверка — id мог быть произвольным
    if !media_embed::allowed(&url) { /* warn; return */ }
    post_url(&url, &label);
}
```

Play/pause без смены URL — `post_cmd("play"|"pause")`; страница шлёт postMessage в YouTube iframe. Stop → `embedUrl: ""`.

## Ассеты

| Путь | Назначение |
| --- | --- |
| `assets/web/` | `index.html`, `overlay.js`, `overlay.css` — mount iframe / stub |
| `assets/panel.json` | кнопки треков и transport |

Без `embed_hosts` или без гранта iframe не откроется (CSP / отказ API).

## Запуск

```powershell
modus new embedder  # then: modus dev <dir> --ui
```

Нужен эмиттер сообщений с командами (fixture/twitch) или клики panel. Полный crate: [`modus new embedder`](modus new embedder).

## Типичные ошибки хоста

| Строка / ситуация | Смысл |
| --- | --- |
| `нет гранта media.embed` | вызов без capability |
| `allowed` = false / warn в логе | хост не в `embed_hosts` |
| `slots требуют грант ui.slot` | слоты без гранта |
| дубликаты в `embed_hosts` | отказ манифеста при pack/load |
| CSP `frame-src 'none'` | пустой allowlist |

См. [ref/04-errors](../ref/04-errors.md), [ref/01-roles](../ref/01-roles.md#слоты-uislot).
