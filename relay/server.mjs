import http from 'node:http';
import { randomInt } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { WebSocketServer, WebSocket } from 'ws';

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const HOST_KINDS = new Set(['lobby', 'start', 'state', 'garbage', 'finish', 'return']);
const CLIENT_KINDS = new Set(['player', 'submit', 'attack']);
export const normalizeCode = value => typeof value === 'string' ? value.trim().toUpperCase().replace(/[\s-]/g, '') : '';

// One process owns the room directory. Run one instance, behind HTTPS/WSS.
// The relay forwards bounded packets; the player's host still runs the session.
export function createRelay({ maxRooms = 100, maxConnections = 200, maxPeers = 13, heartbeatMs = 15000, handshakeMs = 10000 } = {}) {
  const rooms = new Map();
  const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.writeHead(req.url === '/healthz' || req.url === '/' ? 200 : 404);
    res.end(JSON.stringify({ service: 'downstack-rooms', version: 1, ok: req.url === '/healthz' || req.url === '/' }));
  });
  const wss = new WebSocketServer({ noServer: true, maxPayload: 100000, perMessageDeflate: false });
  function send(ws, data, disposable = false) {
    if (ws.readyState !== WebSocket.OPEN) return;
    // Old board views may be skipped. Never silently drop lobby/attack/results.
    if (ws.bufferedAmount > 262144 && disposable) return;
    if (ws.bufferedAmount > 1048576) return ws.close(1013, 'Connection too slow. Please rejoin.');
    ws.send(JSON.stringify(data));
  }
  function reject(ws, code, message) {
    send(ws, { op: 'error', code, message });
    ws.close(1008, message);
  }
  server.on('upgrade', (req, socket, head) => {
    if (req.url !== '/rooms' || wss.clients.size >= maxConnections) {
      socket.end('HTTP/1.1 503 Service Unavailable\r\nConnection: close\r\n\r\n');
      return;
    }
    wss.handleUpgrade(req, socket, head, ws => wss.emit('connection', ws));
  });
  wss.on('connection', ws => {
    ws.room = null;
    ws.peer = 0;
    ws.alive = true;
    ws.tokens = 240;
    ws.bytes = 1048576;
    ws.budgetTime = Date.now();
    const handshake = setTimeout(() => reject(ws, 'timeout', 'Room request timed out.'), handshakeMs);
    handshake.unref();
    ws.on('pong', () => { ws.alive = true; });
    ws.on('error', () => {});
    ws.on('message', (raw, binary) => {
      const now = Date.now();
      const seconds = (now - ws.budgetTime) / 1000;
      ws.budgetTime = now;
      ws.tokens = Math.min(240, ws.tokens + seconds * 120) - 1;
      ws.bytes = Math.min(1048576, ws.bytes + seconds * 524288) - raw.length;
      if (ws.tokens < 0 || ws.bytes < 0) return reject(ws, 'rate_limit', 'Too many room messages.');
      let msg;
      try { msg = JSON.parse(raw.toString()); } catch { return reject(ws, 'invalid', 'Invalid room message.'); }
      if (binary || !msg || typeof msg !== 'object' || Array.isArray(msg)) return reject(ws, 'invalid', 'Invalid room message.');
      if (msg.op === 'ping') return send(ws, { op: 'pong' });
      if (!ws.room) {
        if (!['create', 'join'].includes(msg.op)) return reject(ws, 'invalid', 'Create or join a room first.');
        if (msg.wire !== 1 || msg.protocol !== 4) return reject(ws, 'version', 'Update Downstack to a compatible version.');
        let room;
        if (msg.op === 'create') {
          if (rooms.size >= maxRooms) return reject(ws, 'busy', 'Online rooms are full. Try again shortly.');
          let code;
          do { code = Array.from({ length: 8 }, () => ALPHABET[randomInt(ALPHABET.length)]).join(''); } while (rooms.has(code));
          room = { code, peers: new Map(), nextPeer: 2 };
          rooms.set(code, room);
          ws.peer = 1;
        } else {
          room = rooms.get(normalizeCode(msg.code));
          if (!room) return reject(ws, 'not_found', 'Room not found. Check the code and ask the host to keep the room open.');
          if (room.peers.size >= maxPeers) return reject(ws, 'full', 'This room has no more connection slots.');
          ws.peer = room.nextPeer++;
        }
        clearTimeout(handshake);
        ws.room = room;
        room.peers.set(ws.peer, ws);
        send(ws, { op: 'welcome', code: room.code, peer: ws.peer });
        if (ws.peer !== 1) send(room.peers.get(1), { op: 'peer_joined', peer: ws.peer });
        return;
      }
      if (msg.op !== 'send' || !Number.isSafeInteger(msg.to) || typeof msg.payload !== 'string' || msg.payload.length > 90000 || !/^[A-Za-z0-9+/]*={0,2}$/.test(msg.payload)) return reject(ws, 'invalid', 'Invalid packet.');
      const isHost = ws.peer === 1;
      if ((!isHost && (msg.to !== 1 || !CLIENT_KINDS.has(msg.kind))) || (isHost && (!HOST_KINDS.has(msg.kind) || msg.to === 1 || msg.to < 0))) return reject(ws, 'authority', 'Packet sender is not authorized.');
      const targets = msg.to === 0 ? [...ws.room.peers.values()].filter(peer => peer !== ws) : [ws.room.peers.get(msg.to)].filter(Boolean);
      for (const target of targets) {
        if (isHost && msg.kind === 'state' && target.peer === msg.skip) continue;
        send(target, { op: 'packet', from: ws.peer, kind: msg.kind, payload: msg.payload }, msg.kind === 'state');
      }
    });
    ws.on('close', () => {
      clearTimeout(handshake);
      const room = ws.room;
      if (!room) return;
      room.peers.delete(ws.peer);
      if (ws.peer === 1) {
        rooms.delete(room.code);
        for (const peer of room.peers.values()) {
          peer.room = null;
          send(peer, { op: 'error', code: 'host_left', message: 'The host closed the room.' });
          peer.close(1000, 'The host closed the room.');
        }
        room.peers.clear();
      } else if (room.peers.has(1)) send(room.peers.get(1), { op: 'peer_left', peer: ws.peer });
      ws.room = null;
    });
  });
  const heartbeat = setInterval(() => {
    for (const ws of wss.clients) {
      if (!ws.alive) { ws.terminate(); continue; }
      ws.alive = false;
      ws.ping();
    }
  }, heartbeatMs);
  heartbeat.unref();
  return {
    server, rooms,
    listen: (port = 0, host = '127.0.0.1') => new Promise(resolve => server.listen(port, host, () => resolve(server.address()))),
    close: () => new Promise(resolve => {
      clearInterval(heartbeat);
      for (const ws of wss.clients) ws.terminate();
      wss.close(() => server.close(resolve));
    }),
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const relay = createRelay();
  const address = await relay.listen(Number(process.env.PORT || 8080), '0.0.0.0');
  console.log(`Downstack relay listening on port ${address.port}`);
  for (const signal of ['SIGTERM', 'SIGINT']) process.once(signal, async () => { await relay.close(); process.exit(0); });
}
