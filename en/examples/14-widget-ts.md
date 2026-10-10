# Widget TS

Educational TypeScript widget dummy. Same contract as the Rust [`widget/`](04-widget-web-slot.md): grant `ui.slot`, slot `web`, `uiSlot.post` / lifecycle. The host does not see the language.

## Feature and grants

| | |
| --- | --- |
| Guest SDK | npm `modus-sdk` → import `modus-sdk/widget` |
| Required grants | `ui.slot` + `"slots": ["web"]` |
| Does not | network, emit, connector |
| Runnable | [`modus-examples/widget-ts`](https://github.com/CaptainGnome/modus-examples/tree/master/widget-ts) |
| Tutorial | [start/09-js-ts](../start/09-js-ts.md) |

Your own plugin — `modus new widget --lang ts`, not a fork of the dummy.

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

Sibling clone: `modus-sdk`, `modus-sdk-js`, `modus-examples` under one parent. Otherwise `file:` will not resolve.

## Manifest

```json
{
  "id": "com.modus.examples.widget-ts",
  "capabilities": ["ui.slot"],
  "slots": ["web"]
}
```

## Code

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

No `fetch` / `setTimeout` / `console` in the guest — host APIs only (`log` / `wait` / …).

## Run

From the sibling `modus-sdk` root (Node ≥20):

```powershell
modus pack ../modus-examples/widget-ts
modus dev ../modus-examples/widget-ts --ui
```

`pack`/`dev` run npm + jco themselves. No hand-built `module.wasm` for this path. Unlike Rust `widget/`: no `Cargo.toml`; you get `package.json` + `guest.ts`.
