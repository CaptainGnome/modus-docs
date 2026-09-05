# Package `.mplug`

If this is your first plugin — [pack](../start/06-pack.md). If you need the zip layout — this chapter.

**Rule.** Zip. At root: `manifest`, `module.wasm`, optionally `assets/` (posix, no `..`). Other root — refuse.

| File | Contents |
| --- | --- |
| `manifest` | JSON **without** extension |
| `module.wasm` | **component**, not a core module after bare `cargo build` |
| `assets/settings.json` | settings schema; no file — no form; broken — package will not install; ≤ 32 KiB |
| `assets/i18n/{locale}.json` | flat strings; with `label.key`, `en.json` is required |
| `assets/panel.json` | native panel; HTML in texts — refuse; ≤ 32 KiB |
| `assets/panel/index.html` | panel web; together with `panel.json` — refuse |
| `assets/web/index.html` | OBS / web slot; JS/CSS ok |
| `assets/web/**` | static; no `../` |
| `assets/<platform_logo>` | platform logo; svg/png/webp/jpg ≤ 128 KiB |

`id` in the manifest is stable: reinstall with the same `id` replaces the package. Changing `id` = another plugin. KV and settings are tied to `id`.

`id` — reverse-DNS ≥3 segments. `platform_id` — short platform name, not package id.

Written by `modus pack`. Soft-link: known modus import without grant — ok; WASI / foreign — refuse. Signing — [`docs/signing.md`](../../../docs/signing.md).

Next chapter — [limits](09-limits.md).
