# Media: cache, audio, embed

**Правило.** Бинарники и звук идут через хост. Гость не открывает устройства и не качает файлы своим сокетом мимо `net.*` / cache. Embed — только iframe allowlist, не youtube-dl и не `play` чужого MP4 на хосте.

Эталоны: cache/catalog — `modus new provider`; audio — `modus new player`; embed — `modus new embedder`.

## `media.cache`

Грант `media.cache`. Типично connector / provider / player.

```text
lookup(url) -> Option<string>          // cache-key или None
ensure(url) -> Result<string, string>  // скачать/закрепить → key
put(mime, bytes) -> Result<string, string>
release(key) -> Result<(), string>
```

| Вызов | Смысл |
| --- | --- |
| `lookup` | уже есть в кэше? |
| `ensure` | хост тянет URL (https + allowlist как у сети) и pin |
| `put` | положить сырые байты (`audio/mpeg` или `audio/wav`) |
| `release` | отпустить pin (после `MediaEnded` у player) |

Ключ используют web-слоты как `cache/{key}` в `<img>` / CSP. Не секретное хранилище.

## `media.audio`

Грант `media.audio`. Feature `player` (+ cache обычно рядом).

```text
play(spec) -> Result<string, string>   // playback id (или cache-key для overlay TTS)
stop(id) -> Result<(), string>
duration-ms(spec) -> Result<u32, string>
list-voices() -> Result<list<voice>, string>
render-tts(tts) -> Result<string, string>  // только cache; Ok = 64-hex key
start-render-tts(tts) -> Result<string, string>  // Ok = request-id; Ready::tts-rendered
```

`spec`:

| Вариант | Значение |
| --- | --- |
| `asset(path)` | файл из `assets/` пакета |
| `url(https\|cache-key)` | URL через политику хоста / cache |
| `tts(text)` | TTS хоста с голосом Core по умолчанию |
| `tts-ex({ text, voice? })` | то же; опциональный токен SpVoice |

Настройки Core (хром): `tts.voice`, `tts.output` = `speakers` \| `overlay` \| `both`.

| `tts.output` | Поведение `play(tts*)` | `play` Ok |
| --- | --- | --- |
| `speakers` | Speak в устройство по умолчанию | uuid play-id |
| `overlay` | Один синтез → WAV в `media.cache`; без колонок | 64-hex `audioKey` |
| `both` | Тот же WAV → cache + rodio | 64-hex `audioKey` |

`render-tts` — синтез в cache **без** колонок и **без** play-id / `MediaEnded`; `tts.output` не читает. Синхронный prefetch.

`start-render-tts` сразу отдаёт request-id; готовность — `Ready::tts-rendered { request-id, key?, error? }` (фон SpVoice → cache). На шине предпочитать это, чтобы другие события не ждали Speak. Для алертов: сразу `enqueue` с `pending-audio`, затем `mark-ready` на `tts-rendered` (или TTL Core → play без голоса). Opaque `audio_key` → enqueue сразу ready. Не держать слот кассы, пока Speak не закончится. `pending-audio` / `mark-ready` — общий контракт кассы: тот же путь для стороннего TTS (сеть → `media.cache.put` → `mark-ready`), не только SpVoice.

Гость кладёт звук в оверлей через `ui.slot` / `audioKey` (как voice-донат). Mute глушит только колонки. `list-voices` — тот же грант; пусто на non-Windows / null.

Конец трека или успешный `stop` → `Ready::MediaEnded(id)`.

В `dev` audio — заглушка/лог; `list-voices` / `render-tts` / `start-render-tts` — stub (`tts-rendered` с пустым/синтетическим исходом по реализации `dev`).

## `media.embed`

Грант `media.embed` + манифест `embed_hosts` + обычно `ui.slot` + `slots` web/panel. Feature `embedder`.

```text
hosts() -> list<string>     // копия allowlist манифеста
allowed(url) -> bool        // можно ли этот URL в iframe
```

| Тема | Правило |
| --- | --- |
| `embed_hosts` пуст / нет cap | CSP `frame-src 'none'` |
| вызов без гранта | отказ |
| задача гостя | решить, какой URL вставить; страница ставит iframe только если `allowed` |
| не делает | прокси MP4, скачивание, обход `hosts` wasm |

Дубликаты в `embed_hosts` — отказ манифеста. Формат хоста как у `hosts`.

Связь со слотами — [07-ui-slots-panel](07-ui-slots-panel.md). Сеть — [05-emit-auth-net](05-emit-auth-net.md).

Следующая глава — [history, rates, catalog](09-bridge-history-rates-catalog.md).
