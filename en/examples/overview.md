# Reference plugins

Role walkthroughs: key manifest and code fragments with “what / why / where” notes.

**Public runnable kit** — [modus-examples](https://github.com/CaptainGnome/modus-examples): educational-full dummies (`consumer`, `emitter`, `connector-replay`, `widget`), not copies of closed `plugins/*`. Canonical — sibling clone next to sdk/docs; submodule is checkout convenience. Other roles — `modus new <role>` + chapters below.

Your own plugin always starts from `modus new`, not a fork of a dummy. Dummies are not the store catalog.

Role map — [ref/01-roles](../ref/01-roles.md). SDK — [modus-sdk](https://github.com/CaptainGnome/modus-sdk).

| | Chapter | Role | Runnable |
| --- | --- | --- | --- |
| 0 | [Consumer](00-consumer.md) | `consumer` | [`modus-examples/consumer`](https://github.com/CaptainGnome/modus-examples/tree/master/consumer) |
| 1 | [Emitter / fixture](01-emitter-fixture.md) | `emitter` | [`modus-examples/emitter`](https://github.com/CaptainGnome/modus-examples/tree/master/emitter) |
| 2 | [Connector](02-connector-twitch.md) | `connector` | [`modus-examples/connector-replay`](https://github.com/CaptainGnome/modus-examples/tree/master/connector-replay) |
| 3 | [Provider / 7TV](03-provider-7tv.md) | `provider` | `modus new provider` |
| 4 | [Widget / web-slot](04-widget-web-slot.md) | `widget` | [`modus-examples/widget`](https://github.com/CaptainGnome/modus-examples/tree/master/widget) |
| 5 | [Panel](05-panel.md) | `widget` (panel) | `modus new panel` |
| 6 | [Commander](06-commander.md) | `commander` | `modus new commander` |
| 7 | [Alerter](07-alerter.md) | `alerter` | `modus new alerter` |
| 8 | [Store](08-store.md) | `store` | `modus new store` |
| 9 | [Reader](09-reader.md) | `reader` | `modus new reader` |
| 10 | [Player](10-player.md) | `player` | `modus new player` |
| 11 | [Bridge / OBS](11-bridge-obs.md) | `bridge` | `modus new bridge` |
| 12 | [Embedder](12-embedder.md) | `embedder` | `modus new embedder` |
| 13 | [Rates / FX](13-rates-fx.md) | `rates` | `modus new rates` |

Hub — [README](../introduction.md).
