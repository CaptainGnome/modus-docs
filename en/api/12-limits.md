# Limits

**Rule.** Host numbers are stable in ABI 2. `dev` vs Core semantic divergence (RAM vs sqlite, no alert cashier) does not cancel the Core ceilings below.

Compressed table — [ref/09-limits](../ref/09-limits.md).

## One table

| What | Ceiling |
| --- | --- |
| WASM memory | 16 MiB |
| `init` epoch | ~500 ms to trap (50×10 ms) |
| log | 20/s |
| bus event (JSON body) | 64 KiB (`TooLarge`) |
| `wait` inbox | 64 (overflow — drop) |
| HTTP timeout | 15 s |
| HTTP body / response | 1 MiB |
| HTTP inflight | 4 |
| HTTP redirects | 5 hops (each checked) |
| WS sockets | 2 |
| KV total | 256 KiB |
| KV keys | 256 |
| KV value | 16 KiB |
| KV set/delete | 60/s |
| catalog snapshot | 256 KiB |
| catalog emotes | 2048 |
| catalog publish | 10/s |
| `settings.json` | 32 KiB |
| settings sections / fields | 8 / 32 |
| `panel.json` | 32 KiB |
| i18n file | 32 KiB |
| i18n key / value | 128 / 512 |
| `platform_logo` | 128 KiB |
| `ui-slot.post` | 64 KiB, 10/s |
| `chat.act` send text | ≤ 500 |
| `chat.act` storm | ~10/s per plugin |
| `chat.act` complete | 15 s |
| Core act (composer) | ~5/s |
| backoff start / max | 1 s / 30 s |
| trap quarantine | 3 crashes / 60 s |
| `dev` join on Stop | 5 s |
| plugin `id` length | ≤ 128 |
| panel blocks | 24 |
| panel nest depth | 1 |

A grant does not raise the limit: no cap — `Grant`; cap present but exceeded — `Other` / `Network` / validation reject.

Next chapter — [SDK crate](13-sdk-crate.md).
