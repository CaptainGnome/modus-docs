# Поставить инструменты

Если это первый плагин — запускайте команды в PowerShell по одной и читайте, **что делает каждое слово**. Копировать можно; вслепую — нет. Если тулчейн уже стоит и нужен контракт — [справочник](../README.md#справочник).

Результат главы: на экране help CLI, в списке команд есть `new`, `check`, `pack`, `dev`.

## Rust

Если `rustc` уже отвечает — этот шаг пропустите.

Поставьте [rustup](https://rustup.rs/) (официальный установщик Rust: компилятор, `cargo`, цели). После установки **закройте и снова откройте** PowerShell — иначе система не увидит новые программы.

Проверка:

```powershell
rustc -vV
```

- `rustc` — компилятор Rust.
- `-vV` — напечатать версию подробно (строки `release:`, `host:`).

Вы увидите `release:` (сейчас линейка 1.9x) и `host: x86_64-pc-windows-msvc`. Нужен **stable**, не nightly.

Если rustup просит Visual Studio Build Tools — поставьте. Без них `cargo` на Windows не соберёт CLI.

## Цель wasm

Плагин собирается не в `.exe`, а в модуль для песочницы. Цель — «для какой машины компилировать».

```powershell
rustup target add wasm32-unknown-unknown
```

- `rustup` — менеджер тулчейна (то, что ставили с rustup.rs).
- `target` — подкоманда про цели компиляции.
- `add` — скачать и включить цель.
- `wasm32-unknown-unknown` — имя цели: `wasm32` = WebAssembly 32 бита; два `unknown` = нет «производителя» и **нет операционной системы** у гостя.

Проверка:

```powershell
rustup target list --installed
```

- `list` — показать цели.
- `--installed` — только уже стоящие на машине, не весь каталог rustup.

В списке должна быть строка `wasm32-unknown-unknown`. Нет её — `dev` и `pack` позже упадут с текстом `Нужен target wasm32-unknown-unknown`. Ловим здесь, не там.

**Важно.** Эта цель не даёт гостю файлы и сокеты (в wasm это зовут WASI). Иначе песочницу можно обойти. Точнее — [справочник](../README.md#справочник).

## Репозиторий

SDK пока не на crates.io. Публично:

- SDK / CLI / WIT — [CaptainGnome/modus-sdk](https://github.com/CaptainGnome/modus-sdk)
- эта документация — [CaptainGnome/modus-docs](https://github.com/CaptainGnome/modus-docs)

```powershell
git clone https://github.com/CaptainGnome/modus-sdk.git
git clone https://github.com/CaptainGnome/modus-docs.git
cd modus-sdk
```

Команды CLI ниже — **из корня clone `modus-sdk`**. Рядом удобно держать `modus-docs` для чтения гайда. Плагин можно создать в соседней папке (`modus new … --dir ..\my-plugin`) и в `Cargo.toml` указать `path = "../modus-sdk/guest"`.

## CLI

Первый запуск собирает `modus` несколько минут. Это нормально, не «зависло».

```powershell
cargo run --manifest-path cli/Cargo.toml --release -- --help
```

- `cargo` — сборщик Rust: читает `Cargo.toml`, компилирует, запускает.
- `run` — собрать бинарник и сразу выполнить его.
- `--manifest-path cli/Cargo.toml` — пакет CLI внутри clone `modus-sdk` (вы в корне SDK).
- `--release` — оптимизированная сборка **самого CLI** (не плагина). Без флага каждый вызов будет debug и другим файлом.
- `--` — всё, что правее, **не** флаги cargo, а аргументы программы `modus`. Без этого `--help` покажет справку cargo, не modus.
- `--help` — уже modus: напечатать список подкоманд и выйти.

Вы увидите что-то вроде:

```text
Modus plugin SDK (ABI 2)

Usage: modus.exe <COMMAND>

Commands:
  new
  check
  pack
  dev
  help   Print this message or the help of the given subcommand(s)
```

- `Usage: modus.exe <COMMAND>` — запуск: имя программы, потом одна подкоманда. На Windows часто `.exe`.
- `new` / `check` / `pack` / `dev` — подкоманды CLI. Их нет в выводе — вы не в корне репо или сборка упала (текст ошибки **выше** help).

Чтобы не таскать длинную строку, на **эту сессию** PowerShell:

```powershell
function modus { cargo run --manifest-path cli/Cargo.toml --release -- @args }
modus --help
```

- `function modus { … }` — дать короткое имя длинной команде. Живёт, пока открыт этот PowerShell.
- `@args` — передать в cargo всё, что вы написали после `modus`. Поэтому `modus --help` = `cargo run … -- --help`, а позже `modus new …` = `cargo run … -- new …`.
- Второй `--` внутри функции уже стоит: ваши слова идут как аргументы **modus**, не cargo.
- Если вы в корне продукта, где `modus-sdk` — submodule: `--manifest-path modus-sdk/cli/Cargo.toml`.

Дальше в туториале `modus` значит эта функция, пока CLI не стоит отдельной программой в PATH. Сессию закрыли — задайте функцию снова или пишите `cargo run …` целиком.

Следующая глава — [роли в `new`](02-roles.md).
