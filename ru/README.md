# Плагины Modus

**Языки:** [Русский](README.md) · [English](../en/README.md)

Документация **поверхности гостя** (ABI 2): что видит wasm-плагин через [`modus-sdk`](https://github.com/CaptainGnome/modus-sdk) и CLI `modus`. Core здесь только короткими концептами («Core штампует события шины», «Core паркует `chat.act`», «касса алертов — Core»). Нет глав про брокер изнутри, фильтры ленты, hot-swap, React chrome.

**Публичные репозитории:** этот hub — [modus-docs](https://github.com/CaptainGnome/modus-docs); SDK/CLI/WIT — [modus-sdk](https://github.com/CaptainGnome/modus-sdk); учебные dummy — [modus-examples](https://github.com/CaptainGnome/modus-examples). Разборы с комментариями — [examples/](examples/README.md). Закрытые `plugins/*` продукта в публичный путь не входят.

Путь автора: SDK → `new` → `dev` → `pack` → установка `.mplug` в **готовый** Modus. Язык — Rust. Секреты в пакет не кладут.

## Туториал

Для человека, который умеет скопировать команду в PowerShell. WASM и capability знать не нужно.

| | Глава | Результат |
| --- | --- | --- |
| 0 | [Для кого это и чего ждать](start/00-intro.md) | понятно, чем плагин не является |
| 1 | [Инструменты](start/01-tools.md) | `modus --help` на экране |
| 2 | [Роли](start/02-roles.md) | выбран `consumer`, не Twitch |
| 3 | [Первый `dev`](start/03-dev.md) | в терминале `fixture hello` |
| 4 | [Что нельзя](start/04-cannot.md) | список запретов |
| 5 | [Манифест consumer](start/05-manifest.md) | открыт сгенерированный `manifest` |
| 6 | [Упаковать](start/06-pack.md) | файл `dist/*.mplug` |
| 7 | [Коннектор](start/07-connector.md) (по желанию) | replay кадра без живой площадки |
| 8 | [Дальше](start/08-next.md) | чеклист и ссылки |

Часть 1 — главы 0–6 и 8. Глава 7 не обязательна.

## Справочник

Сжатый контракт: правило → следствие → эталон. Читается с оглавления.

| | Глава | Правило |
| --- | --- | --- |
| 0 | [Контракт](ref/00-contract.md) | SDK + манифест + CLI; WIT не копируют |
| 1 | [Карта ролей](ref/01-roles.md) | feature-пресет + манифест; soft-link; deny на call |
| 2 | [Жизненный цикл и `wait`](ref/02-wait.md) | в `run` только `wait`; стоп не реконнект |
| 3 | [Канон шины](ref/03-canon.md) | штамп Core; `system` только Core |
| 4 | [Ошибки хоста](ref/04-errors.md) | `HostError::classify`, не парсить строки глазами |
| 5 | [CLI](ref/05-cli.md) | `dev` debug, `pack` release; флаги `--settings` / `--act` / `--ui` |
| 6 | [Сеть и auth](ref/06-net-auth.md) | оболочка OAuth у Core; секрет не в wasm |
| 7 | [Settings, KV, act, алерты, слоты](ref/07-host-apis.md) | грант + потолки; `dev` vs Core |
| 8 | [Пакет `.mplug`](ref/08-package.md) | zip: `manifest` + `module.wasm` + posix `assets/` |
| 9 | [Лимиты](ref/09-limits.md) | одна таблица |
| 10 | [Не в этом ABI](ref/10-not-in-abi.md) | граница ABI 2 |
| 11 | [WIT](ref/11-wit.md) | приложение; авторский путь его не копирует |

## API (полная поверхность гостя)

Глубина reference: поля, таблицы, семантика вызовов. Core — только чтобы понять вызов.

| | Глава |
| --- | --- |
| 0 | [Манифест](api/00-manifest.md) |
| 1 | [Lifecycle и `wait`](api/01-lifecycle-wait.md) |
| 2 | [Канон шины](api/02-canon-bus.md) |
| 3 | [Ошибки хоста](api/03-errors.md) |
| 4 | [Базовые host API](api/04-base-host.md) |
| 5 | [Emit, auth, сеть](api/05-emit-auth-net.md) |
| 6 | [KV, act, алерты](api/06-kv-act-alerts.md) |
| 7 | [Слоты и panel](api/07-ui-slots-panel.md) |
| 8 | [Media: cache, audio, embed](api/08-media-cache-audio-embed.md) |
| 9 | [Bridge, history, rates, catalog](api/09-bridge-history-rates-catalog.md) |
| 10 | [Пакет и подпись](api/10-package-signing.md) |
| 11 | [CLI](api/11-cli-dev.md) |
| 12 | [Лимиты](api/12-limits.md) |
| 13 | [Crate `modus-sdk`](api/13-sdk-crate.md) |

## Эталоны

Разборы эталонных плагинов: манифест + ключевые куски кода с комментариями.

| | Глава | Эталон |
| --- | --- | --- |
| — | [оглавление](examples/README.md) | |
| 0–13 | consumer … rates | [`examples/`](examples/README.md) |
