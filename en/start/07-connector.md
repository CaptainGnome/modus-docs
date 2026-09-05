# Connector: replay without a live platform

If the consumer is already green — here is a teaching connector: a fake token and frames from a file. Live Twitch and the Core window are not needed. If you need OAuth and `hosts` in detail — [network and auth](../ref/06-net-auth.md).

Commands — from the **repo root**. The `modus` function — [tools](01-tools.md).

## Scaffold

```powershell
modus new connector --id com.you.mine --dir mine
```

- `connector` — role: login via host, network, emit canon.
- `--id com.you.mine` — your own second segment instead of `you`.
- `--dir mine` — scaffold folder.

The manifest will have `auth_mode`, a stub `client_id`, `hosts: ["example.com"]`. The official Twitch `client_id` and CLI broker are **not** injected.

## Replay in `dev`

Create `mine/frames.replay` (one line = one WS text frame):

```text
hello-dev
```

Run:

```powershell
modus dev mine --token fake --replay mine/frames.replay
```

- `--token fake` — fake access in the CLI process. Not the Core vault; does not go into `.mplug`.
- `--replay` — the host returns file lines as `Ready::WsText`, without a live `wss://`.

After `token` the scaffold connects to `wss://example.com/` (from code), but with `--replay` the socket is teaching: frames from the file. The plugin emits a message on the bus — the frame text appears in the terminal (for example `hello-dev`).

Ctrl+C — `Ready::Stop`. Do not swallow `"остановлен"` (stopped) / `HostError::is_stop()` into reconnect: the scaffold calls `wait_backoff`, stop leaves the loop.

Without `--replay` the CLI may open one live `wss://` from the manifest `hosts` (not private). For the first time replay is enough.

`--http-file` — JSON responses for offline `net.http` (key = URL without query). Need Helix/API without network — see [`modus-sdk/cli/tests/fixtures`](../../../modus-sdk/cli/tests/fixtures) and the reference [`plugins/twitch`](../../../plugins/twitch).

## What not to touch in this chapter

`--settings` / `--act` / `--ui` — [CLI reference](../ref/05-cli.md), not tutorial 0–6.

Live OAuth and installing a `.mplug` into the app are not a way to debug a connector. First `dev` with replay.

Next chapter — [next steps](08-next.md).
