/** Assemble a clean, complete GitHub Pages artifact using Node's module parser.
 * Static ESM imports and re-exports are validated without executing game code.
 */
import { cp, mkdir, readdir, readFile, copyFile, rm } from 'node:fs/promises';
import { dirname, resolve, join, sep } from 'node:path';
import { SourceTextModule } from 'node:vm';

const output = resolve('dist');
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });

for (const file of ['index.html', 'style.css']) {
  await copyFile(file, join(output, file));
}
for (const entry of await readdir('.', { withFileTypes: true })) {
  if (entry.isFile() && /\.(?:js|mjs)$/.test(entry.name)) {
    await copyFile(entry.name, join(output, entry.name));
  }
}
for (const dir of ['assets', 'lib']) {
  await cp(dir, join(output, dir), { recursive: true });
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
  const source = await readFile(absolute, 'utf8');
  // Dynamic import() cannot be validated without running the page. Reject it
  // explicitly instead of silently shipping a potentially incomplete artifact.
  if (/\bimport\s*\(/.test(source)) {
    throw new Error('Dynamic import() is not supported by the static Pages verifier: ' + file);
  }
  const parsed = new SourceTextModule(source, { identifier: absolute });
  seen.add(absolute);
  // The parser covers static multiline imports AND export-from declarations.
  for (const specifier of parsed.dependencySpecifiers) {
    if (!specifier.startsWith('./') && !specifier.startsWith('../')) {
      throw new Error('Unbundled module import is not supported: ' + specifier);
    }
    await verifyModule(resolve(dirname(absolute), specifier));
  }
}
for (const source of sources) await verifyModule(resolve(output, source));

if (!seen.has(resolve(output, 'telegram-game.js'))) {
  throw new Error('Telegram game bridge is not reachable from the game entry point');
}
console.log('Pages artifact ready: ' + seen.size + ' ES modules verified');
