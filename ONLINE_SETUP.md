# Room-code service — maintainer setup

## Status

The room-code client and relay are implemented and tested locally. **No public relay has been deployed or configured.** `online.cfg` deliberately contains an empty URL, so this source build clearly marks online rooms unavailable. Local play and LAN/IP connections remain usable. Do not label a build ready for internet room-code play until the deployment and two-network check below pass.

Once configured, players click **Create online room**, copy the eight-character code, and send it to a friend. The friend enters the code and clicks **Join room**. Both add a player; the host starts the match. Everyone uses the endpoint included in the build. Players do not create hosting accounts, run servers, enter IP addresses, or forward router ports.

## Deploy one shared instance

`relay/` is a small Node.js 22+ service using a pinned `ws` dependency. `render.yaml` defines one Free Render web service with HTTPS, a health check, and no database or persistent disk. It can also run on another host that supports long-lived WebSockets. For Render:

1. Connect the repository to your Render account and create a Blueprint using `render.yaml` on the branch containing this change. Confirm **Free** compute and a single instance. No paid database, disk, custom domain, or workspace upgrade is required.
2. Wait for `/healthz` on the assigned HTTPS URL to return `{"service":"downstack-rooms","version":1,"ok":true}`.
3. Set `relay_url="wss://YOUR-ASSIGNED-HOST/rooms"` in `online.cfg`, then export a Windows build. An exported game also accepts `online.cfg` beside `Downstack.exe`, allowing the maintainer to change the endpoint without a recompile. Bundle the same config for every player. The URL is public configuration, not a secret.
4. Package **Downstack.exe, Downstack.pck, online.cfg, licenses, and the shortcut helper** together as a Windows Release ZIP. GitHub's **Code → Download ZIP** contains source, not an executable.
5. Test from two different internet connections before publishing the configured build. Test create/join, attacks, late spectator, rematch, leaving, and reconnecting with a new room. Confirm starting after the free service sleeps, and invalid/expired code messages. Local tests cannot establish WAN latency or hosting reliability.

When using the Render integration, connect the account first, inspect the service plan, and deploy only the Free compute option. This change does not create any hosting subscription or deployment itself.

## Keep the trial strictly free

Render documents 750 free instance hours per workspace/month and 5 GB of Hobby outbound bandwidth shared across services. It sleeps after 15 minutes without inbound traffic and takes about a minute to wake. Active game/heartbeat messages keep an occupied room active. Free instances may restart at any time. Without a payment method, exceeding the bandwidth allowance suspends services until the next month; with a payment method, overage charges can apply. Inspect the account's actual plan and payment state before deployment.

The client retries initial connections for up to 90 seconds and offers Cancel. It does not silently reconnect an interrupted match: players receive an explanation, return to the menu, and create/join a new room. Codes and room state live only in memory and disappear when the host leaves or the service restarts.

`tests/room_bandwidth.gd` samples empty, eight-row and sixteen-row boards. Application-message estimates at 20 updates/second are approximately **61–95 MB/hour for two players on two PCs**, or **365–570 MB/hour for four players on four PCs**, before WebSocket/TLS/TCP overhead, other messages, retransmits, and other account traffic. These are synthetic estimates, not a measured monthly bill. Spectators and simultaneous rooms increase usage. The relay avoids echoing a player's own board back to them. Monitor Render's actual outbound-traffic dashboard during the first real sessions.

Official hosting references checked during implementation:
- https://render.com/docs/free
- https://render.com/docs/outbound-bandwidth
- https://render.com/docs/websocket

## Local development and tests

```text
npm ci --prefix relay
npm test --prefix relay
node relay/server.mjs
```

Use `DOWNSTACK_RELAY_URL=ws://127.0.0.1:8080/rooms` for local game testing. Internet endpoints must use verified `wss://`; plaintext `ws://` is accepted only for localhost tests. Do not disable certificate verification.

After importing the project with Godot 4.6.3:

```text
godot --headless --path . --editor --import --quit
# Set GODOT_BIN to the Godot executable if it is not on PATH.
node tests/run_room_tests.mjs
godot --headless --path . --script tests/room_bandwidth.gd
```

The room test launcher runs the actual main-menu create/join/cancel/error flow, then four separate Godot processes through a real local relay. It covers four players (including two local players on one client), a late spectator, board snapshots, garbage, a second round, stale-round rejection, disconnect forfeits, winner agreement and host departure. Run the existing nine regression suites and `tests/run_network_tests.py` as well; the direct ENet protocol remains 4.

## Scope and operational limits

The service pairs room members and forwards game messages over WebSockets/TCP. It does not simulate games, store accounts, provide matchmaking, or supply competitive anti-cheat. The player's host continues to coordinate the session. TCP loss can delay subsequent updates; this is not rollback networking or a low-latency guarantee.

Codes are random, unlisted invitations. Anyone given a code can join the room as a spectator, so share them only with intended participants. The service has bounded room/connection counts, packet-size and rate limits, heartbeats, slow-client handling, and an explicit authority/message allowlist. Clients cannot choose their sender identity or forward host-only messages. Rooms are isolated by server-side membership. Application code does not persist IP addresses, codes, or gameplay; the hosting provider may retain standard connection/access logs. Review dependency/security updates before broad public use.

Run exactly one service instance: the room directory is in memory and cannot be load-balanced across independent instances. Host departure ends the room; there is no host migration. Online rooms require the 0.9 client, while direct LAN/IP remains compatible with 0.7/0.8 protocol 4. For a large public release, revisit authentication/moderation, traffic budgets, latency and persistent room coordination.
