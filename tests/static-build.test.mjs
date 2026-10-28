import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const buildScript = fileURLToPath(new URL('../scripts/build-static.mjs', import.meta.url));

async function fixture(t, gameSource, files = {}) {
  const root = await mkdtemp(join(tmpdir(), 'mustache2-pages-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  await mkdir(join(root, 'assets'));
  await mkdir(join(root, 'lib'));
  await writeFile(join(root, 'index.html'), '<script type="module" src="./game.js"></script>');
  await writeFile(join(root, 'style.css'), 'body {}');
  await writeFile(join(root, 'game.js'), gameSource);
  await writeFile(join(root, 'telegram-game.js'), 'export const bridge = true;');
  for (const [name, content] of Object.entries(files)) {
    await mkdir(dirname(join(root, name)), { recursive: true });
    await writeFile(join(root, name), content);
  }
  return root;
}

function runBuild(root) {
  return spawnSync(process.execPath, ['--experimental-vm-modules', buildScript], {
    cwd: root,
    encoding: 'utf8',
  });
}

test('static build verifies multiline imports and re-exports including mjs', async t => {
  const root = await fixture(t, [
    'import {',
    '  bridge',
    '} from "./telegram-game.js";',
    'export { helper } from "./lib/helper.mjs";',
    'console.log(bridge);',
  ].join('\n'), { 'lib/helper.mjs': 'export const helper = true;' });
  const result = runBuild(root);
  assert.equal(result.status, 0, result.stderr);
  assert.match(await readFile(join(root, 'dist/game.js'), 'utf8'), /telegram-game/);
  assert.match(await readFile(join(root, 'dist/lib/helper.mjs'), 'utf8'), /helper/);
});

test('static build clears stale dist and fails if an imported module disappears', async t => {
  const root = await fixture(t,
    'import "./telegram-game.js"; export * from "./extra.mjs";',
    { 'extra.mjs': 'export const extra = true;' });
  assert.equal(runBuild(root).status, 0);
  await rm(join(root, 'extra.mjs'));
  const result = runBuild(root);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /ENOENT/);
  await assert.rejects(readFile(join(root, 'dist/extra.mjs'), 'utf8'), /ENOENT/);
});

test('static build rejects dynamic imports instead of silently ignoring them', async t => {
  const root = await fixture(t, 'import "./telegram-game.js"; import("./lazy.mjs");');
  const result = runBuild(root);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /Dynamic import/);
});
