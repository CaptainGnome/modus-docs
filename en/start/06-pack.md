# Pack and install

If this is your first plugin — get to a `.mplug` file on disk. The Core window is the last check, not a debugging method. If you need the zip and package fields table — [reference](../README.md#reference).

Commands — from the repo root. The `modus` function — [tools chapter](01-tools.md).

## Pack

```powershell
modus pack bus
```

- `pack` — build **release** wasm, check rights, write the package. This is not `dev`: a different profile, no teaching host, no `fixture hello` in the terminal.
- `bus` — `[PATH]`: crate directory, same as `dev`. Not a `.mplug` file.

You will see `packed bus\dist\bus.mplug` (on Windows the slash may be `\`). File name = **directory** name, not `id`.

Inside the zip two required files:

- `manifest` — the same passport as in `bus/manifest`;
- `module.wasm` — the component (not “raw” wasm after a manual `cargo build`). Build is **release**, not debug from `dev`.

The consumer scaffold has no `assets/` folder — it will not be in the zip. That is how it should be.

No file after an error — `pack` does not write one. Common texts: `Нужен target wasm32-unknown-unknown` (Need target wasm32-unknown-unknown), `cargo build не удался` (cargo build failed), no `manifest`. Fix the cause; do not copy someone else's `.mplug`.

Token and `inject.json` do **not** go into the package. Only what is in the crate directory (manifest, wasm, `assets/`) goes in.

## Check is not required separately

`pack` itself runs the same check as `check`. Without success there is no file.

If you want to check an already built package:

```powershell
modus check bus/dist/bus.mplug
```

- `check` — read manifest and wasm, match imports to rights. Runs nothing.
- `bus/dist/bus.mplug` — path to the package. You can pass a crate directory (`bus`) — then the CLI rebuilds wasm itself and checks it.

Success: `ok com.you.bus …`. Rejection — on stderr; pack does not touch the file.

## Install in Core

Debugging is still [`modus dev`](03-dev.md). The window is needed to see the package in the list, like a streamer.

The app is not the plugin. For the window you need Node (dependencies once, then the Tauri script):

```powershell
npm install
npm run tauri dev
```

- `npm install` — download dependencies from the root `package.json` into `node_modules`. Not needed for wasm builds; needed for the window.
- `npm run` — run a script from `package.json`.
- `tauri` — script name: the app CLI.
- `dev` — start Core in development mode. First time is long.

In the header: **Установить плагин** (Install plugin) (or in the “Плагины” (Plugins) window → “Установить” (Install)). Choose `bus\dist\bus.mplug`. Or drag the `.mplug` onto the window.

The **Разрешить плагин?** (Allow plugin?) dialog will show name, id, version, author. For a consumer the rights are “только базовый API” (basic API only). No host list: there is no network in the manifest. Confirm.

The package should appear in “Плагины” with status “работает” (running). Guest log — the **Логи** (Logs) button.

An empty feed with only a consumer — **not a bug**. A listener does not put events on the bus. In `dev` the teaching host did. In Core you need a source: a fixture from the repo or an already installed Twitch.

Fixture:

```powershell
modus pack plugins/fixture
```

- `plugins/fixture` — the reference emitter directory in the repo, not your `bus`.

Also install `plugins\fixture\dist\fixture.mplug`. Then fixture events appear in the consumer log (in `dev` that was the `fixture hello` text; in Core the source is this package). Only your `.mplug` without a source — silence; the scaffold is alive.

Do not debug `lib.rs` edits by installing the package. Again `modus dev bus`, and only then `pack`.

Part 1 closes here: consumer in `dev` and a `.mplug` file. Next chapter — [connector](07-connector.md), optional; or [next steps](08-next.md).
