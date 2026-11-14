// npm ci --prefix relay; GODOT_BIN=/path/to/godot node tests/run_room_tests.mjs
import { spawn } from 'node:child_process';
import { mkdtemp, mkdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRelay } from '../relay/server.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const scratch = await mkdtemp(path.join(tmpdir(), 'downstack-rooms-'));
const relay = createRelay();
const { port } = await relay.listen();
const children = [];
const results = [];
let code;
let watching = false;
let launchFailed;
function launch(role) {
  const env = { ...process.env, APPDATA: path.join(scratch, role), XDG_DATA_HOME: path.join(scratch, role), XDG_CONFIG_HOME: path.join(scratch, role) };
  const args = ['--headless', '--path', root, '--script', 'tests/room_test.gd', '--', `--role=${role}`, `--url=ws://127.0.0.1:${port}/rooms`];
  if (code) args.push(`--code=${code}`);
  const child = spawn(process.env.GODOT_BIN || 'godot', args, { env, windowsHide: true });
  children.push(child);
  let output = '';
  const done = new Promise(resolve => {
    child.on('error', error => { launchFailed = error; resolve({ role, exit: -1, output: String(error) }); });
    child.on('exit', exit => resolve({ role, exit, output }));
  });
  results.push(done);
  const receive = data => {
    output += data;
    if (role !== 'host') return;
    if (!code && /ROOM_CODE=([A-Z2-9-]+)/.test(output)) {
      code = output.match(/ROOM_CODE=([A-Z2-9-]+)/)[1];
      launch('player'); launch('remote');
    }
    if (!watching && output.includes('ROUND=1')) { watching = true; launch('watch'); }
  };
  child.stdout.on('data', receive); child.stderr.on('data', receive);
  return done;
}
const timeout = setTimeout(() => { for (const child of children) child.kill(); }, 25000);
try {
  await mkdir(path.join(scratch, 'host'), { recursive: true });
  const ui = await new Promise(resolve => {
    const child = spawn(process.env.GODOT_BIN || 'godot', ['--headless', '--path', root, '--script', 'tests/room_ui_test.gd', '--', `--url=ws://127.0.0.1:${port}/rooms`], { env: { ...process.env, APPDATA: path.join(scratch, 'ui'), XDG_DATA_HOME: path.join(scratch, 'ui'), XDG_CONFIG_HOME: path.join(scratch, 'ui') }, windowsHide: true });
    children.push(child);
    let output = '';
    child.stdout.on('data', data => { output += data; });
    child.stderr.on('data', data => { output += data; });
    child.on('error', error => resolve({ exit: -1, output: String(error) }));
    child.on('exit', exit => resolve({ exit, output }));
  });
  console.log(JSON.stringify({ role: 'ui', ...ui }));
  if (ui.exit !== 0 || !ui.output.includes('0 failures') || /SCRIPT ERROR|FAIL:/.test(ui.output)) throw new Error('Room UI tests failed');
  await launch('host');
  const completed = await Promise.all(results);
  for (const result of completed) console.log(JSON.stringify(result));
  if (launchFailed || completed.length !== 4 || completed.some(r => r.exit !== 0 || !r.output.includes(`${r.role} ROOM PASS`) || /SCRIPT ERROR| FAIL /.test(r.output))) process.exitCode = 1;
} finally {
  clearTimeout(timeout);
  for (const child of children) if (child.exitCode === null) child.kill();
  await relay.close();
  if (path.dirname(path.resolve(scratch)) !== path.resolve(tmpdir()) || !path.basename(scratch).startsWith('downstack-rooms-')) throw new Error('Unexpected test directory');
  await rm(scratch, { recursive: true, force: true });
}
