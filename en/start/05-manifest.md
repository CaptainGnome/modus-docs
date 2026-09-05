# Consumer manifest

If this is your first plugin — open the file that `new` wrote. Full field table (hosts, slots, auth) — [api/manifest](../api/00-manifest.md).

The file is named `manifest` **with no** extension. It is JSON. Path: `bus/manifest` (or the `--dir` you gave).

```powershell
Get-Content bus/manifest
```

- `Get-Content` — print the file in the terminal (you can also open it in an editor).
- `bus/manifest` — path from the repo root. Not `manifest.json`.

For the command from the [`dev` chapter](03-dev.md) you will see:

```json
{
  "id": "com.you.bus",
  "name": "bus",
  "version": "0.1.0",
  "author": "author",
  "abi": 2
}
```

- `id` — who this plugin is to the host. Reverse-DNS, as in `new --id`. Changing `id` = a **different** plugin: reinstall will not continue old settings. Do not rename “for looks”.
- `name` — human name in the list. You can change it. Default — last segment of `id` (`bus`). Do not confuse with `id`.
- `version` — version of **your** package (`0.1.0`, then `0.1.1`, …). Not the language version with the host.
- `author` — author signature. Default string `author` if `new` had no `--author`.
- `abi` — language version between plugin and app. Currently only **`2`**. This is not the package `version`. Do not set `1` and do not bump “just in case”.

Five fields total. That is how it should be.

No `capabilities` — fine. Listening to the bus needs no rights list. Do not copy into a consumer someone else's manifest with `hosts`, `auth_mode`, and `client_id`: that is a connector; network will not appear from that, and `pack` will start requiring imports the scaffold does not have.

Do not add `client_secret`. A secret in the manifest — rejection.

You may fix `name` and `author`, save, run `modus dev bus` again — the first `dev …` log line keeps the same `id`; the name in the Core UI you will see when installing the `.mplug`.

More precisely on the other fields — [manifest (api)](../api/00-manifest.md).

Next chapter — [pack `bus` into a `.mplug`](06-pack.md).
