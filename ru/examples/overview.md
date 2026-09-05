# Эталоны

Разборы ролей: ключевые фрагменты манифеста и кода с комментариями «что / зачем / куда».

**Публичный runnable kit** — [modus-examples](https://github.com/CaptainGnome/modus-examples): учебно-полные dummy (`consumer`, `emitter`, `connector-replay`, `widget`), не копии закрытых `plugins/*`. Канон — sibling clone рядом с sdk/docs; submodule — удобство checkout’а. Остальные роли — `modus new <роль>` + главы ниже.

Свой плагин всегда с `modus new`, не форком dummy. Dummy — не каталог стора.

Карта ролей — [ref/01-roles](../ref/01-roles.md). SDK — [modus-sdk](https://github.com/CaptainGnome/modus-sdk).

| | Глава | Роль | Runnable |
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

Hub — [оглавление](../introduction.md).
