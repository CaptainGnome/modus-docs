# Commander

Commander reads canon from the bus and sends `chat.act` to the live platform connector. It does not emit canon or use the network: ban/timeout/say is done by the connector via `Ready::Act` + `chat_complete`.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `commander` |
| Required grants | `chat.act` |
| Modules | `chat_act` |
| Does not | `bus.emit`, network |
| Map | [ref/01-roles](../ref/01-roles.md) |

Reference: `modus new commander`.

## Manifest

```json
{
  "id": "com.modus.commander",
  "name": "Commander",
  "version": "0.1.0",
  "author": "modus",
  "abi": 2,
  // sole grant — enqueue ActJob for the live connector
  "capabilities": ["chat.act"]
  // no platform_id: job carries platform/channel from the bus event
}
```

`platform_id` not needed: the job carries `platform`/`channel` from the bus event.

## Code

**Subscribe and message filter.**

```rust
fn init() {
    // without subscribe, chat commands never wake Ready::Bus
    wait::subscribe();
}

fn on_bus(event: &Event) {
    // ignore donations/follows — only Message can carry !commands
    let Payload::Message(msg) = &event.payload else { return };
    // join Fragment::Text only (emotes/mentions stay out of the parser)
    let text = fragments_text(&msg.fragments);
    // map "!ban user" → ActJob targeting event.source.platform/channel
    let Some(job) = parse_command(&event.source.platform, &event.source.channel, &text) else {
        return; // not a command line
    };
    // host routes job to the live connector; connector wakes Ready::Act
    if let Err(err) = chat_act::act(&job) {
        log::log(Level::Warn, &err); // no connector / grant / stop
    }
}
```

**Command parser.** `!ban` / `!unban` / `!timeout <user> <sec>` / `!say …` → `ActJob`.

```rust
match cmd.as_str() {
    // Ban: target user, no duration
    "!ban" => Some(job(platform, channel, ActKind::Ban, None, Some(user), None)),
    // Timeout: target + seconds
    "!timeout" => Some(job(platform, channel, ActKind::Timeout, None, Some(user), Some(secs))),
    // Send: rest of line as chat text (no target user)
    "!say" => Some(job(platform, channel, ActKind::Send, Some(rest.into()), None, None)),
    _ => None, // unknown bang-command
}
```

Text comes only from `Fragment::Text` (emotes/mentions do not break the command).

## Assets

None: no settings / web / panel on the reference.

## How to run

```powershell
modus new commander --id com.you.cmd --dir cmd
modus dev modus new commander
```

In `dev`, `chat.act` is logged by the tutorial host (not the Core queue). Full path needs a live connector for the same `platform` (fixture also answers `Act`). Beside it: `modus dev …/fixture` + inject/`!say` from the bus, or `--inject` with a command message text.

Flags: [api/11-cli-dev](../api/11-cli-dev.md). Act contract — [api/06-kv-act-alerts](../api/06-kv-act-alerts.md).

## Typical host errors

| Situation | String / effect |
| --- | --- |
| No grant | `нет гранта chat.act` |
| No live platform connector | error immediately on `act` (host has nobody to wake) |
| Connector in backoff | `нет соединения` on the complete path |
| Stop | `остановлен` |
