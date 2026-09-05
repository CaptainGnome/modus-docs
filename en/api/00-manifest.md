# Manifest

**Rule.** The `manifest` file (no extension) is JSON at the crate root and at the `.mplug` root. The host reads it before wasm. No field — no right, except the base. `client_secret` in the manifest — always rejected.

Scaffold is written by `modus new`. Full check — `modus check` / `pack`. References: [`plugins/twitch`](../../../plugins/twitch), [`plugins/web-slot`](../../../plugins/web-slot), [`plugins/7tv`](../../../plugins/7tv).

## Required fields

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | reverse-DNS ≥3 segments, ≤128 characters (`com.publisher.name`). Changing `id` = a different plugin (KV/settings are not migrated). Short `twitch` — rejected: `plugin id: нужен reverse-DNS …` |
| `name` | string **or** `{ "key", "fallback" }` | name in UI. Plain — as-is; key — i18n (see below) |
| `version` | string | **package** version (`0.1.0`), not ABI |
| `author` | string | author credit |
| `abi` | number | only **`2`**. Otherwise: `ABI N не поддерживается (нужен 2)` |

Minimum consumer:

```json
{
  "id": "com.you.bus",
  "name": "bus",
  "version": "0.1.0",
  "author": "author",
  "abi": 2
}
```

## Capabilities

Array of strings. Empty / absent — base only (`wait`, settings, assets, log, …). WIT import without a grant — soft-link ok; call without cap — `нет гранта …`.

| Capability | Purpose |
| --- | --- |
| `bus.emit` | put canon on the bus; **requires** non-empty `platform_id` |
| `auth.token` | `list-accounts` / `token`; required for any `auth_mode` |
| `net.http` | HTTPS through the host |
| `net.ws` | WSS through the host |
| `alert.enqueue` | ticket into the alert cashier |
| `storage.kv` | private instance KV |
| `chat.act` | send/delete/timeout/ban/unban |
| `ui.slot` | wasm ↔ web/panel channel; **requires** `slots` |
| `media.cache` | pin URL/bytes in Core cache |
| `media.audio` | play/stop sound |
| `media.embed` | iframe allowlist + `embed_hosts` |
| `catalog.publish` | dictionary snapshot (emotes, etc.) |
| `history.read` | journal pages (not `wait` replay) |
| `bridge.obs` | OBS invoke; type list — `bridge_requests` |
| `rates.publish` | FX rate table |
| `rates.convert` | convert → Core base currency |

Role × grant × reference map — [ref/01-roles](../ref/01-roles.md).

## `platform_id` / `platform_logo`

| Field | Rule |
| --- | --- |
| `platform_id` | short platform name (`twitch`), **not** package `id`. Required with `bus.emit` and with any `auth_mode`. One live plugin per value; second — `platform_id … уже занят` |
| `platform_logo` | path **relative** to `assets/` (no `assets/` prefix, no `..`, no `\`). Extensions: svg/png/webp/jpg. Requires `platform_id`. File ≤ 128 KiB |

## `slots` / `user_theme`

| Field | Rule |
| --- | --- |
| `slots` | `"web"` and/or `"panel"`. Duplicate / unknown slot — rejected. Slots without `ui.slot` — `slots требуют грант ui.slot`. Grant without slot — `ui.slot требует слот web или panel` |
| `user_theme` | `true` — streamer may overlay a theme zip on web/panel. Requires `ui.slot` and a web or panel slot |

Assets: web — `assets/web/`; panel native — `assets/panel.json`; panel web — `assets/panel/` **or** the same `assets/web/`. Both `panel.json` and `panel/index.html` — rejected. Details — [07-ui-slots-panel](07-ui-slots-panel.md).

## Network hosts

| Field | Rule |
| --- | --- |
| `hosts` | DNS allowlist for `net.http` / `net.ws` and auth URLs. Format: hostname or `host:port`. Intersection with Core whitelist. Literal IP / private — rejected at call time |
| `embed_hosts` | iframe allowlist (`media.embed`). Empty + no cap — CSP `frame-src 'none'`. Non-empty without `media.embed` — `embed_hosts требует capability media.embed`. Duplicates — rejected |
| `bridge_requests` | OBS request types. Without `bridge.obs` — rejected. Core denylist: `GetStreamServiceSettings`, `SetStreamServiceSettings` |

Concept: manifest ∩ Core policy. The guest does not “open” a URL itself — the host checks. Network — [05-emit-auth-net](05-emit-auth-net.md).

## Auth (`auth_mode`)

Without `auth_mode`, fields `auth_url` / `token_url` / `device_url` must not be set (`нужен auth.mode`). With a mode, grant `auth.token` and `platform_id` are required.

| Mode | Required | Optional |
| --- | --- | --- |
| `broker` | `client_id`, `auth_url`, `broker_url`; URL ∈ `hosts` | `token_url`, `userinfo_url`, `scopes` |
| `pkce` | `client_id`, `auth_url`, `token_url` | `userinfo_url`, `scopes` |
| `device` | `client_id`, `device_url`, `token_url` | `userinfo_url`, `scopes` |
| `api` | (streamer pastes token in UI) | `userinfo_url` |
| `custom` | `token_url` and at least one of `auth_url` / `device_url` | `userinfo_url`, `scopes` |

`client_secret` — forbidden. Core runs the OAuth shell; wasm sees only a short access via `auth.token`. In `dev` — `--token` / `--token-file`, not the Core safe.

`api` without a pasted token: `режим api: вставьте токен`. Broker in production requires a verified package signature — [10-package-signing](10-package-signing.md).

## Catalog: `provides` / `depends` / `consumes`

| Field | Rule |
| --- | --- |
| `provides` | list of `{ "name", "schema" }`. Currently name `emotes` → schema strictly `modus.emotes.v1`. Duplicate name — rejected |
| `depends` | `{ "platform": "twitch" }` — platform without which the catalog is meaningless. Empty `platform` — rejected |
| `consumes` | names of others' provides; currently only `"emotes"` |

Snapshot publish — grant `catalog.publish` ([09-bridge-history-rates-catalog](09-bridge-history-rates-catalog.md)). Reference: [`plugins/7tv`](../../../plugins/7tv).

## i18n in labels

`name` (and panel/settings texts) may be:

```json
"name": { "key": "plugin.title", "fallback": "My plugin" }
```

- `key` — flat key in `assets/i18n/{locale}.json` (Latin, ≤128).
- `fallback` — if locale / key is missing.
- With any `label.key` in the package, **`assets/i18n/en.json`** is required.
- Locale file ≤ 32 KiB; value ≤ 512; key→string object, no nesting.
- Locale: `en`, `ru`, or `en-US` (two lowercase + optional `-` + two uppercase).

Runtime label in settings form: `settings::set_label_i18n` / `modus_sdk::set_label_i18n` — Core substitutes the string from the catalog.

## Manifest bans

| Error | When |
| --- | --- |
| `client_secret запрещён в манифесте` | field present |
| `нет platform_id` | `bus.emit` or auth without the field |
| `auth.mode требует грант auth.token` | mode without cap |
| `нужен auth.mode` | auth URL without mode |
| `slots требуют грант ui.slot` / reverse | slots and cap out of sync |
| `user_theme требует …` | theme without ui surface |
| `provides: неизвестное имя` / bad schema | catalog |
| `bridge_requests: тип … в denylist Core` | forbidden OBS request |

Next chapter — [lifecycle and wait](01-lifecycle-wait.md).
