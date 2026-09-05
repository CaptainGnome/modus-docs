# Not in this ABI

If this is your first plugin — [what you cannot](../start/04-cannot.md). If you need the ABI 2 boundary — this chapter.

**Rule.** The host loads only `"abi": 2`. An old `.mplug` with ABI 1 will not load. Below — what the guest does **not** have as a platform promise.

## Not available to the guest

- Disk and own sockets (except host KV and reading own `assets/`).
- WASI / `wasi-http` — always refuse `pack` / load.
- Settings as a plugin HTML form: Core draws the schema.
- Raw TCP to OBS/VTS bypassing `net.bridge`.
- Emit of canon `system` (Core only).
- Store/DRM (`signature.license` etc.) — later at the product; not the plugin author's path in this guide.

## Already in ABI 2 (not here)

`media.audio`, `net.bridge`, `history.read`, `media.embed`, `rates.*`, `catalog.publish`, `ui.slot`, alerts, KV, `chat.act` — see [role map](01-roles.md) and [host API](07-host-apis.md).

TTS: voice — another plugin (`media.audio` or `custom` `tts.request`), not “Core speaks”.

Next chapter — [WIT](11-wit.md).
