# CLI `modus`

If this is your first plugin — commands in the [tutorial](../start/01-tools.md). If you need the flag map — this chapter.

**Rule.** `dev` builds **debug** wasm and raises the host in the same process. `pack` — **release** + component + `.mplug`. Debug with `dev`, not “install mplug in Core”.

## Commands

| Command | Purpose |
| --- | --- |
| `new <role> --id …` | scaffold on disk |
| `dev [PATH]` | tutorial host without Tauri |
| `check [PATH]` | directory or `.mplug` |
| `pack [PATH]` | `dist/<name>.mplug` |
| `keygen` / `pack --sign` | signing (see [`docs/signing.md`](../../../docs/signing.md)) |

CLI from [modus-sdk](https://github.com/CaptainGnome/modus-sdk) (not on crates.io yet). From the clone root:

```powershell
cargo run --manifest-path cli/Cargo.toml --release -- <command>
```

At the product root (submodule): `modus-sdk/cli/Cargo.toml`. Or the `modus` function from the [tutorial](../start/01-tools.md).

`new connector` does not set `broker`, the official Twitch `client_id`, or Twitch hosts. No `wit_bindgen::generate` in `src`. Two bindgens (SDK + `generate` in one crate) — `pack`/`check` refuse.

## `modus dev`

```text
modus dev [PATH]
  --inject <FILE>       JSON onto the bus instead of the tutorial fixture
  --token <STR>         fake access (or --token-file)
  --account <ID>        account id for auth.token (default dev)
  --replay <FILE>       text WS frames line by line
  --http-file <FILE>    JSON net.http responses (key = URL without query)
  --ui <FILE>           JSON → Ready::Ui
  --settings <FILE>     value overlay → Ready::Settings
  --act <FILE>          JSON act-request → Ready::Act
```

- Without `--inject` — tutorial `message` (“fixture hello”), `donation`, `reward`.
- `--token` / `--token-file` — CLI process only; not packed.
- `--replay` — offline WS; without it one live `wss://` from `hosts` is possible (not private).
- `--settings` — needs `assets/settings.json`; unknown key — refuse at start; after `init` one `Ready::Settings`.
- `--act` — object or array; host may fill `id` / `account-id`.
- `--ui` — string or JSON → `Ready::Ui` (widget / slot).

In `dev`: KV and settings — RAM per process; `alert.enqueue` / `chat.act` — log + id to stderr (not Core queue and not park to a neighbor wasm). Ctrl+C → `Ready::Stop`.

Tutorial: [consumer](../start/03-dev.md), [connector](../start/07-connector.md).

## `pack` / `check`

`pack` itself builds release wasm, wraps as a component, soft-links imports. No file without a successful `check`. WASI / foreign import — refuse. Known modus import without grant in the manifest — soft-link ok; call without cap is cut by the host.

Next chapter — [network and auth](06-net-auth.md).
