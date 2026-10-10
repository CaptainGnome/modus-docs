# JS/TS: виджет без Rust в госте

Параллельный путь к части 1 (consumer на Rust). Хост языку не видит: тот же ABI 2, тот же `check`, тот же `.mplug`. Официальный фокус JS/TS — **widget** и **alerter**. Коннекторы остаются на Rust.

Результат главы: `dist/*.mplug` от `modus new widget --lang ts` и зелёный `modus dev` без Tauri.

## Что нужно

- Sibling clone: [modus-sdk](https://github.com/CaptainGnome/modus-sdk), [modus-sdk-js](https://github.com/CaptainGnome/modus-sdk-js), [modus-examples](https://github.com/CaptainGnome/modus-examples) (и этот hub — по желанию).
- **Node.js ≥ 20** — guest и jco. Проверка: `node -v`.
- Бинарь `modus` — из sibling `modus-sdk` (`cargo run --manifest-path cli/Cargo.toml --release -- …`) или уже установленный. Rust toolchain нужен, чтобы **собрать CLI**, не чтобы писать guest TS.

```powershell
git clone https://github.com/CaptainGnome/modus-sdk.git
git clone https://github.com/CaptainGnome/modus-sdk-js.git
git clone https://github.com/CaptainGnome/modus-examples.git
cd modus-sdk
```

Функция `modus` из [инструментов](01-tools.md) или полный `cargo run … --`.

## Каркас

Из корня `modus-sdk`:

```powershell
modus new widget --lang ts --id com.example.hud --dir ..\my-hud
```

- `--lang ts` — TypeScript (основной DX). Есть и `--lang js`.
- Роли для JS/TS: только `widget` и `alerter`. Иное — отказ `JS/TS: widget and alerter only`.
- В каркасе: `package.json` (`modus-sdk` → `file:` на sibling `modus-sdk-js`), `guest.ts`, `manifest`, `assets/web/`, `scripts/rolldown.config.mjs`.

## `dev` и `pack`

```powershell
modus dev ..\my-hud --ui
modus pack ..\my-hud
```

CLI сам делает `npm install` и jco componentize. Отдельный `npm run build` для учебного пути не нужен. WASI / `wasi:*` — отказ `check`/`pack`.

Учебный dummy без своего `new`: [`modus-examples/widget-ts`](https://github.com/CaptainGnome/modus-examples/tree/master/widget-ts) — [разбор](../examples/14-widget-ts.md).

```powershell
modus pack ../modus-examples/widget-ts
modus dev ../modus-examples/widget-ts --ui
```

Дальше `.mplug` ставится в **shipped** Modus, как у Rust. npm-фасад — [api/14-sdk-js](../api/14-sdk-js.md). CLI `--lang` — [ref/05-cli](../ref/05-cli.md).
