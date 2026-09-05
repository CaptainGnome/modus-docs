# Widget / web-slot

Widget с грантом `ui.slot` и слотом `web`: wasm ↔ страница оверлея через `ui_slot::post` / `Ready::Ui`. Эталон — счётчик кликов поверх ленты чата (шина приходит в JS по WebSocket хоста).

## Feature и гранты

| | |
| --- | --- |
| Feature SDK | `widget` |
| Обязательные гранты | `ui.slot` + `"slots": ["web"]` |
| Модули | `ui_slot` (+ база `wait`) |
| Не делает | сеть, emit |
| Карта | [ref/01-roles](../ref/01-roles.md) |

Эталон: [`modus-examples/widget`](../../../modus-examples/widget). Глухой web без канала wasm — consumer + `slots: ["web"]` без `ui.slot`.

## Манифест

```json
{
  "id": "com.modus.web.slot",
  /* грант канала wasm ↔ страница; без него post/Ui откажут */
  "capabilities": ["ui.slot"],
  /* слот web обязателен в паре с ui.slot (иначе отказ load) */
  "slots": ["web"],
  /* тема стримера из Core → CSS переменные на странице */
  "user_theme": true,
  /* подписка на каталог 7TV: overlay.js рисует emotes */
  "consumes": ["emotes"]
}
```

| Поле | Зачем |
| --- | --- |
| `ui.slot` + `slots` | канал post/Ui; без пары — отказ load |
| `user_theme` | тема стримера для CSS |
| `consumes` | подписка на каталог (7TV `emotes` в overlay.js) |

## Код

**Post в DOM.** Байты уходят на страницу кадром `plugin`.

```rust
fn post_n(n: u32) {
    // JSON, который overlay.js ждёт в кадре plugin
    let body = format!("{{\"n\":{n}}}");
    // post → страница; без ui.slot хост вернёт грант-ошибку
    if let Err(err) = ui_slot::post(body.as_bytes()) {
        log::log(Level::Warn, &err);
    }
}
```

**Клик со страницы → `Ready::Ui`.** Кнопка шлёт JSON; wasm увеличивает счётчик и снова `post`.

```rust
fn run() {
    let mut n = 0u32;
    loop {
        match wait::wait() {
            Ready::Stop => return,
            // клик #inc / --ui: payload от страницы (здесь тело не читаем)
            Ready::Ui(_) => {
                // saturating — не падать на u32::MAX
                n = n.saturating_add(1);
                // сразу отдать новое n в DOM
                post_n(n);
            }
            // Bus и пр. — лента в эталоне рисуется в JS с host WS
            _ => {}
        }
    }
}
```

`subscribe` в `init` — чтобы при желании слушать шину из wasm; лента в эталоне рисуется в JS с host WS.

## Assets

| Путь | Назначение |
| --- | --- |
| [`assets/web/index.html`](../../../modus-examples/widget/assets/web/index.html) | HUD `#count` + `#inc`, `#feed` |
| [`assets/web/overlay.js`](../../../modus-examples/widget/assets/web/overlay.js) | WS: snapshot/batch/catalog/`plugin` |
| [`assets/web/overlay.css`](../../../modus-examples/widget/assets/web/overlay.css) | стили ленты / эмодзи |

Картинки эмодзи — `cache/{key}` (не произвольный origin).

## Как запустить

```powershell
modus new widget --id com.you.overlay --dir overlay
modus dev ../modus-examples/widget --ui click.json
```

`--ui` эмулирует клик без браузера. Полный оверлей — Core / OBS browser source. См. [api/07-ui-slots-panel](../api/07-ui-slots-panel.md).

## Типичные ошибки хоста

| Ситуация | Строка |
| --- | --- |
| `slots` без гранта | `slots требуют грант ui.slot` |
| грант без слота | `ui.slot требует слот web или panel` |
| чужой слот | `слот … не поддерживается` |
| post без `ui.slot` | `нет гранта ui.slot` |
