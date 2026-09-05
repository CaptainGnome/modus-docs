# Базовые host API

**Правило.** Эти импорты есть у любого пакета на world `plugin`. Грант в манифесте не нужен. Soft-link полный; deny только на стопе / валидации аргументов.

Модули SDK (при любой role-feature): `self_info`, `log`, `clock`, `assets`, `settings`, `wait`, `types`. `chat_complete` — без гранта, но re-export у feature `emitter` / `connector`.

## `self_info`

```text
plugin_id() -> string
version()   -> string
```

| Вызов | Значение |
| --- | --- |
| `plugin_id` | `id` из манифеста |
| `version` | `version` из манифеста |

Для логов и отладки; подделать чужой id нельзя.

## `log`

```text
log(level, message)
```

Уровни: `debug` / `info` / `warn` / `error`. Потолок **20 сообщений/с** на инстанс; лишнее хост дропает. Токены и refresh в сообщение не писать (в `dev` redact слабее Core).

## `clock`

```text
sleep_ms(ms)
```

Блокирующий сон с опросом стопа ~каждые 50 ms. **Не** замена `wait` для циклов коннектора: на стопе выходите через `Ready::Stop` / `wait_backoff`, иначе join в `dev` ждёт 5 s.

## `assets.read`

```text
read(path) -> Result<Vec<u8>, String>
```

Чтение файла из пакета относительно `assets/`. Без `..`, без абсолютных путей, без выхода из дерева ассетов. Типично: дефолтные JSON, звуки для `media.audio` spec `asset`, статика для сверки.

Диск стримера и чужие пакеты не видны. Persist — KV / settings Core.

## Settings

Схема — `assets/settings.json`. Нет файла — нет формы в UI. Битая / > 32 KiB — пакет не ставится. Потолки схемы: 8 секций, 32 поля. Рисует **Core**; гость значения читает/пишет labels.

```text
get(key) -> Option<String>
set_label(key, text) -> Result<(), String>
set_label_i18n(key, label_key, params?) -> Result<(), String>
```

| Вызов | Правило |
| --- | --- |
| `get` | нет схемы / чужой ключ → `None`. В `init` без `wait` ок |
| `set_label` | только поле `type: label` в схеме; иначе отказ |
| `set_label_i18n` | Core резолвит `label_key` из `assets/i18n/{locale}.json`; `params` — опциональный JSON-объект (`{"err":"boom"}`) для подстановок |

Обёртка SDK: `modus_sdk::set_label_i18n(...)`.

Save в Core → `Ready::Settings`. В `dev`: `--settings file.json` — оверлей значений + один `Ready::Settings` после `init`. Неизвестный ключ в файле — отказ при старте `dev`.

Эталон: [`plugins/store`](../../../plugins/store).

## `chat_complete`

```text
complete(id, outcome: Result<(), String>)
```

Без гранта. Вызывает **коннектор/emitter**, получивший `Ready::Act`, с тем же `id` job. Чужой id — отказ. Нет `complete` за **15 с** — ошибка тому, кто звал `chat.act`.

Командир `complete` не вызывает. Исход `Err` — текст уходит вызывающему act, на шину сам по себе не кладётся.

Связка act — [06-kv-act-alerts](06-kv-act-alerts.md). Жизненный цикл — [01-lifecycle-wait](01-lifecycle-wait.md).

Следующая глава — [emit, auth, сеть](05-emit-auth-net.md).
