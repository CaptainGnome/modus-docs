# Пакет `.mplug` и подпись

**Правило.** `.mplug` — zip. В корне: `manifest`, `module.wasm`, опционально `assets/` (posix, без `..`) и опционально `signature`. Иной корень — отказ. Пишет `modus pack`.

Сжатый layout — [ref/08-package](../ref/08-package.md). Политика подписи целиком — [`docs/signing.md`](../../docs/signing.md) в checkout Modus (из submodule `modus-docs`: `../docs/signing.md` от корня docs-репо; из этой главы — `../../docs/signing.md`).

## Layout zip

| Путь | Содержимое |
| --- | --- |
| `manifest` | JSON **без** расширения |
| `module.wasm` | **компонент** WIT (не голый core после `cargo build`) |
| `assets/settings.json` | схема настроек; нет файла — нет формы; битая — не ставится; ≤ 32 KiB |
| `assets/i18n/{locale}.json` | плоские строки; при `label.key` обязателен `en.json` |
| `assets/panel.json` | native-панель; HTML в текстах — отказ; ≤ 32 KiB |
| `assets/panel/index.html` | panel web; вместе с `panel.json` — отказ |
| `assets/web/index.html` | OBS / web-слот |
| `assets/web/**` | статика; без `../` |
| `assets/<platform_logo>` | лого площадки; svg/png/webp/jpg ≤ 128 KiB |
| `signature` | опционально; **не** входит в digest |

`id` в манифесте стабилен: повторная установка с тем же `id` заменяет пакет. KV и settings привязаны к `id`.

## Сборка

`pack`:

1. release-wasm (`opt` как у эталонов);
2. wrap в компонент;
3. soft-link импортов (известный modus без гранта — ок; WASI / чужое — отказ);
4. zip → `dist/<имя>.mplug`.

Без успешного `check` файла нет. В одном crate `modus-sdk` + `wit_bindgen::generate` в `src` — отказ: `WIT вручную плюс SDK — два bindgen`.

## Подпись (для автора)

Опционально. Канонический SHA-256 всех записей zip **кроме** `signature`, Ed25519 на сырой digest.

Файл `signature` (v1): `alg`, `key_id`, `digest`, `sig`. Поле `license` зарезервировано (store/DRM позже).

```powershell
modus keygen --out modus.key
modus pack --sign --key-file modus.key
modus check path\to\plugin.mplug --trusted-keys trusted_keys.json
```

Переменная `MODUS_SIGN_KEY` — путь к ключу (эквивалент `--key-file` при pack).

| Статус | Установка |
| --- | --- |
| Unsigned | с диска ок, UI предупреждает; OAuth через broker недоступен |
| Invalid | установка отклонена |
| Verified | broker / строгие политики |

Trusted keys и revoke — в [`docs/signing.md`](../../docs/signing.md). Файлы `plugins/{id}/inject/` в Core **не** в digest (темы overlay).

Следующая глава — [CLI](11-cli-dev.md).
