# CLI `modus`

**Правило.** `dev` собирает **debug**-wasm и поднимает хост в том же процессе. `pack` — **release** + компонент + `.mplug`. Отладка — `dev`, не «поставь mplug в Core».

Сжатый обзор — [ref/05-cli](../ref/05-cli.md). Из корня clone [modus-sdk](https://github.com/CaptainGnome/modus-sdk):

```powershell
cargo run --manifest-path cli/Cargo.toml --release -- <команда>
```

В корне продукта (submodule): `modus-sdk/cli/Cargo.toml`. Тулчейн — [start/01-tools](../start/01-tools.md).

## Команды

| Команда | Зачем |
| --- | --- |
| `new <role> --id …` | каркас на диск |
| `dev [PATH]` | учебный хост без Tauri |
| `check [PATH]` | каталог crate или `.mplug` |
| `pack [PATH]` | `dist/<имя>.mplug` |
| `keygen` | ключ Ed25519 для подписи |

`new connector` не ставит `broker`, официальный Twitch `client_id` и хосты Twitch. В `src` нет `wit_bindgen::generate`.

## `modus new`

```text
modus new <role> --id <reverse.dns.name>
  [--name <str>]
  [--author <str>]
  [--dir <path>]
  [--lang rust]
  [--mode native|web]   # только role panel
```

Роли: `consumer`, `emitter`, `connector`, `provider`, `widget`, `panel` (→ feature `widget`), `reader`, `player`, `bridge`, `embedder`, `rates`, `alerter`, `commander`, `store`.

`--id` обязателен, reverse-DNS ≥3 сегмента. Каталог по умолчанию — последний сегмент id. `--lang` кроме `rust` — отказ. `--mode` только для `panel`.

Карта грантов в каркасе — [ref/01-roles](../ref/01-roles.md). Help `new` совпадает со списком ролей.

## `modus check`

```text
modus check [PATH]
  [--trusted-keys <file>]
```

- каталог — compile component + validate manifest/assets/imports;
- `.mplug` — unpack validate + статус подписи (`signed` / `unsigned` / ошибка).

## `modus pack`

```text
modus pack [PATH]
  [--sign]
  [--key-file <path>]
```

Без ключа — unsigned zip. `--sign` или наличие `MODUS_SIGN_KEY` / `--key-file` — подписать после pack. Подробнее — [10-package-signing](10-package-signing.md).

## `modus keygen`

```text
modus keygen --out <path>
  [--key-id modus-dev]
  [--issuer Modus]
```

## `modus dev`

```text
modus dev [PATH]
  --inject <FILE>       JSON на шину вместо учебной фикстуры
  --token <STR>         фейковый access
  --token-file <FILE>   access из файла
  --account <ID>        id аккаунта для auth.token (по умолчанию dev)
  --replay <FILE>       текстовые кадры WS по строке
  --http-file <FILE>    JSON-ответы net.http (ключ URL без query)
  --ui <FILE>           JSON → Ready::Ui
  --settings <FILE>     оверлей значений → Ready::Settings
  --act <FILE>          JSON act-request → Ready::Act
```

| Флаг | Поведение |
| --- | --- |
| (нет `--inject`) | учебные `message` («fixture hello»), `donation`, `reward` |
| `--inject` | события из JSON вместо фикстуры |
| `--token` / `--token-file` | только процесс CLI; в пакет не попадает |
| `--account` | какой id вернёт `list_accounts` / примет `token` |
| `--replay` | офлайн WS; без него возможен один live `wss://` из `hosts` |
| `--http-file` | офлайн Helix/HTTP |
| `--settings` | нужна `assets/settings.json`; неизвестный ключ — отказ старта; после `init` — `Ready::Settings` |
| `--act` | объект или массив; `id` / `account-id` хост может подставить |
| `--ui` | строка или JSON → `Ready::Ui` |

`PATH` — каталог crate, не `.mplug`.

В `dev`: KV и settings — RAM; `alert.enqueue` / `chat.act` — лог + id (не очередь Core); Ctrl+C → `Ready::Stop`.

Туториал: [consumer](../start/03-dev.md), [коннектор](../start/07-connector.md).

Следующая глава — [лимиты](12-limits.md).
