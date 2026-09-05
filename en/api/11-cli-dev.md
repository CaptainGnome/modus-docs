# CLI `modus`

**Rule.** `dev` builds **debug**-wasm and starts a host in the same process. `pack` — **release** + component + `.mplug`. Debug with `dev`, not “install mplug into Core”.

Compressed overview — [ref/05-cli](../ref/05-cli.md). From the [modus-sdk](https://github.com/CaptainGnome/modus-sdk) clone root:

```powershell
cargo run --manifest-path cli/Cargo.toml --release -- <command>
```

At the product root (submodule): `modus-sdk/cli/Cargo.toml`. Toolchain — [start/01-tools](../start/01-tools.md).

## Commands

| Command | Purpose |
| --- | --- |
| `new <role> --id …` | scaffold on disk |
| `dev [PATH]` | tutorial host without Tauri |
| `check [PATH]` | crate directory or `.mplug` |
| `pack [PATH]` | `dist/<name>.mplug` |
| `keygen` | Ed25519 key for signing |

`new connector` does not set `broker`, official Twitch `client_id`, or Twitch hosts. There is no `wit_bindgen::generate` in `src`.

## `modus new`

```text
modus new <role> --id <reverse.dns.name>
  [--name <str>]
  [--author <str>]
  [--dir <path>]
  [--lang rust]
  [--mode native|web]   # panel role only
```

Roles: `consumer`, `emitter`, `connector`, `provider`, `widget`, `panel` (→ feature `widget`), `reader`, `player`, `bridge`, `embedder`, `rates`, `alerter`, `commander`, `store`.

`--id` is required, reverse-DNS ≥3 segments. Default directory — last segment of id. `--lang` other than `rust` — rejected. `--mode` only for `panel`.

Grant map in the scaffold — [ref/01-roles](../ref/01-roles.md). Help for `new` matches the role list.

## `modus check`

```text
modus check [PATH]
  [--trusted-keys <file>]
```

- directory — compile component + validate manifest/assets/imports;
- `.mplug` — unpack validate + signature status (`signed` / `unsigned` / error).

## `modus pack`

```text
modus pack [PATH]
  [--sign]
  [--key-file <path>]
```

Without a key — unsigned zip. `--sign` or presence of `MODUS_SIGN_KEY` / `--key-file` — sign after pack. Details — [10-package-signing](10-package-signing.md).

## `modus keygen`

```text
modus keygen --out <path>
  [--key-id modus-dev]
  [--issuer Modus]
```

## `modus dev`

```text
modus dev [PATH]
  --inject <FILE>       JSON onto the bus instead of the tutorial fixture
  --token <STR>         fake access
  --token-file <FILE>   access from file
  --account <ID>        account id for auth.token (default dev)
  --replay <FILE>       text WS frames per line
  --http-file <FILE>    JSON responses for net.http (key = URL without query)
  --ui <FILE>           JSON → Ready::Ui
  --settings <FILE>     value overlay → Ready::Settings
  --act <FILE>          JSON act-request → Ready::Act
```

| Flag | Behavior |
| --- | --- |
| (no `--inject`) | tutorial `message` (“fixture hello”), `donation`, `reward` |
| `--inject` | events from JSON instead of fixture |
| `--token` / `--token-file` | CLI process only; not packed into the package |
| `--account` | which id `list_accounts` returns / `token` accepts |
| `--replay` | offline WS; without it one live `wss://` from `hosts` is possible |
| `--http-file` | offline Helix/HTTP |
| `--settings` | needs `assets/settings.json`; unknown key — start rejected; after `init` — `Ready::Settings` |
| `--act` | object or array; host may fill `id` / `account-id` |
| `--ui` | string or JSON → `Ready::Ui` |

`PATH` — crate directory, not `.mplug`.

In `dev`: KV and settings — RAM; `alert.enqueue` / `chat.act` — log + id (not Core queue); Ctrl+C → `Ready::Stop`.

Tutorial: [consumer](../start/03-dev.md), [connector](../start/07-connector.md).

Next chapter — [limits](12-limits.md).
