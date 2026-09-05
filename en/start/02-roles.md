# Roles: what to pick in `new`

If this is your first plugin — chapter goal: choose **`consumer`** and invent an `id`. Connector and Twitch — not now. If you need the full role and grant list — [reference](../README.md#reference).

First look at what the CLI can create at all.

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

- `<ROLE>` — positional argument: a word **without** `--`. One of the values in `possible values` above. `new` knows no others. Full feature × grant map — [reference](../ref/01-roles.md).
- `--id <ID>` — required flag. `<ID>` — plugin identifier, not a nick and not a folder name.
- `--name` / `--author` — how the plugin is signed in the manifest. Optional: name is taken from the last segment of `id`, author is `author`.
- `--dir <DIR>` — which folder to write the scaffold into. No flag — folder = last segment of `id`. Path is relative to the **current** directory (repo root).
- `--lang` — scaffold language. Do not set it: Rust anyway. Any other value — rejection `S1 только Rust` (S1 Rust only).
- `--mode` — only for `panel`: `native` or `web`.
- `[OPTIONS]` in Usage — “flags are optional except those listed separately”. Here `--id` is separately required.

Order: `modus new consumer --id …` and `modus new --id … consumer` — both fine. Role without `--`, id only with `--id`.

## Three roles

| Role in `new` | What it does | When to choose |
| --- | --- | --- |
| `consumer` | Listens to the bus: chat and other events | First plugin. Logic without ban and without its own platform |
| `emitter` | Also **puts** events on the bus. No platform network | Fixture, test. Not the first step |
| `connector` | Platform: login, network via host, emit canon | When you already have `dev` on a consumer and understand `wait` |

Listening and putting are different rights. A consumer only listens. Events on the bus in `dev` are put by the **host** (teaching fixture), not your code.

`new` can create every role from help (including `store`, `commander`, `alerter`, …). A beginner should not go there — start with `consumer`. More precisely — [reference](../ref/01-roles.md).

The reference consumer in the repo is [`modus-examples/consumer`](../../../modus-examples/consumer). You do not need to copy it: `new` writes a fresh scaffold.

## `id`

Format — reverse-DNS, like Android packages: **from the end** it reads “whose” and “what”.

Rules (otherwise the CLI rejects with `plugin id: нужен reverse-DNS (com.publisher.name)` (plugin id: reverse-DNS required (com.publisher.name))):

- at least **three** segments separated by dots: `com.you.bus`;
- only lowercase `a-z`, digits, and hyphen inside a segment;
- no capitals, no `_`, no two segments.

Why not `twitch`: one word, not a namespace. The official connector is `com.modus.twitch`. A short name would steal someone else's meaning and fail the check.

The last segment is the crate name and default folder. For `com.you.bus` that is `bus`. Changing `id` later = a **different** plugin (settings will not migrate). Do not touch KV yet — remember: id is stable.

Example for the next chapter: `com.you.bus`. Put your own second segment instead of `you`.

Check that a short id is rejected (does not create a folder):

```powershell
modus new consumer --id twitch
```

- `consumer` — the role you **chose**.
- `--id twitch` — deliberately wrong id.

You will see `plugin id: нужен reverse-DNS (com.publisher.name)`. That is chapter success, not a broken CLI.

## What not to choose now

Not `connector`: without a teaching token the scaffold writes “no account” and waits for stop. That is normal, but as a first experience — a dead end. Not live Twitch: network and OAuth are not needed to see `fixture hello`.

Not `emitter`: you have not looked at `wait` yet. Listener first.

Not `provider`: an emote dictionary, not the first `wait` loop.

Bottom line: role **`consumer`**, id like `com.you.bus`. Next chapter — [new and dev](03-dev.md).
