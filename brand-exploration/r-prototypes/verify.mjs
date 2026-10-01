import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const here = dirname(fileURLToPath(import.meta.url));
const names = ['ranked-short', 'ranked-long', 'ranked-landscape', 'series-vermilion', 'series-crimson', 'sequential-heatmap'];
const logo = readFileSync(join(here, '..', 'pterosaur-simplified.svg'), 'utf8');
const [, intrinsicWidth, intrinsicHeight] = logo.match(/viewBox="[\d.]+ [\d.]+ ([\d.]+) ([\d.]+)"/) || [];
assert.ok(intrinsicWidth && intrinsicHeight, 'simplified mark has an intrinsic viewBox');
const intrinsicRatio = Number(intrinsicWidth) / Number(intrinsicHeight);
for (const name of names) {
  const landscape = name === 'ranked-landscape';
  const png = readFileSync(join(here, 'exports', `${name}.png`));
  assert.equal(png.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
  assert.equal(png.readUInt32BE(16), landscape ? 1920 : 1080);
  assert.equal(png.readUInt32BE(20), landscape ? 1080 : 1920);
  const svg = readFileSync(join(here, 'exports', `${name}.svg`), 'utf8');
  assert.match(svg, landscape ? /viewBox='0 0 960\.00 540\.00'/ : /viewBox='0 0 540\.00 960\.00'/);
  assert.match(svg, /font-family: "Work Sans"/);
  assert.equal((svg.match(/data:font\/ttf;base64,/g) || []).length, 3);
  assert.match(svg, /THE DATA DECODED/);
  assert.match(svg, /synthetic demonstration data/);
  assert.doesNotMatch(svg, /@import|https?:\/\/fonts\./i);
  const [, width, height] = svg.match(/<image width='([\d.]+)' height='([\d.]+)'[^>]+preserveAspectRatio='xMidYMid meet'/) || [];
  assert.ok(width && height, `${name}: logo image has physical width, height, and meet rule`);
  const placedRatio = Number(width) / Number(height);
  assert.ok(Math.abs(placedRatio - intrinsicRatio) < 0.005,
    `${name}: placed logo ratio ${placedRatio} differs from intrinsic ${intrinsicRatio}`);
  if (name.startsWith('ranked-')) {
    assert.match(svg, /#A6B0BD/i, `${name}: provisional light context fill`);
    assert.match(svg, /#2455FF/i, `${name}: blue highlight`);
  }
  console.log(`${name}: ${landscape ? '1920×1080' : '1080×1920'} PNG, self-contained SVG, logo ${placedRatio.toFixed(3)} vs ${intrinsicRatio.toFixed(3)}`);
}

const palette = JSON.parse(readFileSync(join(here, '..', 'palette.json'), 'utf8'));
assert.equal(palette.brandBlue, '#2455FF');
assert.equal(palette.categoricalBase.length, 8);
assert.equal(palette.categoricalExtension12.length, 4);
assert.equal(palette.categoricalExtension16.length, 4);
const luminance = hex => {
  const rgb = hex.match(/[a-f\d]{2}/gi).map(v => parseInt(v, 16) / 255);
  const linear = rgb.map(v => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4);
  return .2126 * linear[0] + .7152 * linear[1] + .0722 * linear[2];
};
const contrast = (a,b) => {const [x,y]=[luminance(a),luminance(b)].sort((x,y)=>y-x);return (x+.05)/(y+.05)};
for (const [name,hex] of Object.entries({blue:palette.brandBlue,vermilion:palette.warmAccentCandidates.vermilion,crimson:palette.warmAccentCandidates.crimson,ink:palette.ink,slate:palette.slate})) {
  console.log(`${name} on paper: ${contrast(hex,palette.paper).toFixed(2)}:1; on white: ${contrast(hex,'#FFFFFF').toFixed(2)}:1`);
}
