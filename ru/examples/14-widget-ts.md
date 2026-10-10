# Widget TS

Учебный dummy виджета на TypeScript. Тот же контракт, что у Rust [`widget/`](04-widget-web-slot.md): грант `ui.slot`, слот `web`, `uiSlot.post` / lifecycle. Хост языку не видит.

## Feature и гранты

| | |
| --- | --- |
| Guest SDK | npm `modus-sdk` → import `modus-sdk/widget` |
| Обязательные гранты | `ui.slot` + `"slots": ["web"]` |
| Не делает | сеть, emit, коннектор |
| Runnable | [`modus-examples/widget-ts`](https://github.com/CaptainGnome/modus-examples/tree/master/widget-ts) |
| Туториал | [start/09-js-ts](../start/09-js-ts.md) |

Свой плагин — `modus new widget --lang ts`, не форк dummy.

## Layout

```text
widget-ts/
  package.json          # "modus-sdk": "file:../../modus-sdk-js"
  guest.ts              # definePlugin + uiSlot.post
  tsconfig.json
  scripts/rolldown.config.mjs
  manifest
  assets/web/
```

Sibling clone: `modus-sdk`, `modus-sdk-js`, `modus-examples` под одним родителем. Иначе `file:` не резолвится.

## Манифест

```json
{
  "id": "com.modus.examples.widget-ts",
  "capabilities": ["ui.slot"],
  "slots": ["web"]
}
```

## Код

```ts
import { definePlugin, wait, info, uiSlot } from "modus-sdk/widget";

const { lifecycle } = definePlugin({
  init() {
    wait.subscribe();
    info("init");
    uiSlot.post(new TextEncoder().encode("<div>hello</div>"));
  },
  run() {
    for (;;) {
      const ready = wait.wait();
      if (ready.tag === "stop") return;
    }
  },
});

export { lifecycle };
```

В госте нет `fetch` / `setTimeout` / `console` — только host API (`log` / `wait` / …).

## Запуск

Из корня sibling `modus-sdk` (Node ≥20):

```powershell
modus pack ../modus-examples/widget-ts
modus dev ../modus-examples/widget-ts --ui
```

`pack`/`dev` сами зовут npm + jco. Ручной `module.wasm` для этого пути не нужен. Отличие от Rust `widget/`: нет `Cargo.toml`, есть `package.json` + `guest.ts`.
