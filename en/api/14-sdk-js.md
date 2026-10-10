# npm package `modus-sdk` (JS/TS)

**Rule.** The public guest SDK for JavaScript/TypeScript is the separate repo [modus-sdk-js](https://github.com/CaptainGnome/modus-sdk-js), package name `modus-sdk`. Same WIT (`modus:abi@2.0.0`, world `plugin`) as the Rust crate. The host does not see the language. Official focus — **widget** and **alerter**.

Companion to the Rust crate — [api/13-sdk-crate](13-sdk-crate.md). Tutorial — [start/09-js-ts](../start/09-js-ts.md).

## Wiring

Sibling clone next to `modus-sdk`. In the plugin (what `modus new --lang ts` writes):

```json
{
  "dependencies": {
    "modus-sdk": "file:../../modus-sdk-js"
  }
}
```

npm registry is not required in the first iteration. Node ≥20 is required.

## Role presets

Exactly one role import path:

```ts
import { definePlugin, wait, info, uiSlot } from "modus-sdk/widget";
// or: import { … } from "modus-sdk/alerter";

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

World is always full `plugin`. Rights stay on the manifest + host deny-on-call, same as Rust.

## Toolchain

| Package | Pin |
| --- | --- |
| `@bytecodealliance/jco` | 1.37.0 |
| `@bytecodealliance/componentize-js` | 0.23.0 |

`modus pack` / `modus check` / `modus dev` invoke jco componentize with `disableFeatures`: stdio, random, clocks, http, fetch-event. Any `wasi:*` — reject. Instance memory ceiling — 16 MiB (same as Core / `dev`).

Guest sources must not rely on `fetch`, `setTimeout`, or `console` — only host `log` / `wait` / capability APIs.

## CLI

`--lang ts` | `js` — [ref/05-cli](../ref/05-cli.md), [api/11-cli-dev](11-cli-dev.md). Detect: `package.json` (JS) vs `Cargo.toml` (Rust); both at once — reject.
