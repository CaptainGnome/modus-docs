# Media: cache, audio, embed

**Правило.** Бинарники и звук идут через хост. Гость не открывает устройства и не качает файлы своим сокетом мимо `net.*` / cache. Embed — только iframe allowlist, не youtube-dl и не `play` чужого MP4 на хосте.

Эталоны: cache/catalog — [`plugins/7tv`](../../../plugins/7tv); audio — [`plugins/player`](../../../plugins/player); embed — [`plugins/embedder`](../../../plugins/embedder).

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
| `put` | положить сырые байты с mime |
| `release` | отпустить pin (после `MediaEnded` у player) |

Ключ используют web-слоты как `cache/{key}` в `<img>` / CSP. Не секретное хранилище.

## `media.audio`

Грант `media.audio`. Feature `player` (+ cache обычно рядом).

```text
play(spec) -> Result<string, string>   // playback id
stop(id) -> Result<(), string>
```

`spec`:

| Вариант | Значение |
| --- | --- |
| `asset(path)` | файл из `assets/` пакета |
| `url(https)` | URL через политику хоста / cache |
| `tts(text)` | синтез на стороне хоста (если доступен) |

Конец трека или успешный `stop` → `Ready::MediaEnded(id)`. Player отпускает связанные cache-key. Устройство вывода выбирает Core, не плагин.

TTS-запрос с шины: другой плагин может эмитить `custom` kind `tts.request`; исполнитель с `media.audio` играет. Эталонный alerter без audio — только overlay.

В `dev` audio — заглушка/лог по возможности CLI; не ждите паритета драйвера с Core.

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

Следующая глава — [bridge, history, rates, catalog](09-bridge-history-rates-catalog.md).
