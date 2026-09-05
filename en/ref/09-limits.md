# Runtime limits

If this is your first plugin — a green `dev` is enough. If you need ceilings — one table.

**Rule.** Host limits are stable in ABI 2; `dev` vs Core semantics (RAM vs sqlite) do not cancel the numbers below for Core.

| What | Ceiling |
| --- | --- |
| WASM memory | 16 MiB |
| `init` | ~500 ms until trap (epoch) |
| HTTP | 15 s, 1 MiB, 4 inflight, 5 redirects |
| WS | 2 sockets, frames via `wait` |
| log | 20/s |
| bus event | 64 KiB |
| `wait` inbox | 64 |
| KV | 256 KiB / 256 keys / 16 KiB value / 60 set·delete/s |
| catalog | 256 KiB / 2048 emotes / 10 publish/s |
| settings.json | 32 KiB, 8 sections, 32 fields |
| `ui-slot.post` | 64 KiB, 10/s |
| `chat.act` | text ≤ 500; ~10/s |

Next chapter — [not in this ABI](10-not-in-abi.md).
