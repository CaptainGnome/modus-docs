# Package `.mplug` and signing

**Rule.** `.mplug` is a zip. At the root: `manifest`, `module.wasm`, optional `assets/` (posix, no `..`) and optional `signature`. Any other root — rejected. Written by `modus pack`.

Compressed layout — [ref/08-package](../ref/08-package.md). Full signing policy — [`docs/signing.md`](../../../docs/signing.md) in the Modus checkout (from submodule `modus-docs`: `../docs/signing.md` from the docs-repo root; from this chapter — `../../../docs/signing.md`).

## Zip layout

| Path | Contents |
| --- | --- |
| `manifest` | JSON **without** extension |
| `module.wasm` | WIT **component** (not bare core after `cargo build`) |
| `assets/settings.json` | settings schema; no file — no form; broken — not installed; ≤ 32 KiB |
| `assets/i18n/{locale}.json` | flat strings; with `label.key`, `en.json` is required |
| `assets/panel.json` | native panel; HTML in texts — rejected; ≤ 32 KiB |
| `assets/panel/index.html` | panel web; together with `panel.json` — rejected |
| `assets/web/index.html` | OBS / web slot |
| `assets/web/**` | static; no `../` |
| `assets/<platform_logo>` | platform logo; svg/png/webp/jpg ≤ 128 KiB |
| `signature` | optional; **not** part of the digest |

`id` in the manifest is stable: reinstall with the same `id` replaces the package. KV and settings are bound to `id`.

## Build

`pack`:

1. release-wasm (`opt` as in references);
2. wrap into component;
3. soft-link imports (known modus without grant — ok; WASI / foreign — rejected);
4. zip → `dist/<name>.mplug`.

Without a successful `check` there is no file. In one crate `modus-sdk` + `wit_bindgen::generate` in `src` — rejected: `WIT вручную плюс SDK — два bindgen`.

## Signing (for the author)

Optional. Canonical SHA-256 of all zip entries **except** `signature`, Ed25519 over the raw digest.

`signature` file (v1): `alg`, `key_id`, `digest`, `sig`. Field `license` is reserved (store/DRM later).

```powershell
modus keygen --out modus.key
modus pack --sign --key-file modus.key
modus check path\to\plugin.mplug --trusted-keys trusted_keys.json
```

Variable `MODUS_SIGN_KEY` — path to the key (equivalent to `--key-file` for pack).

| Status | Install |
| --- | --- |
| Unsigned | from disk ok, UI warns; OAuth via broker unavailable |
| Invalid | install rejected |
| Verified | broker / strict policies |

Trusted keys and revoke — in [`docs/signing.md`](../../../docs/signing.md). Files `plugins/{id}/inject/` in Core are **not** in the digest (overlay themes).

Next chapter — [CLI](11-cli-dev.md).
