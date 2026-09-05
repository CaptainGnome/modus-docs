# Roles: what to pick in `new`

If this is your first plugin — chapter goal: choose **`consumer`** and invent an `id`. Every other role in help exists and works; a beginner should not go there in part 1. Full feature × grant map — [reference](../ref/01-roles.md).

First look at what the CLI can create.

```powershell
modus new --help
```

- `modus` — the function from the [tools chapter](01-tools.md). Missing in this session — define it again.
- `new` — subcommand: **create** a plugin scaffold on disk. In this chapter we do not run it with a role yet, only help.
- `--help` — help for **this** subcommand, not the whole CLI.

You will see:

```text
Usage: modus.exe new [OPTIONS] --id <ID> <ROLE>

Arguments:
  <ROLE>  [possible values: consumer, emitter, connector, provider, widget, panel, reader, player, bridge, embedder, rates, alerter, commander, store]

Options:
      --id <ID>
      --name <NAME>
      --author <AUTHOR>
      --dir <DIR>
      --lang <LANG>
      --mode <MODE>      [possible values: native, web]
  -h, --help             Print help
```

- `<ROLE>` — positional argument: a word **without** `--`. One of the values in `possible values`. `new` knows no others.
- `--id <ID>` — required flag. Plugin identifier, not a nick and not a folder name.
- `--name` / `--author` — how the plugin is signed in the manifest. Optional: name from the last segment of `id`, author `author`.
- `--dir <DIR>` — scaffold folder. No flag — folder = last segment of `id`. Path relative to the **current** directory (`modus-sdk` clone root).
- `--lang` — do not set it: Rust anyway. Any other value — rejection `S1 Rust only`.
- `--mode` — only for `panel`: `native` or `web`.
- `[OPTIONS]` in Usage — flags are optional except those listed separately. Here `--id` is separately required.

Order: `modus new consumer --id …` and `modus new --id … consumer` — both fine.

## Where to start (part 1)

| Role | What it does | When |
| --- | --- | --- |
| `consumer` | Listens to the bus | **First plugin** |
| `emitter` | Puts canon on the bus without a platform network | After consumer; teaching source in the app |
| `connector` | Login, network via host, emit canon | After `wait`; chapter [07](07-connector.md) with `--replay` |

Listening and putting are different rights. A consumer only listens. In `dev`, teaching bus events are put by the **host** (fixture), not your code.

Reference consumer — [`modus-examples/consumer`](https://github.com/CaptainGnome/modus-examples/tree/master/consumer). You do not need to copy it: `new` writes a fresh scaffold.

## All `new` roles

Short map. Grants and details — [ref/01-roles](../ref/01-roles.md); code walkthroughs — [examples/](../examples/overview.md).

| Role | One line | Runnable |
| --- | --- | --- |
| `consumer` | listen to the bus | [`modus-examples/consumer`](https://github.com/CaptainGnome/modus-examples/tree/master/consumer) |
| `emitter` | put message/donation without a platform | [`modus-examples/emitter`](https://github.com/CaptainGnome/modus-examples/tree/master/emitter) |
| `connector` | platform via the host | [`modus-examples/connector-replay`](https://github.com/CaptainGnome/modus-examples/tree/master/connector-replay) |
| `provider` | emote catalog (`catalog.publish`) | `modus new provider` |
| `widget` | web slot, frames into the DOM | [`modus-examples/widget`](https://github.com/CaptainGnome/modus-examples/tree/master/widget) |
| `panel` | dock in Core layout (`native` / `web`) | `modus new panel` |
| `reader` | journal pages (`history.read`) | `modus new reader` |
| `player` | audio via Core (`media.audio`) | `modus new player` |
| `bridge` | OBS WebSocket (`bridge.obs`) | `modus new bridge` |
| `embedder` | foreign-origin iframe (`media.embed`) | `modus new embedder` |
| `rates` | FX table (`rates.publish`) | `modus new rates` |
| `alerter` | alert till ticket + overlay | `modus new alerter` |
| `commander` | `chat.act` (ban / timeout / …) | `modus new commander` |
| `store` | `storage.kv` | `modus new store` |

`panel` in the SDK is the same `widget` feature with a different manifest/assets. Beginner: only `consumer` until part 1 is done.

## `id`

Format — reverse-DNS (**from the end**: “whose” and “what”).

Rules (otherwise CLI: `plugin id: reverse-DNS required (com.publisher.name)`):

- at least **three** segments separated by dots: `com.you.bus`;
- lowercase `a-z`, digits, and hyphen inside a segment;
- no capitals, no `_`, no two segments.

Why not `twitch`: one word, not a namespace. The official connector is `com.modus.twitch`.

The last segment is the crate name and default folder. Changing `id` later = a **different** plugin (settings will not migrate).

Example for the next chapter: `com.you.bus` (your own second segment instead of `you`).

Check that a short id is rejected:

```powershell
modus new consumer --id twitch
```

You will see `plugin id: reverse-DNS required (com.publisher.name)`. That is chapter success.

## What not to choose now

Not `connector` without chapter 7: without `--token` the scaffold logs `no account` and waits for stop — normal, but a dead end as a first experience.

Not `emitter` / `provider` / UI / act / KV: listener and `wait` first.

Bottom line: role **`consumer`**, id like `com.you.bus`. Next chapter — [new and `dev`](03-dev.md).
