# CLI `modus`

Если это первый плагин — команды в [туториале](../start/01-tools.md). Если нужна карта флагов — эта глава.

**Правило.** `dev` собирает **debug**-wasm и поднимает хост в том же процессе. `pack` — **release** + компонент + `.mplug`. Отладка — `dev`, не «поставь mplug в Core».

## Команды

| Команда | Зачем |
| --- | --- |
| `new <role> --id …` | каркас на диск |
| `dev [PATH]` | учебный хост без Tauri |
| `check [PATH]` | каталог или `.mplug` |
| `pack [PATH]` | `dist/<имя>.mplug` |
| `keygen` / `pack --sign` | подпись (см. [`docs/signing.md`](../../docs/signing.md)) |

CLI из репозитория (пока не crates.io):

```powershell
cargo run --manifest-path sdk/cli/Cargo.toml --release -- <команда>
```

Или функция `modus` из [туториала](../start/01-tools.md).

`new connector` не ставит `broker`, официальный Twitch `client_id` и хосты Twitch. В `src` нет `wit_bindgen::generate`. Два bindgen (SDK + `generate` в одном crate) — `pack`/`check` отказ.

## `modus dev`

```text
modus dev [PATH]
  --inject <FILE>       JSON на шину вместо учебной фикстуры
  --token <STR>         фейковый access (или --token-file)
  --account <ID>        id аккаунта для auth.token (по умолчанию dev)
  --replay <FILE>       текстовые кадры WS по строке
  --http-file <FILE>    JSON-ответы net.http (ключ URL без query)
  --ui <FILE>           JSON → Ready::Ui
  --settings <FILE>     оверлей значений → Ready::Settings
  --act <FILE>          JSON act-request → Ready::Act
```

- Без `--inject` — учебные `message` («fixture hello»), `donation`, `reward`.
- `--token` / `--token-file` — только процесс CLI; в пакет не попадает.
- `--replay` — офлайн WS; без него возможен один live `wss://` из `hosts` (не private).
- `--settings` — нужна `assets/settings.json`; неизвестный ключ — отказ при старте; после `init` один `Ready::Settings`.
- `--act` — объект или массив; `id` / `account-id` хост может подставить.
- `--ui` — строка или JSON → `Ready::Ui` (виджет / слот).

В `dev`: KV и settings — RAM на процесс; `alert.enqueue` / `chat.act` — лог + id в stderr (не очередь Core и не парк до соседнего wasm). Ctrl+C → `Ready::Stop`.

Туториал: [consumer](../start/03-dev.md), [коннектор](../start/07-connector.md).

## `pack` / `check`

`pack` сам собирает release-wasm, оборачивает в компонент, soft-link импортов. Без успешного `check` файла нет. WASI / чужой импорт — отказ. Известный modus-импорт без гранта в манифесте — soft-link ок; вызов без cap режет хост.

Следующая глава — [сеть и auth](06-net-auth.md).
