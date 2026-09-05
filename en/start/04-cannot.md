# What a plugin cannot do

If this is your first plugin — remember the bans while `dev` is still green. If you need the limits table and host errors — [reference](../README.md#reference).

A plugin is a guest in a sandbox. It does not get its own disk, socket, or window. Everything allowed is only an SDK call, and only if the manifest permitted it. A manifest entry without a call in code is fine. A call without an entry — `pack` will refuse, the package will not load.

Panel, chat history, sound, bridges — **not available in a plugin**. Not “later in this chapter”.

## Bans

**Open a file on the streamer's disk.** The guest has no filesystem. `std::fs`, reading `C:\…`, writing next to the `.exe` — will not work. Secrets and chat live in Core, not in wasm.

**Open TCP or UDP yourself.** The guest has no sockets. You cannot listen on a port and cannot `TcpStream` to Twitch. Network is the host outlet (`net.http` / `net.ws`), and not for a consumer.

**Do `fetch` like in a browser.** Plugin wasm has no browser `fetch` and no `reqwest` “straight to the internet”. HTTPS only through the host, if the role and manifest gave it. Right now you have a consumer — no network.

**Draw a window.** A plugin does not create UI. The streamer app draws the feed. The guest writes to the log and listens to the bus.

**Learn chat history before subscribe.** The journal is in Core. `wait` after `subscribe` gives only new letters. Old messages from a file or database are not given to the guest.

**Emit `system`.** Service messages are written only by Core. Even a connector with the right to put events on the bus gets rejection `system только Core` (system Core only). A consumer has not reached emit yet — and should not.

**Put a password in the log.** Do not write a token, `bearer`, or `client_secret` in `log::log`. The host will replace some strings with `[redacted]`, but that is a safety net, not a place for secrets. The secret is not in wasm and not in `inject.json`.

## What follows

The `new consumer` scaffold is already inside these bounds: `subscribe`, `wait`, log. Do not add files, sockets, and HTTP “to check”. The check is `modus dev`; the host puts the bus.

More precisely on limits, grants, and error strings — [reference](../README.md#reference).

Next chapter — [open the generated `manifest`](05-manifest.md).
