import test from 'node:test';
import assert from 'node:assert/strict';
import { WebSocket } from 'ws';
import { createRelay, normalizeCode } from '../server.mjs';

async function fixture(t, options = {}) {
  const relay = createRelay(options);
  const { port } = await relay.listen();
  t.after(() => relay.close());
  const peers = [];
  t.after(() => { for (const peer of peers) peer.ws.terminate(); });
  async function connect(op = 'create', extra = {}) {
    const ws = new WebSocket(`ws://127.0.0.1:${port}/rooms`);
    const messages = [];
    const waiters = [];
    ws.on('error', () => {});
    ws.on('message', raw => {
      const message = JSON.parse(raw);
      const at = waiters.findIndex(w => w.predicate(message));
      if (at >= 0) { const [w] = waiters.splice(at, 1); clearTimeout(w.timer); w.resolve(message); }
      else messages.push(message);
    });
    const peer = {
      ws, messages,
      send: data => ws.send(JSON.stringify(data)),
      wait: predicate => {
        const at = messages.findIndex(predicate);
        if (at >= 0) return Promise.resolve(messages.splice(at, 1)[0]);
        return new Promise((resolve, reject) => {
          const waiter = { predicate, resolve, timer: setTimeout(() => reject(new Error('Message timed out')), 3000) };
          waiters.push(waiter);
        });
      },
    };
    peers.push(peer);
    await new Promise((resolve, reject) => { ws.once('open', resolve); ws.once('error', reject); });
    if (op) peer.send({ op, wire: 1, protocol: 4, ...extra });
    return peer;
  }
  return { relay, connect, port };
}
const op = name => message => message.op === name;
const payload = Buffer.from('opaque game packet').toString('base64');

test('room codes are readable, normalized and unique', async t => {
  const f = await fixture(t);
  const first = await (await f.connect()).wait(op('welcome'));
  const second = await (await f.connect()).wait(op('welcome'));
  assert.match(first.code, /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$/);
  assert.equal(first.peer, 1);
  assert.notEqual(first.code, second.code);
  assert.equal(normalizeCode('  abcd-efgh\n'), 'ABCDEFGH');
  const joined = await (await f.connect('join', { code: first.code.toLowerCase().slice(0, 4) + '-' + first.code.slice(4) })).wait(op('welcome'));
  assert.equal(joined.code, first.code);
  assert.equal(joined.peer, 2);
});

test('host routes broadcasts and targeted packets within its room only', async t => {
  const f = await fixture(t);
  const host = await f.connect();
  const { code } = await host.wait(op('welcome'));
  const guest = await f.connect('join', { code });
  const spectator = await f.connect('join', { code });
  const outside = await f.connect();
  const guestId = (await guest.wait(op('welcome'))).peer;
  await spectator.wait(op('welcome'));
  await outside.wait(op('welcome'));
  await host.wait(op('peer_joined'));
  host.send({ op: 'send', to: 0, kind: 'lobby', payload });
  assert.equal((await guest.wait(op('packet'))).from, 1);
  assert.equal((await spectator.wait(op('packet'))).payload, payload);
  host.send({ op: 'send', to: guestId, kind: 'start', payload });
  assert.equal((await guest.wait(op('packet'))).kind, 'start');
  host.send({ op: 'ping' }); await host.wait(op('pong'));
  assert.equal(outside.messages.filter(op('packet')).length, 0);
  assert.equal(spectator.messages.filter(op('packet')).length, 0);
  host.send({ op: 'send', to: 0, skip: guestId, kind: 'state', payload });
  assert.equal((await spectator.wait(op('packet'))).kind, 'state');
  assert.equal(guest.messages.filter(op('packet')).length, 0);
});

test('client submissions identify the actual sender', async t => {
  const f = await fixture(t);
  const host = await f.connect();
  const { code } = await host.wait(op('welcome'));
  const client = await f.connect('join', { code });
  const { peer } = await client.wait(op('welcome'));
  client.send({ op: 'send', to: 1, from: 1, kind: 'attack', payload });
  assert.equal((await host.wait(op('packet'))).from, peer);
});

test('clients cannot impersonate host or broadcast to other players', async t => {
  const f = await fixture(t);
  const host = await f.connect();
  const { code } = await host.wait(op('welcome'));
  for (const forged of [{ to: 0, kind: 'attack' }, { to: 1, kind: 'start' }]) {
    const client = await f.connect('join', { code });
    await client.wait(op('welcome'));
    client.send({ op: 'send', ...forged, payload });
    assert.equal((await client.wait(op('error'))).code, 'authority');
  }
  assert.equal(host.messages.filter(op('packet')).length, 0);
});

test('wrong code and incompatible version have actionable errors', async t => {
  const f = await fixture(t);
  assert.equal((await (await f.connect('join', { code: 'ZZZZZZZZ' })).wait(op('error'))).code, 'not_found');
  assert.equal((await (await f.connect('create', { protocol: 3 })).wait(op('error'))).code, 'version');
  assert.equal(f.relay.rooms.size, 0);
});

test('room capacity rejects excess peers without disrupting existing clients', async t => {
  const f = await fixture(t, { maxPeers: 2 });
  const host = await f.connect();
  const { code } = await host.wait(op('welcome'));
  await (await f.connect('join', { code })).wait(op('welcome'));
  assert.equal((await (await f.connect('join', { code })).wait(op('error'))).code, 'full');
  assert.equal(f.relay.rooms.get(code).peers.size, 2);
});

test('host departure invalidates the code and closes the entire room', async t => {
  const f = await fixture(t);
  const host = await f.connect();
  const { code } = await host.wait(op('welcome'));
  const guest = await f.connect('join', { code });
  await guest.wait(op('welcome'));
  host.ws.close();
  assert.equal((await guest.wait(op('error'))).code, 'host_left');
  assert.equal(f.relay.rooms.has(code), false);
  assert.equal((await (await f.connect('join', { code })).wait(op('error'))).code, 'not_found');
});

test('client departure frees capacity and notifies the host', async t => {
  const f = await fixture(t, { maxPeers: 2 });
  const host = await f.connect();
  const { code } = await host.wait(op('welcome'));
  const guest = await f.connect('join', { code });
  const { peer } = await guest.wait(op('welcome'));
  guest.ws.close();
  assert.equal((await host.wait(op('peer_left'))).peer, peer);
  assert.ok((await (await f.connect('join', { code })).wait(op('welcome'))).peer > peer);
});

test('malformed packets and repeated room requests are rejected', async t => {
  const f = await fixture(t);
  for (const message of ['{', 'null', '[]']) {
    const client = await f.connect(null);
    client.ws.send(message);
    assert.equal((await client.wait(op('error'))).code, 'invalid');
  }
  const host = await f.connect(); await host.wait(op('welcome'));
  host.send({ op: 'create', wire: 1, protocol: 4 });
  assert.equal((await host.wait(op('error'))).code, 'invalid');
});

test('room limit bounds server resources', async t => {
  const f = await fixture(t, { maxRooms: 1 });
  await (await f.connect()).wait(op('welcome'));
  assert.equal((await (await f.connect()).wait(op('error'))).code, 'busy');
  assert.equal(f.relay.rooms.size, 1);
});

test('connection limit rejects excess upgrades', async t => {
  const f = await fixture(t, { maxConnections: 2 });
  await (await f.connect()).wait(op('welcome'));
  await (await f.connect()).wait(op('welcome'));
  await assert.rejects(f.connect(null), /503/);
});

test('message flood closes the offending connection', async t => {
  const f = await fixture(t);
  const host = await f.connect();
  await host.wait(op('welcome'));
  for (let i = 0; i < 400; i++) host.send({ op: 'ping' });
  assert.equal((await host.wait(op('error'))).code, 'rate_limit');
});

test('health check is available without exposing codes', async t => {
  const f = await fixture(t);
  const response = await fetch(`http://127.0.0.1:${f.port}/healthz`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { service: 'downstack-rooms', version: 1, ok: true });
});
