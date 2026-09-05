# Player

Роль играет звук через хост (`media.audio`): устройство и драйвер выбирает Core. Эталон слушает donation/sub, берёт `audio_key` из `opaque` или падает на ассет `sfx.mp3`, после `MediaEnded` отпускает pin кэша.

## Feature и гранты

| | |
| --- | --- |
| SDK feature | `player` |
| Обязательные | `media.audio`, `media.cache` |

Карта — [ref/01-roles](../ref/01-roles.md). API — [api/08-media-cache-audio-embed](../api/08-media-cache-audio-embed.md).

## Манифест

```json
{
  "id": "com.modus.player",
  "name": "Player",
  "version": "0.1.0",
  "abi": 2,
  /* play/stop + MediaEnded; release pin после URL-трека */
  "capabilities": ["media.audio", "media.cache"]
}
```

| Поле | Зачем |
| --- | --- |
| `media.audio` | `play` / `stop`, wake `MediaEnded` |
| `media.cache` | `release` после окончания URL-трека |

## Код

**Bus → play.** Только donation и sub. Spec: `Url(cache-key)` или `Asset("sfx.mp3")`. Id воспроизведения кладётся в `pending`.

```rust
Ready::Bus(event) => {
    // message/follow и пр. — не наш триггер звука
    if !matches!(&event.payload, Payload::Donation(_) | Payload::Sub(_)) {
        continue;
    }
    // opaque от emitter/connector: {"audio_key":"…"}
    let audio_key = audio_key_from_opaque(event.opaque.as_deref());
    let spec = match audio_key.as_ref() {
        // Url = ключ media.cache (не http)
        Some(key) => Spec::Url(key.clone()),
        // fallback — файл из пакета плагина
        None => Spec::Asset("sfx.mp3".into()),
    };
    match media_audio::play(&spec) {
        // id нужен, чтобы на MediaEnded знать, что release'ить
        Ok(id) => { pending.insert(id, audio_key); }
        Err(err) => log::log(Level::Warn, &err),
    }
}
```

**Конец / Stop.** `MediaEnded` → `media_cache::release` только если играли по cache-key. На `Stop` — release всех оставшихся.

```rust
Ready::MediaEnded(id) => {
    // Some(Some(key)) = играли Url → отпустить pin
    if let Some(Some(key)) = pending.remove(&id) {
        let _ = media_cache::release(&key);
    } else {
        // Asset / уже снято — только убрать из pending
        pending.remove(&id);
    }
}
```

**Opaque.** Простой разбор `"audio_key":"…"` из JSON-хвоста события (коннектор/другой плагин кладёт ключ после `media_cache::ensure`).

```rust
fn audio_key_from_opaque(opaque: Option<&str>) -> Option<String> {
    let raw = opaque?; // нет opaque → fallback Asset
    let marker = "\"audio_key\"";
    // найти пару кавычек после маркера — учебный парсер без serde
    // …вернуть String ключа кэша
}
```

TTS в этом эталоне нет: `Spec::Tts` / `custom` `tts.request` — отдельный путь того же гранта.

## Ассеты

| Путь | Назначение |
| --- | --- |
| `assets/sfx.mp3` | fallback `Spec::Asset` |

## Запуск

```powershell
modus new <role>  # scaffold, then modus dev <dir>
```

В `dev` audio часто заглушка/лог — не ждите паритета с Core. Полный crate: [`modus new player`](modus new player).

## Типичные ошибки хоста

| Строка / ситуация | Смысл |
| --- | --- |
| `нет гранта media.audio` | `play` без capability |
| `нет гранта media.cache` | `release` / ensure без гранта |
| отказ URL | политика сети / нет pin в кэше |
| нет `MediaEnded` в `dev` | возможная заглушка CLI |

См. [ref/04-errors](../ref/04-errors.md), [ref/09-limits](../ref/09-limits.md).
