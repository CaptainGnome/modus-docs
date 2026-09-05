# Emitter / fixture

Роль эмитит канон на шину без логина площадки. Fixture — учебный «фейковый чат»: сообщения, донаты, follow, reward, viewers и ответы на `chat.act` через `chat_complete`.

## Feature и гранты

| | |
| --- | --- |
| Feature SDK | `emitter` |
| Обязательные гранты | `bus.emit` (+ непустой `platform_id`) |
| В эталоне ещё | `media.cache` (голос в opaque доната) |
| Модули | `bus_emit`, `chat_complete` |
| Карта | [ref/01-roles](../ref/01-roles.md) |

Эталон: [`modus-examples/emitter`](../../../modus-examples/emitter).

## Манифест

```json
{
  "id": "com.modus.fixture",
  "name": "Fixture",
  "version": "0.1.0",
  "author": "modus",
  "abi": 2,
  /* bus.emit — писать канон; media.cache — pin аудио для voice-доната */
  "capabilities": ["bus.emit", "media.cache"],
  /* метка площадки в Event.source; без неё emit откажет */
  "platform_id": "fixture"
}
```

| Поле | Зачем |
| --- | --- |
| `capabilities` | право писать на шину (+ кэш аудио для voice-доната) |
| `platform_id` | метка площадки в каноне; без неё emit откажет |

## Код

**Пачка emit в `init`.** Хост уже готов; helpers SDK собирают `Payload`, канал `"dev"`.

```rust
fn init() {
    // helper → Payload::Message; user/display/text
    let message = text_message("fixture", "fixture", "fixture hello", None, None);
    // канал "dev" — учебный; None = без opaque
    let _ = bus_emit::emit("dev", &message, None);
    // donation: сумма + валюта + фрагменты текста благодарности
    let donation = donation(
        "fixture", "fixture", 5.0, "USD",
        vec![text_fragment("thanks for the stream!")],
    );
    let _ = bus_emit::emit("dev", &donation, None);
    // follow / reward / viewer_count — тем же emit с другими helpers
}
```

**Voice-донат через assets + cache.** Байты из пакета → ключ кэша → JSON в `opaque`.

```rust
fn emit_voice_donation() -> Result<(), String> {
    // байты из пакета плагина (pack кладёт assets/)
    let bytes = assets::read("sfx.mp3")?;
    // pin в media.cache → ключ для Spec::Url / opaque
    let key = media_cache::put("audio/mpeg", &bytes)?;
    // opaque — произвольный JSON для player/alerter; не канон
    let opaque = format!(
        r#"{{"fixture":"voice","audio_key":"{key}","audio_kind":"voice"}}"#
    );
    let payload = donation("fixture", "fixture-voice", 42.0, "USD",
        vec![text_fragment("voice donation")]);
    // Some(opaque) — player сможет взять audio_key без своего ensure
    bus_emit::emit("dev", &payload, Some(&opaque))
}
```

**Ответ на act.** Командир шлёт job → хост будит `Ready::Act` → fixture эмитит канон и зовёт `complete`.

```rust
fn handle_act(req: ActRequest) {
    // выполнить Ban/Timeout/Send локально (учебный emit ответа)
    match execute(&req) {
        // всегда complete — иначе командир/касса ждут job вечно
        Ok(()) => chat_complete::complete(&req.id, Ok(())),
        Err(err) => chat_complete::complete(&req.id, Err(err.as_str())),
    }
}
```

## Assets

| Путь | Назначение |
| --- | --- |
| [`assets/sfx.mp3`](../../../modus-examples/emitter/assets/sfx.mp3) | короткий звук для `media_cache::put` в voice-донат |

Settings / web / panel у fixture нет.

## Как запустить

```powershell
modus new emitter --id com.you.fixture --dir fixture
modus dev ../modus-examples/emitter
```

Consumer рядом увидит `fixture hello`. Проверка act: `modus dev … --act <json>` ([api/11-cli-dev](../api/11-cli-dev.md)).

## Типичные ошибки хоста

| Ситуация | Строка |
| --- | --- |
| Нет `bus.emit` | `нет гранта bus.emit` |
| Пустой / нет `platform_id` | `нет platform_id` |
| Второй живой плагин той же площадки | `platform_id … уже занят` |
| Emit `system` | `system только Core` |
| Событие > 64 KiB | `TooLarge` |
