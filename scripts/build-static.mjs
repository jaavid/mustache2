/** Assemble the complete GitHub Pages asset tree and fail on missing local ES modules.
 * Keep this as the single build path for both PR checks and production deploys.
 */
import { cp, mkdir, readdir, readFile, copyFile, stat } from 'node:fs/promises';
import { dirname, resolve, join, sep } from 'node:path';

const output = resolve('dist');
await mkdir(output, { recursive: true });
for (const file of ['index.html', 'style.css']) {
  await copyFile(file, join(output, file));
}
for (const entry of await readdir('.', { withFileTypes: true })) {
  if (entry.isFile() && entry.name.endsWith('.js')) {
    await copyFile(entry.name, join(output, entry.name));
  }
}
for (const dir of ['assets', 'lib']) {
  await cp(dir, join(output, dir), { recursive: true, force: true });
}

const html = await readFile(join(output, 'index.html'), 'utf8');
const sources = [...html.matchAll(/<script\b[^>]*\bsrc=["']([^"']+)["']/g)]
  .map(match => match[1]).filter(src => src.startsWith('.'));
if (sources.length === 0) throw new Error('No local entry point found in index.html');

const seen = new Set();
async function verifyModule(file) {
  const absolute = resolve(file);
  if (!absolute.startsWith(output + sep)) {
    throw new Error('Module escapes the published directory: ' + file);
  }
  if (seen.has(absolute)) return;
  seen.add(absolute);
  await stat(absolute);
  const source = await readFile(absolute, 'utf8');
  // Static, relative ES module imports used by the game. Track the entire
  // dependency graph so a new module cannot silently disappear from Pages.
  const imports = [...source.matchAll(/(?:^|\n)\s*import\s+(?:[^\n;]*?\s+from\s*)?["'](\.[^"']+)["']/g)];
  for (const match of imports) {
    await verifyModule(resolve(dirname(absolute), match[1]));
  }
}
for (const source of sources) await verifyModule(resolve(output, source));

// Fail before deploying if the Telegram bridge is omitted from the artifact.
if (!seen.has(resolve(output, 'telegram-game.js'))) {
  throw new Error('Telegram game bridge is not reachable from the game entry point');
}
console.log('Pages artifact ready: ' + seen.size + ' ES modules verified');
