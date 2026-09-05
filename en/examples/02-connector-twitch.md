# Connector / Twitch

A connector is a live platform: OAuth via host, HTTP/WS, canon emit, reply to `chat.act`. Twitch reference (~700 lines): below only auth → IRC → wait-loop → emit, not a full Helix/EventSub dump.

## Feature and grants

| | |
| --- | --- |
| SDK feature | `connector` |
| Required (typical) | `auth.token` + `net.http` + `net.ws` + `bus.emit` + `media.cache` |
| Modules | `auth_token`, `net_http`, `net_ws`, `bus_emit`, `chat_complete`, `media_cache` |
| Map | [ref/01-roles](../ref/01-roles.md) |

Reference: `modus new connector`. Auth/network — [ref/06-net-auth](../ref/06-net-auth.md).

## Manifest (fragment)

| Field | Why |
| --- | --- |
| `capabilities` | token, HTTP, WS, emit, emote cache |
| `platform_id` | `"twitch"` — canon label and platform slot |
| `auth_mode` | `"broker"` — OAuth via Core/CLI broker |
| `client_id` / `auth_url` / `token_url` / `userinfo_url` | Helix OAuth |
| `broker_url` | code-exchange broker |
| `scopes` | chat / mod / redemptions |
| `hosts` | DNS allowlist for `net.*` |

```json
{
  // five grants: OAuth token, Helix HTTP, IRC/EventSub WS, bus write, emote pins
  "capabilities": ["auth.token", "net.http", "net.ws", "bus.emit", "media.cache"],
  // single live owner of the "twitch" platform slot
  "platform_id": "twitch",
  // OAuth flows through Core/CLI broker (not raw client secret in guest)
  "auth_mode": "broker",
  // DNS allowlist — net.* to any other host is refused
  "hosts": [
    "id.twitch.tv",           // OAuth
    "api.twitch.tv",          // Helix REST
    "irc-ws.chat.twitch.tv",  // chat IRC over WS
    "eventsub.wss.twitch.tv"  // EventSub notifications
  ]
}
```

Full file: `modus new connector`.

## Code: auth → WS → wait → emit

**Start: account and token.** Without an account `run` exits quietly; token only via grant.

```rust
fn run() {
    // list linked OAuth accounts the host already holds for this plugin
    let accounts = auth_token::list_accounts();
    if accounts.is_empty() {
        // no login yet — exit quietly (Core shows "link account")
        log::log(Level::Info, "нет аккаунта");
        return;
    }
    // pick first linked account for this session
    run_account(&accounts[0]);
}

fn run_session(account_id: &str) -> Outcome {
    // fetch access token — grant-gated; is_stop errors must not become Retry
    let token = match auth_token::token(account_id) {
        Ok(token) => token,
        Err(err) => return fail(&err), // is_stop → do not swallow into backoff
    };
    // helix_user(&token) → nick / user_id for IRC identity
    // open IRC WebSocket — URL must be in manifest hosts
    let irc = match net_ws::connect(IRC_URL) { /* … */ Ok(h) => h, Err(e) => return fail(&e) };
    // PASS / NICK / CAP / JOIN on irc — then enter wait-loop below
}
```

**Wait-loop (skeleton).** One IRC + EventSub; `Act` → Helix/PRIVMSG; socket close → retry with backoff.

```rust
loop {
    match wait::wait() {
        // host shutdown — close sockets, Outcome::Stopped
        Ready::Stop => { /* close; Outcome::Stopped */ }
        // IRC socket died — fail so outer layer can backoff/retry
        Ready::WsClosed(h) if h == session.irc => return fail("ws закрыт"),
        // inbound IRC line — parse PRIVMSG / NOTICE / …
        Ready::WsText(frame) if frame.handle == session.irc => {
            if let Some(out) = handle_irc(&mut session, &frame.text) {
                return out; // Stopped or fatal from inside handler
            }
        }
        // commander chat.act job — Helix/PRIVMSG then complete
        Ready::Act(req) => handle_act(&session, &req),
        // Core asked resume after pause — treat as session end here
        Ready::Resume => return fail("resume"),
        // periodic: EventSub reconnect / poll viewer count
        Ready::Timer => { /* EventSub reconnect / poll viewers */ }
        _ => {}
    }
}
```

**Emit from PRIVMSG.** Parser → `Payload::Message` → `bus_emit`; emote URLs into `media_cache`.

```rust
Line::Privmsg(msg) => {
    // warm-lookup emote CDN URLs before emit (async pin starts)
    for url in &urls { let _ = media_cache::lookup(url); }
    // map IRC tags → canon Message (user, fragments, color, …)
    let payload = Payload::Message(Message { /* user, fragments, color… */ });
    // channel from PRIVMSG → bus channel; None opaque for plain chat
    if let Err(err) = bus_emit::emit(&msg.channel, &payload, None) {
        // stop errors (shutdown) must abort the session, not log-and-continue
        if HostError::classify(&err).is_stop() {
            return Some(Outcome::Stopped);
        }
    }
    // ensure pins after emit so overlay can resolve cache/{key}
    for url in &urls { let _ = media_cache::ensure(url); }
}
```

**Act → complete.** Send goes to IRC; ban/timeout/delete — Helix; always `chat_complete`.

```rust
fn handle_act(session: &Session, req: &ActRequest) {
    // Send → PRIVMSG; Ban/Timeout/Delete → Helix moderation APIs
    match execute_act(session, req) {
        // always ack — commander blocks until complete
        Ok(()) => chat_complete::complete(&req.id, Ok(())),
        Err(err) => chat_complete::complete(&req.id, Err(err.as_str())),
    }
}
```

## Assets

Twitch has `platform_logo.svg` (platform icon). No settings UI in the reference: channel = IRC account login.

## How to run

```powershell
modus new connector --id com.you.twitch --dir twitch
```

Offline without live Twitch ([start/07-connector](../start/07-connector.md)):

```powershell
modus dev ../modus-examples/connector-replay --token fake --replay frames.replay
```

Optional `--http-file` for Helix. Live OAuth — Core / broker, not the first debug step.

## Typical host errors

| Situation | String |
| --- | --- |
| Missing cap | `no grant auth.token` / `net.ws` / `bus.emit` |
| Host not in `hosts` | `… not in manifest` |
| Not https/wss | `https/wss only` |
| Foreign / revoked token | `foreign account`, `refresh revoked` (`is_stop`) |
| No `platform_id` | `no platform_id` |
| Platform taken | `platform_id … already taken` |
| Stop during backoff | `stopped` — exit, do not `Retry` |
