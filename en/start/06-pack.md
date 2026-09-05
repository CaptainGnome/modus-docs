# Pack and install

If this is your first plugin — get to a `.mplug` file on disk. Installing into the app is the last check, not a debugging method. If you need the zip and package fields table — [reference](../README.md#reference).

Commands — from the `modus-sdk` clone root. The `modus` function — [tools chapter](01-tools.md). Keep [modus-examples](https://github.com/CaptainGnome/modus-examples) nearby.

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

No file after an error — `pack` does not write one. Common texts: `Need target wasm32-unknown-unknown` (Need target wasm32-unknown-unknown), `cargo build failed` (cargo build failed), no `manifest`. Fix the cause; do not copy someone else's `.mplug`.

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

## Install in Modus

Debugging is still [`modus dev`](03-dev.md). To see the package in the list like a streamer, you need the **shipped** Modus app — not a product checkout and not `npm` / `tauri`.

1. Open Modus.
2. In the header: **Install plugin** (or “Plugins” → “Install”). Choose `bus\dist\bus.mplug`. Or drag the `.mplug` onto the window.
3. The **Allow plugin?** dialog shows name, id, version, author. For a consumer the rights are “basic API only”. No host list: there is no network in the manifest. Confirm.

The package should appear in “Plugins” with status “running”. Guest log — the **Logs** button.

An empty feed with only a consumer — **not a bug**. A listener does not put events on the bus. In `dev` the teaching host did. In the app you need a source: the educational emitter or an already installed platform connector.

Bus source (educational emitter from [modus-examples](https://github.com/CaptainGnome/modus-examples)):

```powershell
modus pack ../modus-examples/emitter
```

- path — from the `modus-sdk` clone root when `modus-examples` is a sibling.

Also install `..\modus-examples\emitter\dist\emitter.mplug`. Then events appear in the consumer log (in `dev` that was the `fixture hello` text; here the source is the emitter package). Only your `.mplug` without a source — silence; the scaffold is alive.

Do not debug `lib.rs` edits by installing the package. Again `modus dev bus`, and only then `pack`.

Part 1 closes here: consumer in `dev` and a `.mplug` file. Next chapter — [connector](07-connector.md), optional; or [next steps](08-next.md).
