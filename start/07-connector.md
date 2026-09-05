# Коннектор: replay без живой площадки

Если consumer уже зелёный — здесь учебный коннектор: фейковый токен и кадры из файла. Живой Twitch и окно Core не нужны. Если нужны OAuth и `hosts` подробно — [сеть и auth](../ref/06-net-auth.md).

Команды — из **корня** репозитория. Функция `modus` — [инструменты](01-tools.md).

## Каркас

```powershell
modus new connector --id com.you.mine --dir mine
```

- `connector` — роль: логин через хост, сеть, emit канона.
- `--id com.you.mine` — свой второй кусок вместо `you`.
- `--dir mine` — папка каркаса.

В манифесте будут `auth_mode`, `client_id`-заглушка, `hosts: ["example.com"]`. Официальный Twitch `client_id` и брокер CLI **не** подставляет.

## Replay в `dev`

Создайте `mine/frames.replay` (одна строка = один текстовый кадр WS):

```text
hello-dev
```

Запуск:

```powershell
modus dev mine --token fake --replay mine/frames.replay
```

- `--token fake` — фейковый access в процессе CLI. Не сейф Core, в `.mplug` не попадает.
- `--replay` — хост отдаёт строки файла как `Ready::WsText`, без живого `wss://`.

Каркас после `token` коннектится к `wss://example.com/` (из кода), но с `--replay` сокет учебный: кадры из файла. Плагин эмитит сообщение на шину — в терминале видно текст кадра (например `hello-dev`).

Ctrl+C — `Ready::Stop`. `"остановлен"` / `HostError::is_stop()` не глотать в реконнект: каркас зовёт `wait_backoff`, стоп выходит из цикла.

Без `--replay` CLI может открыть один live `wss://` из `hosts` манифеста (не private). Для первого раза replay достаточно.

`--http-file` — JSON-ответы для офлайн `net.http` (ключ = URL без query). Нужен Helix/API без сети — см. [`modus-sdk/cli/tests/fixtures`](../../modus-sdk/cli/tests/fixtures) и эталон [`plugins/twitch`](../../plugins/twitch).

## Что не трогать в этой главе

`--settings` / `--act` / `--ui` — [справочник CLI](../ref/05-cli.md), не туториал 0–6.

Живой OAuth и установка `.mplug` в приложение — не способ отладки коннектора. Сначала `dev` с replay.

Следующая глава — [дальше](08-next.md).
