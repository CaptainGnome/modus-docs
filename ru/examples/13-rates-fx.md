# Rates / FX

Роль публикует таблицу курсов в Core (`rates.publish`), не кладя курс в `opaque` канона. Эталон тянет snapshot с allowlisted HTTP, инвертирует пары к выбранной base и зовёт `publish`. Convert для алертов — другой грант (`rates.convert`) у alerter.

## Feature и гранты

| | |
| --- | --- |
| SDK feature | `rates` |
| Обязательные | `net.http`, `rates.publish` |
| Манифест | `hosts` — куда можно `fetch` |

Карта — [ref/01-roles](../ref/01-roles.md). API — [api/09-bridge-history-rates-catalog](../api/09-bridge-history-rates-catalog.md), сеть — [api/05-emit-auth-net](../api/05-emit-auth-net.md).

## Манифест

```json
{
  "id": "com.modus.fx",
  "name": "FX Rates",
  "version": "0.1.0",
  "abi": 2,
  /* fetch snapshot + publish таблицы в Core */
  "capabilities": ["net.http", "rates.publish"],
  /* allowlist origin; иначе «… вне манифеста» */
  "hosts": ["open.er-api.com"]
  /* UI / KV / emit нет — только таблица курсов */
}
```

| Поле | Зачем |
| --- | --- |
| `net.http` | `net_http::fetch` |
| `rates.publish` | снимок пар → FX table Core |
| `hosts` | allowlist origin; иначе `… вне манифеста` |
| нет UI / KV / emit | роль только таблица курсов |

## Код

**Цикл.** Refresh → timer по `interval_hours` (1…168 ч, минимум 60 s). Wake: Timer / Settings / Resume.

```rust
fn run() {
    loop {
        // сразу тянем snapshot; потом спим
        refresh();
        // interval из settings; дефолт 6 ч, clamp 1…168
        let hours = settings::get("interval_hours")
            .and_then(|v| v.parse::<f64>().ok())
            .unwrap_or(6.0)
            .clamp(1.0, 168.0);
        // минимум 60_000 мс — не долбить API чаще минуты
        let ms = ((hours as u64).saturating_mul(HOUR_MS)).max(60_000) as u32;
        wait::set_timer(ms);
        match wait::wait() {
            Ready::Stop => return,
            // Timer / смена settings / Resume → следующий refresh
            Ready::Timer | Ready::Settings | Ready::Resume => {}
            // Bus и пр. — не наш сценарий
            // …
        }
    }
}
```

**Fetch + publish.** Base из settings (по умолчанию `RUB`). URL строго под `hosts`.

```rust
fn refresh() {
    // ISO base: settings "base" или "RUB"
    let base = /* settings "base" или "RUB" */;
    // хост обязан быть в hosts манифеста
    let url = format!("https://open.er-api.com/v6/latest/{base}");
    match net_http::fetch("GET", &url, NONE, &[]) {
        Ok(resp) if (200..300).contains(&resp.status) => {
            // API: 1 base = value × code → инверт к Core
            let rates = parse_rates(&resp.body, &base)?;
            // снимок в FX table; alerter потом convert_to_base
            rates_publish::publish(&rates)?;
            // status label: "ok N pairs"
        }
        Ok(resp) => { /* http status → status label */ }
        Err(err) => { /* сеть / грант → status label */ }
    }
}
```

**Парсинг.** API даёт «1 base = value × code»; в Core нужны пары `from=code → to=base` с `value = 1/value`.

```rust
rates.push(Rate {
    from: code,              // чужая валюта (USD, EUR…)
    to: base.to_string(),    // base стримера (RUB…)
    value: 1.0 / value,      // инверт: сколько base за 1 code
});
```

Потребитель convert — [07-alerter](07-alerter.md) (`rates::convert_to_base`).

## Ассеты

| Путь | Назначение |
| --- | --- |
| `assets/settings.json` | `base` (ISO), `interval_hours`, label `status` |

## Запуск

```powershell
modus dev plugins/fx
```

Нужен сеть + whitelist хоста (и Core allowlist, если строже манифеста). Полный crate: [`../../../plugins/fx`](../../../plugins/fx).

В `dev` publish часто → stderr; convert у другого плагина зависит от того, сохранил ли учебный хост таблицу.

## Типичные ошибки хоста

| Строка / ситуация | Смысл |
| --- | --- |
| `нет гранта net.http` / `rates.publish` | нет capability |
| `хост … вне манифеста` / `не в whitelist Core` | URL не в allowlist |
| `только https/wss` | схема |
| `квота http` | rate limit |
| пустой снимок / `нет rates` | битый JSON ответа |
| convert без publish | у alerter `Err` на donation FX |

См. [ref/04-errors](../ref/04-errors.md), [ref/06-net-auth](../ref/06-net-auth.md).
