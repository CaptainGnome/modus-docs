# Пакет `.mplug`

Если это первый плагин — [упаковать](../start/06-pack.md). Если нужен layout zip — эта глава.

**Правило.** Zip. В корне: `manifest`, `module.wasm`, опционально `assets/` (posix, без `..`). Иной корень — отказ.

| Файл | Содержимое |
| --- | --- |
| `manifest` | JSON **без** расширения |
| `module.wasm` | **компонент**, не core-модуль после голого `cargo build` |
| `assets/settings.json` | схема настроек; нет файла — нет формы; битая — пакет не ставится; ≤ 32 KiB |
| `assets/i18n/{locale}.json` | плоские строки; при `label.key` обязателен `en.json` |
| `assets/panel.json` | native-панель; HTML в текстах — отказ; ≤ 32 KiB |
| `assets/panel/index.html` | panel web; вместе с `panel.json` — отказ |
| `assets/web/index.html` | OBS / web-слот; JS/CSS ок |
| `assets/web/**` | статика; без `../` |
| `assets/<platform_logo>` | лого площадки; svg/png/webp/jpg ≤ 128 KiB |

`id` в манифесте стабилен: повторная установка с тем же `id` заменяет пакет. Смена `id` = другой плагин. KV и settings привязаны к `id`.

`id` — reverse-DNS ≥3 сегмента. `platform_id` — короткое имя площадки, не id пакета.

Пишет `modus pack`. Soft-link: известный modus-импорт без гранта — ок; WASI / чужое — отказ. Подпись — [`docs/signing.md`](../../docs/signing.md).

Следующая глава — [лимиты](09-limits.md).
