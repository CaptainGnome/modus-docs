# Alerter

Роль ставит талон в кассу Core (`alert.enqueue`), а показ делает сама: после `Ready::AlertPlay` шлёт JSON в web-оверлей. Очередь, приоритеты и skip — у хоста; гость не ведёт свою кассу. Эталон — `modus new alerter` (~1900 строк UI/тиров; ниже только узлы потока).

## Feature и гранты

| | |
| --- | --- |
| SDK feature | `alerter` |
| Обязательные | `alert.enqueue`, `ui.slot`, `history.read` |
| Слоты | `"slots": ["web", "panel"]` |
| Дополнительно в эталоне | `storage.kv` (тиры/стиль), `media.audio` (SFX), `rates.convert` (донат → base) |

Карта — [ref/01-roles](../ref/01-roles.md). Касса — [api/06-kv-act-alerts](../api/06-kv-act-alerts.md).

## Манифест

```json
{
  "id": "com.modus.alerter",
  "abi": 2,
  "capabilities": [
    /* талон в кассу Core + complete после показа */
    "alert.enqueue",
    /* оверлей OBS (web) и native panel */
    "ui.slot",
    /* recovery: прочитать журнал после рестарта / Resume */
    "history.read",
    /* тиры и стиль между сессиями */
    "storage.kv",
    /* SFX по ключу кэша при AlertPlay */
    "media.audio",
    /* donation → base currency для матча тира */
    "rates.convert"
  ],
  /* оба слота: web-оверлей + panel настроек */
  "slots": ["web", "panel"]
}
```

| Поле | Зачем |
| --- | --- |
| `alert.enqueue` | `enqueue` / `complete` |
| `ui.slot` + `slots` | оверлей OBS (`web`) и native panel |
| `history.read` | recovery после рестарта / `Resume` |
| `storage.kv` | тиры и стиль между сессиями |
| `media.audio` | SFX по ключу кэша при play |
| `rates.convert` | матч donation-тира в валюте Core |

## Код

**Цикл.** Подписка в `init`; в `run` — шина → enqueue, play/stop → оверлей, UI panel, recovery на `Resume`.

```rust
fn init() {
    // шина нужна: Bus → enqueue
    wait::subscribe();
    // KV → стиль/тиры в память до первого события
    load_style();
    load_all_tiers();
    // сразу синхронизировать panel и CSS оверлея
    post_panel();
    post_style();
    // спрятать карточку на случай грязного DOM после hot-reload
    hide();
    // догнать высокие приоритеты из history (не через wait)
    recover();
}

fn run() {
    loop {
        match wait::wait() {
            Ready::Stop => return,
            // канон → Job в кассу Core
            Ready::Bus(event) => enqueue_bus(&event),
            // касса разрешила показ → SFX + post show
            Ready::AlertPlay(cmd) => on_play(&cmd),
            // касса / skip → hide + complete
            Ready::AlertStop(cmd) => on_stop(&cmd),
            // клики panel: тиры, стиль, test
            Ready::Ui(payload) => on_ui(&payload),
            // после Resume — снова hide + recover из history
            Ready::Resume => { hide(); recover(); }
            // Ws / Act / Timer — игнор в этом эталоне
        }
    }
}
```

**Enqueue.** На интересный `Bus` (и не `skip_alert`) строится `Job`, карточка кэшируется по `event_id`, талон уходит в Core. Донат перед матчем тира конвертируется в base.

```rust
fn enqueue_bus(event: &Event) {
    // флаг канона: стример/коннектор попросили не алертить
    if event.flags.skip_alert { return; }
    // title/body/tier match; для donation — rates::convert_to_base
    // CARDS[event_id] = Card { title, body, image_key, sfx_key }
    CARDS.with(|map| { /* Card { title, body, image_key, sfx_key } */ });
    if let Err(err) = alert_enqueue::enqueue(&Job {
        // id события = ключ дедупа и связи с Card
        event_id: event.id.clone(),
        priority,      // из тира
        duration_ms,   // сколько держать show
        title,
        body,
    }) {
        // откат Card + лог — иначе утечка кэша карточек
    }
}
```

**Play / stop.** Core будит play → SFX + `ui_slot::post` с `op: show`. Stop / hide → `complete`.

```rust
fn on_play(cmd: &AlertCommand) {
    // Card из CARDS[event_id] или fallback-текст из Job
    if let Some(key) = sfx_key.as_ref() {
        // Spec::Url — ключ media.cache, не http URL
        let _ = media_audio::play(&Spec::Url(key.clone()));
    }
    // op:show → overlay.js монтирует карточку на durationMs
    let payload = format!(
        "{{\"op\":\"show\",\"jobId\":\"{}\",\"eventId\":\"{}\",\"durationMs\":{},…}}",
        /* job_id / event_id / title / body / image… */
    );
    let _ = ui_slot::post(payload.as_bytes());
}

fn on_stop(cmd: &AlertCommand) {
    hide(); // post {"op":"hide"} — убрать карточку из DOM
    // убрать Card из CARDS
    // complete обязателен — иначе касса считает job живым
    let _ = alert_enqueue::complete(&cmd.job_id, Ok(()));
}
```

**Recovery.** Не replay в `wait`: `history_read::read`, пропуск уже `alert_shown`, повторный enqueue высоких приоритетов.

```rust
fn recover() {
    // history — отдельный API, не Ready::Bus
    let Ok(page) = history_read::read(None, 50) else { return; };
    for event in &page.events {
        // уже показали до рестарта — не дублировать
        if page.alert_shown.iter().any(|id| id == &event.id) { continue; }
        // только high-prio (donation/sub…), не весь чат
        if !is_high_prio(&event.payload) { continue; }
        enqueue_bus(event);
    }
}
```

В `modus dev` enqueue/complete пишутся в stderr **без** `AlertPlay`/`AlertStop` — оверлей в CLI не крутится как в Core.

## Ассеты

| Путь | Назначение |
| --- | --- |
| `assets/web/` | `index.html`, `overlay.js`, `overlay.css` — WS от хоста, `op: show/hide/style` |
| `assets/panel.json` | native panel: тиры, цвета, анимации |
| `assets/i18n/{en,ru}.json` | подписи panel |

Web не ходит в сеть сам: кадры `plugin` и `cache/{key}` по CSP слота.

## Запуск

Из корня репо:

```powershell
modus new <role>  # scaffold, then modus dev <dir>
```

Полный crate: [`modus new alerter`](modus new alerter). С эмиттером событий — рядом fixture/twitch; курсы для donation FX — [13-rates-fx](13-rates-fx.md).

## Типичные ошибки хоста

| Строка / ситуация | Смысл |
| --- | --- |
| `нет гранта alert.enqueue` | вызов без capability |
| `slots требуют грант ui.slot` / `ui.slot требует слот…` | манифест слотов |
| отказ `history.read` | нет гранта → recovery молча пустой |
| `нет гранта rates.convert` / нет курса | donation без convert; тир может не матчиться |
| в `dev` нет play | ожидаемо: касса Core не эмулируется |

См. [ref/04-errors](../ref/04-errors.md), [api/01-lifecycle-wait](../api/01-lifecycle-wait.md).
