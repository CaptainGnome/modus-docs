# Install tools

If this is your first plugin — run the PowerShell commands one by one and read **what each word does**. Copying is fine; blind copying is not. If the toolchain is already installed and you need the contract — [reference](../README.md#reference).

Chapter outcome: CLI help on screen; the command list includes `new`, `check`, `pack`, `dev`.

## Rust

If `rustc` already responds — skip this step.

Install [rustup](https://rustup.rs/) (the official Rust installer: compiler, `cargo`, targets). After install **close and reopen** PowerShell — otherwise the system will not see the new programs.

Check:

```powershell
rustc -vV
```

- `rustc` — the Rust compiler.
- `-vV` — print the version in detail (lines `release:`, `host:`).

You will see `release:` (currently the 1.9x line) and `host: x86_64-pc-windows-msvc`. You need **stable**, not nightly.

If rustup asks for Visual Studio Build Tools — install them. Without them `cargo` on Windows will not build the CLI.

## Wasm target

A plugin builds not to an `.exe`, but to a sandbox module. A target is “which machine to compile for”.

```powershell
rustup target add wasm32-unknown-unknown
```

- `rustup` — the toolchain manager (what you installed from rustup.rs).
- `target` — the subcommand about compile targets.
- `add` — download and enable the target.
- `wasm32-unknown-unknown` — target name: `wasm32` = 32-bit WebAssembly; two `unknown`s = no “vendor” and **no operating system** for the guest.

Check:

```powershell
rustup target list --installed
```

- `list` — show targets.
- `--installed` — only ones already on the machine, not the full rustup catalog.

The list must contain the line `wasm32-unknown-unknown`. If it is missing — `dev` and `pack` will later fail with `Нужен target wasm32-unknown-unknown` (Need target wasm32-unknown-unknown). Catch it here, not there.

**Important.** This target does not give the guest files or sockets (in wasm that is called WASI). Otherwise the sandbox could be bypassed. More precisely — [reference](../README.md#reference).

## Repository

The SDK is not on crates.io yet. The CLI (`modus-sdk/cli`) and the `modus-sdk` crate (`modus-sdk/guest`) live in the product tree next to this documentation. Docs are the `modus-docs/` directory (this text).

Commands below are **from the tree root** where `modus-sdk/`, `plugins/`, and `modus-docs/` sit side by side. If docs are a submodule, that root is the parent of `modus-docs/`.

```powershell
cd path\to\product-root
```

At the root there is `rust-toolchain.toml`: rustup will pick stable and the same wasm target itself. The `target add` step is still required — so the target exists before the first long build.

## CLI

The first run builds `modus` for several minutes. That is normal, not “hung”.

```powershell
cargo run --manifest-path modus-sdk/cli/Cargo.toml --release -- --help
```

- `cargo` — the Rust builder: reads `Cargo.toml`, compiles, runs.
- `run` — build the binary and run it immediately.
- `--manifest-path modus-sdk/cli/Cargo.toml` — do not look for a package in the current folder; take the CLI manifest. Path is **relative**: you stand at the repo root; the file is `modus-sdk/cli/Cargo.toml`.
- `--release` — optimized build of **the CLI itself** (not the plugin). Without the flag every call is debug and a different file.
- `--` — everything to the right is **not** cargo flags, but arguments to the `modus` program. Without this, `--help` shows cargo help, not modus.
- `--help` — already modus: print the subcommand list and exit.

You will see something like:

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

- `Usage: modus.exe <COMMAND>` — how to run: program name, then one subcommand. On Windows often `.exe`.
- `new` / `check` / `pack` / `dev` — CLI subcommands. Missing from the output — you are not at the repo root or the build failed (error text is **above** help).

To avoid dragging the long line, for **this** PowerShell session:

```powershell
function modus { cargo run --manifest-path modus-sdk/cli/Cargo.toml --release -- @args }
modus --help
```

- `function modus { … }` — give a short name to a long command. Lives while this PowerShell stays open.
- `@args` — pass to cargo everything you wrote after `modus`. So `modus --help` = `cargo run … -- --help`, and later `modus new …` = `cargo run … -- new …`.
- The second `--` inside the function is already there: your words go as **modus** arguments, not cargo.

Further in the tutorial `modus` means this function until the CLI is a separate program on PATH. Session closed — define the function again or write the full `cargo run …`.

Next chapter — [roles in `new`](02-roles.md).
