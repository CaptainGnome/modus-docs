# First success: consumer and `dev`

If this is your first plugin — get to the `fixture hello` line in the terminal. The streamer app is not needed. If you need the `wait` and canon contract — [reference](../README.md#reference).

Commands — from the **repo root**. The `modus` function — [tools chapter](01-tools.md). Do not `cd bus`: `--manifest-path` inside the function is relative and will break.

## Create the scaffold

```powershell
modus new consumer --id com.you.bus --dir bus
```

- `new` — write the scaffold to disk, do not run the plugin.
- `consumer` — role. Why — [previous chapter](02-roles.md).
- `--id com.you.bus` — identifier in the manifest. Your own second segment instead of `you`.
- `--dir bus` — scaffold folder relative to the repo root. Without the flag the folder would still be `bus` (last segment of id); the flag makes it explicit.

You will see `created bus`. Inside:

- `bus/manifest` — plugin passport;
- `bus/Cargo.toml` — how to build;
- `bus/src/lib.rs` — your code;
- `bus/.gitignore` — do not commit `target/`.

Folder already exists and is not empty — rejection `bus уже существует` (bus already exists). Pick another `--dir` (and align the last segment of `--id` if you want the names to match).

## Run `dev`

```powershell
modus dev bus
```

- `dev` — build the plugin and start a **teaching host in the same process**. The Core window does not open.
- `bus` — `[PATH]`: crate directory, not a `.mplug` file and not `src/lib.rs`.

The first time it builds **debug** wasm. That is not the module that later goes into `.mplug`. It may take minutes — that is the build, not “chat broke”.

What `dev` does, briefly:

1. builds wasm from `bus/`;
2. starts the host in the CLI;
3. calls `init`, then puts two teaching events on the bus: a `fixture hello` message and a donation;
4. runs your `run` until you press Ctrl+C.

You will first see `dev com.you.bus 0.1.0`, then guest log `init`, then host lines `emit … fixture hello`, then the plugin log with the same text — like `bus message fixture:dev … fixture hello`.

Look for the **second** `fixture hello` phrase: the host dropped a letter, the plugin read it. There is `emit`, no `bus message` — `subscribe` did not work or wasm never reached `run`. No `fixture hello` at all after the build finishes — wrong directory or the build failed (error **above** the log).

Ctrl+C — the host wakes with `Ready::Stop`, the process exits. That is a normal exit, not a crash.

Other `modus dev --help` flags are not needed in this chapter:

- `--inject` — your own JSON onto the bus, a bit below;
- `--token`, `--token-file`, `--account`, `--replay`, `--http-file` — connector, leave them alone;
- `--ui`, `--settings`, `--act` — reference (widget / store / act).

## What `new` wrote in `lib.rs`

Open `bus/src/lib.rs`. Do not paste someone else's sample and do not copy [`plugins/consumer`](../../../plugins/consumer) — look at the **generated** file.

The host calls three functions in order. In the generated file it is the same without these comments — the meaning is:

```rust
// Guest — contract with the host: init, run, and shutdown must exist.
impl Guest for Plugin {
    fn init() {
        // Short startup. The host calls this first, before run.
        log::log(Level::Info, "init");
        // “Put bus letters in my mailbox”. Without subscribe the wait loop will not see the bus.
        // Subscribe right here: dev puts teaching events right after init.
        // If you call subscribe only in run — the mailbox is still closed, letters are dropped.
        wait::subscribe();
    }

    fn run() {
        // The only long loop. You call wait — the plugin sleeps, the host wakes it.
        loop {
            match wait::wait() {
                // Normal exit: Ctrl+C in dev, off in Core. No other return from the loop.
                Ready::Stop => return,
                // Foreign event from the bus (fixture, inject, connector). log_bus prints the text.
                Ready::Bus(event) => log_bus(&event),
                // Ignore for now: no socket, timer, or commands for a consumer in dev.
                // Resume — only after Windows sleep in Core; not emulated in dev.
                Ready::WsText(_)
                | Ready::WsClosed(_)
                | Ready::Timer
                | Ready::Act(_)
                | Ready::Settings
                | Ready::Resume => {}
            }
        }
    }

    // Host calls after run. Empty for now — leave it that way.
    fn shutdown() {}
}

// Register Plugin as the guest. Do not delete. Name in parentheses = struct Plugin.
modus_sdk::export!(Plugin);

// Below in the file — log_bus, payload_kind, payload_text. Print text only; for
// first success do not touch them.
```

## Your own text: `--inject`

Without the flag `dev` itself puts `fixture hello` and a donation. `--inject` **replaces** that pair with your file: one object is enough.

Create `bus/inject.json` (not JSONL, not an array):

```json
{
  "type": "message",
  "user_id": "you",
  "display_name": "you",
  "fragments": [{ "type": "text", "text": "hello from me" }]
}
```

- `type` — event kind on the bus. For now only `message`.
- `user_id` / `display_name` — who “wrote”. For the consumer log the text matters more.
- `fragments` — body pieces, not HTML. `type: text` + `text` — a plain string.

Run:

```powershell
modus dev bus --inject bus/inject.json
```

- `--inject` — take events from the file instead of the built-in fixture.
- `bus/inject.json` — path **relative to the repo root** (where you stand), not automatically relative to `bus/`.

The log should show a `hello from me` line. Change `text`, save, `dev` again — you will see the new text. No line — typo in JSON or wrong file path (CLI will write `inject: …`).

Ctrl+C, as before.

Next chapter — [what a plugin cannot do](04-cannot.md), even when `dev` is already green.
