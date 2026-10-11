# npm-пакет `modus-sdk` (JS/TS)

**Правило.** Публичный guest SDK для JavaScript/TypeScript — отдельный репозиторий [modus-sdk-js](https://github.com/CaptainGnome/modus-sdk-js), пакетное имя `modus-sdk`. Тот же WIT (`modus:abi@2.1.0`, world `plugin`), что у Rust crate. Хост языку не видит. Официальный фокус — **widget** и **alerter**.

Пара к Rust crate — [api/13-sdk-crate](13-sdk-crate.md). Туториал — [start/09-js-ts](../start/09-js-ts.md).

## Подключение

Sibling clone рядом с `modus-sdk`. В плагине (так пишет `modus new --lang ts`):

```json
{
  "dependencies": {
    "modus-sdk": "file:../../modus-sdk-js"
  }
}
```

npm registry в первой итерации не обязателен. Нужен Node ≥20.

## Role presets

Ровно один import-path роли:

```ts
import { definePlugin, wait, info, uiSlot } from "modus-sdk/widget";
// или: import { … } from "modus-sdk/alerter";

export const { lifecycle } = definePlugin({
  init() {
    wait.subscribe();
    info("hello");
  },
  run() {
    for (;;) {
      const ready = wait.wait();
      if (ready.tag === "stop") return;
    }
  },
});
```

World всегда полный `plugin`. Права — манифест + deny на вызове хоста, как у Rust.

## Тулчейн

| Пакет | Pin |
| --- | --- |
| `@bytecodealliance/jco` | 1.37.0 |
| `@bytecodealliance/componentize-js` | 0.23.0 |

`modus pack` / `modus check` / `modus dev` сами вызывают jco componentize с `disableFeatures`: stdio, random, clocks, http, fetch-event. Любой `wasi:*` — отказ. Лимит памяти инстанса — 16 MiB (как Core / `dev`).

В guest sources нельзя опираться на `fetch`, `setTimeout`, `console` — только host `log` / `wait` / capability API.

## CLI

`--lang ts` | `js` — [ref/05-cli](../ref/05-cli.md), [api/11-cli-dev](11-cli-dev.md). Detect: `package.json` (JS) vs `Cargo.toml` (Rust); оба сразу — отказ.
