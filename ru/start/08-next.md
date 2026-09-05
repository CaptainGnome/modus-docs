# Дальше

Часть 1 (главы 0–6) закрыта, если у вас есть `dist/*.mplug` consumer и зелёный `dev`. Глава 7 (коннектор) — по желанию.

## Чеклист

- [ ] `modus new consumer` → `modus dev` → в логе `fixture hello`
- [ ] `modus pack` → файл `.mplug`
- [ ] (по желанию) `modus new connector` → `dev --token fake --replay …`

## Куда смотреть

| Нужно | Сжатый ref | Полный api |
| --- | --- | --- |
| Все роли `new` и гранты | [Карта ролей](../ref/01-roles.md) | [Манифест](../api/00-manifest.md) |
| `wait`, стоп, backoff | [Жизненный цикл](../ref/02-wait.md) | [Lifecycle](../api/01-lifecycle-wait.md) |
| Канон шины | [Канон](../ref/03-canon.md) | [Канон](../api/02-canon-bus.md) |
| Строки ошибок хоста | [Ошибки](../ref/04-errors.md) | [Ошибки](../api/03-errors.md) |
| Флаги `dev` | [CLI](../ref/05-cli.md) | [CLI](../api/11-cli-dev.md) |
| Сеть и OAuth | [Сеть и auth](../ref/06-net-auth.md) | [Emit/auth/net](../api/05-emit-auth-net.md) |
| KV, act, алерты, слоты | [Host API](../ref/07-host-apis.md) | [KV/act](../api/06-kv-act-alerts.md), [слоты](../api/07-ui-slots-panel.md) |
| Содержимое `.mplug` | [Пакет](../ref/08-package.md) | [Пакет/подпись](../api/10-package-signing.md) |
| Потолки | [Лимиты](../ref/09-limits.md) | [Лимиты](../api/12-limits.md) |
| Crate SDK | [Контракт](../ref/00-contract.md) | [SDK](../api/13-sdk-crate.md) |
| Чего нет в ABI 2 | [Не в этом ABI](../ref/10-not-in-abi.md) | — |
| WIT | [приложение](../ref/11-wit.md) | — |
| Разбор эталона по роли | [examples/](../examples/overview.md) | — |

Оглавление — [hub](../introduction.md).

Путь автора не меняется: SDK → `new` → `dev` → `pack` → shipped Modus. Секреты в пакет не кладут. Все роли `new` — [карта](../ref/01-roles.md); учебные dummy — [modus-examples](https://github.com/CaptainGnome/modus-examples).
