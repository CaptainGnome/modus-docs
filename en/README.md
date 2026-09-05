# Modus plugins

**Languages:** [English](README.md) · [Русский](../ru/README.md)

Documentation of the **guest surface** (ABI 2): what a wasm plugin sees through [`modus-sdk`](https://github.com/CaptainGnome/modus-sdk) and the `modus` CLI. Core appears only as short concepts (“Core stamps bus events”, “Core parks `chat.act`”, “alert till is Core”). No chapters on the broker internals, feed filters, hot-swap, or React chrome.

**Public repositories:** this hub — [modus-docs](https://github.com/CaptainGnome/modus-docs); SDK/CLI/WIT — [modus-sdk](https://github.com/CaptainGnome/modus-sdk); educational dummies — [modus-examples](https://github.com/CaptainGnome/modus-examples). Annotated walkthroughs — [examples/](examples/README.md). Closed product `plugins/*` are not part of the public path.

Author path: SDK → `new` → `dev` → `pack` → install `.mplug` into the **shipped** Modus app. Language — Rust. Do not put secrets in the package.

## Tutorial

For someone who can paste a command into PowerShell. You do not need to know WASM or capabilities first.

| | Chapter | Outcome |
| --- | --- | --- |
| 0 | [Who this is for and what to expect](start/00-intro.md) | clear what a plugin is not |
| 1 | [Tools](start/01-tools.md) | `modus --help` on screen |
| 2 | [Roles](start/02-roles.md) | picked `consumer`, not Twitch |
| 3 | [First `dev`](start/03-dev.md) | `fixture hello` in the terminal |
| 4 | [What you must not do](start/04-cannot.md) | list of bans |
| 5 | [Consumer manifest](start/05-manifest.md) | opened the generated `manifest` |
| 6 | [Pack](start/06-pack.md) | file `dist/*.mplug` |
| 7 | [Connector](start/07-connector.md) (optional) | frame replay without a live platform |
| 8 | [Next](start/08-next.md) | checklist and links |

Part 1 is chapters 0–6 and 8. Chapter 7 is optional.

## Reference

Compact contract: rule → consequence → reference plugin. Read from the table of contents.

| | Chapter | Rule |
| --- | --- | --- |
| 0 | [Contract](ref/00-contract.md) | SDK + manifest + CLI; do not copy WIT |
| 1 | [Role map](ref/01-roles.md) | feature preset + manifest; soft-link; deny on call |
| 2 | [Lifecycle and `wait`](ref/02-wait.md) | in `run` only `wait`; stop is not reconnect |
| 3 | [Bus canon](ref/03-canon.md) | Core stamps; `system` only from Core |
| 4 | [Host errors](ref/04-errors.md) | `HostError::classify`, do not parse strings by eye |
| 5 | [CLI](ref/05-cli.md) | `dev` debug, `pack` release; `--settings` / `--act` / `--ui` |
| 6 | [Network and auth](ref/06-net-auth.md) | OAuth shell is Core; secret not in wasm |
| 7 | [Settings, KV, act, alerts, slots](ref/07-host-apis.md) | grant + ceilings; `dev` vs Core |
| 8 | [`.mplug` package](ref/08-package.md) | zip: `manifest` + `module.wasm` + posix `assets/` |
| 9 | [Limits](ref/09-limits.md) | one table |
| 10 | [Not in this ABI](ref/10-not-in-abi.md) | ABI 2 boundary |
| 11 | [WIT](ref/11-wit.md) | appendix; author path does not copy it |

## API (full guest surface)

Reference depth: fields, tables, call semantics. Core only enough to understand the call.

| | Chapter |
| --- | --- |
| 0 | [Manifest](api/00-manifest.md) |
| 1 | [Lifecycle and `wait`](api/01-lifecycle-wait.md) |
| 2 | [Bus canon](api/02-canon-bus.md) |
| 3 | [Host errors](api/03-errors.md) |
| 4 | [Base host APIs](api/04-base-host.md) |
| 5 | [Emit, auth, network](api/05-emit-auth-net.md) |
| 6 | [KV, act, alerts](api/06-kv-act-alerts.md) |
| 7 | [Slots and panel](api/07-ui-slots-panel.md) |
| 8 | [Media: cache, audio, embed](api/08-media-cache-audio-embed.md) |
| 9 | [Bridge, history, rates, catalog](api/09-bridge-history-rates-catalog.md) |
| 10 | [Package and signing](api/10-package-signing.md) |
| 11 | [CLI](api/11-cli-dev.md) |
| 12 | [Limits](api/12-limits.md) |
| 13 | [Crate `modus-sdk`](api/13-sdk-crate.md) |

## Examples

Walkthroughs of reference plugins: manifest + key code with comments.

| | Chapter | Reference |
| --- | --- | --- |
| — | [table of contents](examples/README.md) | |
| 0–13 | consumer … rates | [`examples/`](examples/README.md) |
