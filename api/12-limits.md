# Лимиты

**Правило.** Цифры хоста стабильны в ABI 2. Расхождение `dev` и Core по семантике (RAM vs sqlite, нет кассы алертов) не отменяет потолки ниже для Core.

Сжатая таблица — [ref/09-limits](../ref/09-limits.md).

## Одна таблица

| Что | Потолок |
| --- | --- |
| WASM memory | 16 MiB |
| `init` epoch | ~500 ms до trap (50×10 ms) |
| лог | 20/с |
| событие шины (JSON тела) | 64 KiB (`TooLarge`) |
| inbox `wait` | 64 (переполнение — drop) |
| HTTP таймаут | 15 s |
| HTTP тело / ответ | 1 MiB |
| HTTP inflight | 4 |
| HTTP редиректы | 5 hop (каждый checked) |
| WS сокетов | 2 |
| KV суммарно | 256 KiB |
| KV ключей | 256 |
| KV значение | 16 KiB |
| KV set/delete | 60/с |
| catalog снимок | 256 KiB |
| catalog эмоутов | 2048 |
| catalog publish | 10/с |
| `settings.json` | 32 KiB |
| settings секций / полей | 8 / 32 |
| `panel.json` | 32 KiB |
| i18n файл | 32 KiB |
| i18n ключ / значение | 128 / 512 |
| `platform_logo` | 128 KiB |
| `ui-slot.post` | 64 KiB, 10/с |
| `chat.act` текст send | ≤ 500 |
| `chat.act` шторм | ~10/с на плагин |
| `chat.act` complete | 15 s |
| Core act (композер) | ~5/с |
| backoff старт / max | 1 s / 30 s |
| trap quarantine | 3 падения / 60 s |
| `dev` join на Stop | 5 s |
| plugin `id` длина | ≤ 128 |
| panel blocks | 24 |
| panel nest depth | 1 |

Грант не поднимает лимит: нет cap — `Grant`, есть cap но превысили — `Other` / `Network` / отказ валидации.

Следующая глава — [crate SDK](13-sdk-crate.md).
