import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import assert from 'node:assert/strict';

const here = dirname(fileURLToPath(import.meta.url));
const svg = key => readFileSync(join(here, `${key}.svg`), 'utf8');
const normalized = source => source
  .replace(/aria-label="[^"]+"/, 'aria-label="comparison"')
  .replace(/\.title-(?:sans|serif)\{font-family:[^;]+;/, '.title{font-family:TITLE;')
  .replaceAll('class="title-sans"', 'class="title"')
  .replaceAll('class="title-serif"', 'class="title"');

for (const length of ['short', 'long']) {
  const a = svg(`a-${length}`);
  const b = svg(`b-${length}`);
  assert.equal(normalized(a), normalized(b), `${length}: changed beyond title family`);
  assert.equal((a.match(/class="title-sans"/g) || []).length, length === 'long' ? 3 : 1);
  assert.equal((b.match(/class="title-serif"/g) || []).length, length === 'long' ? 3 : 1);
}

for (const key of ['a-short', 'b-short', 'a-long', 'b-long']) {
  const source = svg(key);
  assert.match(source, /viewBox="0 0 360 640"/);
  assert.match(source, /\.\.\/fonts\/WorkSans-Regular\.ttf/);
  assert.doesNotMatch(source, /data:font|<image|fonts\.googleapis/i, `${key}: unexpected embedded or remote font`);
  const png = readFileSync(join(here, `${key}.png`));
  assert.equal(png.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
  assert.equal(png.readUInt32BE(16), 360);
  assert.equal(png.readUInt32BE(20), 640);
}

assert.equal(readdirSync(here).filter(name => /\.(?:ttf|otf|woff2?)$/i.test(name)).length, 0);
console.log('Verified archived A/B frames except title family; 4 SVGs with local Work Sans references and 4 phone-size PNG captures.');
