# Next steps

Part 1 (chapters 0–6) is done if you have a consumer `dist/*.mplug` and a green `dev`. Chapter 7 (connector) is optional.

## Checklist

- [ ] `modus new consumer` → `modus dev` → `fixture hello` in the log
- [ ] `modus pack` → `.mplug` file
- [ ] (optional) `modus new connector` → `dev --token fake --replay …`

## Where to look

| Need | Compact ref | Full api |
| --- | --- | --- |
| All `new` roles and grants | [Role map](../ref/01-roles.md) | [Manifest](../api/00-manifest.md) |
| `wait`, stop, backoff | [Lifecycle](../ref/02-wait.md) | [Lifecycle](../api/01-lifecycle-wait.md) |
| Bus canon | [Canon](../ref/03-canon.md) | [Canon](../api/02-canon-bus.md) |
| Host error strings | [Errors](../ref/04-errors.md) | [Errors](../api/03-errors.md) |
| `dev` flags | [CLI](../ref/05-cli.md) | [CLI](../api/11-cli-dev.md) |
| Network and OAuth | [Network and auth](../ref/06-net-auth.md) | [Emit/auth/net](../api/05-emit-auth-net.md) |
| KV, act, alerts, slots | [Host API](../ref/07-host-apis.md) | [KV/act](../api/06-kv-act-alerts.md), [slots](../api/07-ui-slots-panel.md) |
| `.mplug` contents | [Package](../ref/08-package.md) | [Package/signing](../api/10-package-signing.md) |
| Ceilings | [Limits](../ref/09-limits.md) | [Limits](../api/12-limits.md) |
| SDK crate | [Contract](../ref/00-contract.md) | [SDK](../api/13-sdk-crate.md) |
| What is not in ABI 2 | [Not in this ABI](../ref/10-not-in-abi.md) | — |
| WIT | [appendix](../ref/11-wit.md) | — |
| Annotated reference by role | [examples/](../examples/overview.md) | — |

Table of contents — [README](../introduction.md).

The author path does not change: SDK → `new` → `dev` → `pack` → Core. Secrets do not go into the package.
