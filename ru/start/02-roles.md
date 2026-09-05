# Роли: что жать в `new`

Если это первый плагин — цель главы: выбрать **`consumer`** и придумать `id`. Остальные роли из help существуют и работают; новичку туда не идти в части 1. Полная карта feature × грант — [справочник](../ref/01-roles.md).

Сначала посмотрите, что CLI умеет создать.

```powershell
modus new --help
```

- `modus` — функция из [главы про инструменты](01-tools.md). Нет её в этой сессии — задайте снова.
- `new` — подкоманда: **создать** каркас плагина на диске. В этой главе её ещё не запускаем с ролью, только help.
- `--help` — справка **этой** подкоманды, не всего CLI.

Вы увидите:

```text
Usage: modus.exe new [OPTIONS] --id <ID> <ROLE>

Arguments:
  <ROLE>  [possible values: consumer, emitter, connector, provider, widget, panel, reader, player, bridge, embedder, rates, alerter, commander, store]

Options:
      --id <ID>
      --name <NAME>
      --author <AUTHOR>
      --dir <DIR>
      --lang <LANG>
      --mode <MODE>      [possible values: native, web]
  -h, --help             Print help
```

- `<ROLE>` — позиционный аргумент: слово **без** `--`. Одно из значений в `possible values`. Других `new` не знает.
- `--id <ID>` — обязательный флаг. Идентификатор плагина, не ник и не имя папки.
- `--name` / `--author` — подпись в манифесте. Можно не указывать: имя из последнего куска `id`, автор — `author`.
- `--dir <DIR>` — папка каркаса. Нет флага — папка = последний кусок `id`. Путь относительно **текущей** директории (корень clone `modus-sdk`).
- `--lang` — не указывайте: и так Rust. Иное значение — отказ `S1 Rust only`.
- `--mode` — только для `panel`: `native` или `web`.
- `[OPTIONS]` в Usage — флаги необязательны, кроме отдельно перечисленных. Здесь отдельно обязателен `--id`.

Порядок: `modus new consumer --id …` и `modus new --id … consumer` — оба ок.

## С чего начать (часть 1)

| Роль | Что делает | Когда |
| --- | --- | --- |
| `consumer` | Слушает шину | **Первый плагин** |
| `emitter` | Кладёт канон на шину без сети площадки | После consumer; учебный источник в приложении |
| `connector` | Логин, сеть через хост, emit канона | После `wait`; глава [07](07-connector.md) с `--replay` |

Слушать и класть — разные права. Consumer только слушает. В `dev` учебные события на шину кладёт **хост** (фикстура), не ваш код.

Эталон consumer — [`modus-examples/consumer`](https://github.com/CaptainGnome/modus-examples/tree/master/consumer). Копировать не нужно: `new` пишет свежий каркас.

## Все роли `new`

Короткая карта. Детали и гранты — [ref/01-roles](../ref/01-roles.md); разборы кода — [examples/](../examples/overview.md).

| Роль | Одной фразой | Runnable |
| --- | --- | --- |
| `consumer` | слушать шину | [`modus-examples/consumer`](https://github.com/CaptainGnome/modus-examples/tree/master/consumer) |
| `emitter` | класть message/donation без площадки | [`modus-examples/emitter`](https://github.com/CaptainGnome/modus-examples/tree/master/emitter) |
| `connector` | площадка через хост | [`modus-examples/connector-replay`](https://github.com/CaptainGnome/modus-examples/tree/master/connector-replay) |
| `provider` | каталог эмоутов (`catalog.publish`) | `modus new provider` |
| `widget` | web-слот, кадры в DOM | [`modus-examples/widget`](https://github.com/CaptainGnome/modus-examples/tree/master/widget) |
| `panel` | док в раскладке Core (`native` / `web`) | `modus new panel` |
| `reader` | страницы журнала (`history.read`) | `modus new reader` |
| `player` | звук через Core (`media.audio`) | `modus new player` |
| `bridge` | OBS WebSocket (`bridge.obs`) | `modus new bridge` |
| `embedder` | iframe чужого origin (`media.embed`) | `modus new embedder` |
| `rates` | таблица курсов (`rates.publish`) | `modus new rates` |
| `alerter` | талон в кассу алертов + оверлей | `modus new alerter` |
| `commander` | `chat.act` (бан / timeout / …) | `modus new commander` |
| `store` | `storage.kv` | `modus new store` |

`panel` в SDK — та же feature `widget`, другой манифест/ассеты. Новичок: только `consumer`, пока не закроете часть 1.

## `id`

Формат — reverse-DNS (**с конца** «чьё» и «что»).

Правила (иначе CLI: `plugin id: reverse-DNS required (com.publisher.name)`):

- минимум **три** куска через точку: `com.you.bus`;
- строчные `a-z`, цифры и дефис внутри куска;
- без заглавных, без `_`, без двух кусков.

Почему нельзя `twitch`: одно слово, не пространство имён. Официальный коннектор — `com.modus.twitch`.

Последний кусок — имя crate и папки по умолчанию. Смена `id` позже = **другой** плагин (настройки не переедут).

Пример для следующей главы: `com.you.bus` (свой второй кусок вместо `you`).

Проверка, что короткий id отвергается:

```powershell
modus new consumer --id twitch
```

Вы увидите `plugin id: reverse-DNS required (com.publisher.name)`. Это успех главы.

## Что не выбирать сейчас

Не `connector` без главы 7: без `--token` каркас пишет `no account` и ждёт стоп — штатно, но как первый опыт тупик.

Не `emitter` / `provider` / UI / act / KV: сначала слушатель и `wait`.

Итог: роль **`consumer`**, id вида `com.you.bus`. Следующая глава — [new и `dev`](03-dev.md).
