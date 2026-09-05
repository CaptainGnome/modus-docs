# Не в этом ABI

Если это первый плагин — [что нельзя](../start/04-cannot.md). Если нужна граница ABI 2 — эта глава.

**Правило.** Хост грузит только `"abi": 2`. Старый `.mplug` с ABI 1 не загрузится. Ниже — то, чего **нет** у гостя как обещания платформы.

## Нет у гостя

- Диск и свои сокеты (кроме KV хоста и чтения своих `assets/`).
- WASI / `wasi-http` — всегда отказ `pack` / загрузки.
- Settings как HTML-форма плагина: схему рисует Core.
- Сырой TCP к OBS/VTS в обход `net.bridge`.
- Эмит канона `system` (только Core).
- Store/DRM (`signature.license` и т.п.) — позже у продукта, не путь автора плагина в этом гайде.

## Уже в ABI 2 (не сюда)

`media.audio`, `net.bridge`, `history.read`, `media.embed`, `rates.*`, `catalog.publish`, `ui.slot`, алерты, KV, `chat.act` — см. [карту ролей](01-roles.md) и [host API](07-host-apis.md).

TTS: голос — другой плагин (`media.audio` или `custom` `tts.request`), не «Core говорит».

Следующая глава — [WIT](11-wit.md).
