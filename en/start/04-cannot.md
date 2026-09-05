# What a plugin cannot do

If this is your first plugin — remember the bans while `dev` is still green. If you need the limits table and host errors — [reference](../introduction.md#reference).

A plugin is a guest in a sandbox. It does not get its own disk, socket, or OS window. Everything allowed is only an SDK call, and only if the manifest permitted it. A manifest entry without a call in code is fine. A call without an entry — `pack` will refuse, the package will not load.

A part-1 consumer has no network, UI slot, or journal access. Other roles (`widget`, `panel`, `reader`, `player`, `bridge`, …) grant those capabilities — after the tutorial, via a different `new` and a grant.

## Bans

**Open a file on the streamer's disk.** The guest has no filesystem. `std::fs`, reading `C:\…`, writing next to the `.exe` — will not work. Secrets and chat live in Core, not in wasm. Package assets — only via `assets.read` / slots, not an arbitrary path.

**Open TCP or UDP yourself.** The guest has no sockets. You cannot listen on a port and cannot `TcpStream` to Twitch. Network is the host outlet (`net.http` / `net.ws`), and not for a consumer.

**Do `fetch` like in a browser.** Plugin wasm has no browser `fetch` and no `reqwest` “straight to the internet”. HTTPS only through the host, if the role and manifest gave it. Right now you have a consumer — no network.

**Create an OS window.** A plugin does not open Windows windows. The streamer app draws the feed. Guest UI is only roles with a slot (`ui.slot`: widget / panel / …), not `consumer`.

**Expect backlog from `wait`.** After `subscribe`, `wait` delivers only **new** letters. Older journal pages — role `reader` and grant `history.read`, not the consumer scaffold.

**Emit `system`.** Service messages are written only by Core. Even a connector with the right to put events on the bus gets rejection `system is Core-only`. A consumer has not reached emit yet — and should not.

**Put a password in the log.** Do not write a token, `bearer`, or `client_secret` in `log::log`. The host will replace some strings with `[redacted]`, but that is a safety net, not a place for secrets. The secret is not in wasm and not in `inject.json`.

## What follows

The `new consumer` scaffold is already inside these bounds: `subscribe`, `wait`, log. Do not add files, sockets, and HTTP “to check”. The check is `modus dev`; the host puts the bus.

More precisely on limits, grants, and error strings — [reference](../introduction.md#reference).

Next chapter — [open the generated `manifest`](05-manifest.md).
