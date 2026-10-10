# JS/TS: widget without Rust in the guest

A parallel path to part 1 (Rust consumer). The host does not see the language: same ABI 2, same `check`, same `.mplug`. Official JS/TS focus — **widget** and **alerter**. Connectors stay on Rust.

Chapter outcome: `dist/*.mplug` from `modus new widget --lang ts` and a green `modus dev` without Tauri.

## What you need

- Sibling clones: [modus-sdk](https://github.com/CaptainGnome/modus-sdk), [modus-sdk-js](https://github.com/CaptainGnome/modus-sdk-js), [modus-examples](https://github.com/CaptainGnome/modus-examples) (this hub optional).
- **Node.js ≥ 20** — guest and jco. Check: `node -v`.
- A `modus` binary — from the sibling `modus-sdk` (`cargo run --manifest-path cli/Cargo.toml --release -- …`) or already installed. The Rust toolchain builds the **CLI**, not the TS guest.

```powershell
git clone https://github.com/CaptainGnome/modus-sdk.git
git clone https://github.com/CaptainGnome/modus-sdk-js.git
git clone https://github.com/CaptainGnome/modus-examples.git
cd modus-sdk
```

Use the `modus` helper from [tools](01-tools.md) or the full `cargo run … --`.

## Scaffold

From the `modus-sdk` root:

```powershell
modus new widget --lang ts --id com.example.hud --dir ..\my-hud
```

- `--lang ts` — TypeScript (primary DX). `--lang js` also works.
- JS/TS roles: only `widget` and `alerter`. Anything else — rejection `JS/TS: widget and alerter only`.
- Scaffold writes: `package.json` (`modus-sdk` → `file:` sibling `modus-sdk-js`), `guest.ts`, `manifest`, `assets/web/`, `scripts/rolldown.config.mjs`.

## `dev` and `pack`

```powershell
modus dev ..\my-hud --ui
modus pack ..\my-hud
```

The CLI runs `npm install` and jco componentize. No separate `npm run build` for the tutorial path. WASI / `wasi:*` — `check`/`pack` reject.

Ready-made dummy without your own `new`: [`modus-examples/widget-ts`](https://github.com/CaptainGnome/modus-examples/tree/master/widget-ts) — [walkthrough](../examples/14-widget-ts.md).

```powershell
modus pack ../modus-examples/widget-ts
modus dev ../modus-examples/widget-ts --ui
```

Then install `.mplug` into **shipped** Modus, same as Rust. npm façade — [api/14-sdk-js](../api/14-sdk-js.md). CLI `--lang` — [ref/05-cli](../ref/05-cli.md).
