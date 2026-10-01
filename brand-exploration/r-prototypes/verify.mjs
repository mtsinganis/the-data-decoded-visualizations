import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const here = dirname(fileURLToPath(import.meta.url));
const names = ['ranked-short', 'ranked-long-before', 'ranked-long-after',
  'ranked-landscape', 'series-A', 'series-B', 'sequential-heatmap',
  'multipanel', 'annotated-tall', 'composition-A', 'composition-B'];
const aspects = {'ranked-short':.72,'ranked-long-before':.72,'ranked-long-after':.72,
  'ranked-landscape':2.6,'series-A':.76,'series-B':.76,'sequential-heatmap':.87,
  'multipanel':.86,'annotated-tall':.68,'composition-A':2.8,'composition-B':2.8};
const layout = JSON.parse(readFileSync(join(here, 'exports', 'layout.json'), 'utf8'));
assert.deepEqual(readdirSync(join(here,'exports')).sort(),
  [...names.flatMap(name=>[`${name}.png`,`${name}.svg`]),'layout.json'].sort(),
  'the current study exports only its eleven designated cases');
const logo = readFileSync(join(here, '..', 'pterosaur-simplified.svg'), 'utf8');
for (const filename of ['pterosaur-mark.svg', 'pterosaur-simplified.svg', 'pterosaur-compact.svg']) {
  const source = readFileSync(join(here, '..', filename), 'utf8');
  assert.match(source, /<path fill="#2455FF"/, `${filename}: working fill is confirmed blue`);
  assert.doesNotMatch(source, /#0062DF/i, `${filename}: old reference blue is absent`);
}
const [, intrinsicWidth, intrinsicHeight] = logo.match(/viewBox="[\d.]+ [\d.]+ ([\d.]+) ([\d.]+)"/) || [];
assert.ok(intrinsicWidth && intrinsicHeight, 'simplified mark has an intrinsic viewBox');
const intrinsicRatio = Number(intrinsicWidth) / Number(intrinsicHeight);
for (const name of names) {
  const landscape = name === 'ranked-landscape' || name.startsWith('composition-');
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
  assert.doesNotMatch(svg, />SYNTHETIC DATA</, `${name}: obsolete badge`);
  assert.doesNotMatch(svg, /@import|https?:\/\/fonts\./i);
  const rasterPlacements = [...svg.matchAll(/<image width='([\d.]+)' height='([\d.]+)' x='([\d.]+)'[^>]+preserveAspectRatio='xMidYMid meet'/g)];
  const [, width, height, logoX] = rasterPlacements.find(([, w, h]) =>
    Math.abs(Number(w) / Number(h) - intrinsicRatio) < .005) || [];
  assert.ok(width && height, `${name}: logo image has physical width, height, and meet rule`);
  const placedRatio = Number(width) / Number(height);
  assert.ok(Math.abs(placedRatio - intrinsicRatio) < 0.005,
    `${name}: placed logo ratio ${placedRatio} differs from intrinsic ${intrinsicRatio}`);
  const [, sourceX] = svg.match(/<text x='([\d.]+)'[^>]*>Source:/) || [];
  assert.ok(sourceX, `${name}: source text present`);
  assert.ok(Math.abs(Number(sourceX)-Number(logoX)) < .1, `${name}: signature aligns with source`);
  const metrics = layout[name];
  assert.ok(metrics, `${name}: measured frame metrics present`);
  assert.ok(metrics.title_size >= (landscape ? 27 : 31) &&
    metrics.title_size <= (landscape ? 30 : 35), `${name}: title size within range`);
  assert.ok(metrics.plot_bottom >= metrics.plot_bottom_limit - .01);
  assert.ok(metrics.plot_bottom + metrics.plot_height <= metrics.plot_top_limit + .01);
  assert.ok(metrics.plot_bottom_limit > metrics.source_top);
  assert.ok(metrics.source_top > metrics.divider_y);
  assert.equal(metrics.left, metrics.signature_x);
  assert.ok(Math.abs(metrics.plot_width / metrics.plot_height - aspects[name]) < .005);
  if (name.startsWith('ranked-') || name === 'annotated-tall') {
    assert.match(svg, /#A6B0BD/i, `${name}: provisional light context fill`);
    assert.match(svg, /#2455FF/i, `${name}: blue highlight`);
  }
  console.log(`${name}: ${landscape ? '1920×1080' : '1080×1920'} PNG, self-contained SVG, logo ${placedRatio.toFixed(3)} vs ${intrinsicRatio.toFixed(3)}`);
}
assert.equal(layout['ranked-short'].title_size, 35, 'short title retains its size');
assert.equal(layout['ranked-long-before'].title_size, 35, 'before title uses original size');
assert.equal(layout['ranked-long-after'].title_size, 31, 'after title stays within documented range');
assert.ok(layout['ranked-long-after'].title_lines < layout['ranked-long-before'].title_lines,
  'adaptive title reduces wrapping');
assert.deepEqual(layout['series-A'], layout['series-B'], 'line comparison holds layout constant');
assert.deepEqual(layout['composition-A'], layout['composition-B'], 'composition comparison holds layout constant');
const svgText = name => [...readFileSync(join(here,'exports',`${name}.svg`),'utf8')
  .matchAll(/<text[^>]*>(.*?)<\/text>/g)].map(match=>match[1]);
for(const kind of ['series','composition']){
  assert.deepEqual(svgText(`${kind}-A`),svgText(`${kind}-B`),
    `${kind} comparison holds chart and frame wording constant`);
}
assert.ok(layout.multipanel.source_lines + layout.multipanel.note_lines >
  layout['ranked-short'].source_lines + layout['ranked-short'].note_lines,
  'multiline footer consumes measured space');
assert.equal(layout.multipanel.subtitle_lines, 0, 'multipanel has no subtitle');
for (const key of ['series-A','series-B','multipanel','sequential-heatmap',
                   'composition-A','composition-B']) {
  for (const mode of ['protan','deutan','tritan','gray']) {
    const image = readFileSync(join(here,'..','r-prototypes','simulations',`${key}-${mode}.png`));
    assert.equal(image.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
    const landscape = key.startsWith('composition-');
    assert.equal(image.readUInt32BE(16), landscape ? 960 : 540);
    assert.equal(image.readUInt32BE(20), landscape ? 540 : 960);
  }
}

const palette = JSON.parse(readFileSync(join(here, '..', 'palette.json'), 'utf8'));
assert.equal(palette.brandBlue, '#2455FF');
assert.equal(palette.recommendedAccent, 'crimson');
assert.equal(palette.recommendedCategorical, 'B');
assert.equal(palette.categoricalBase.length, 8);
assert.equal(palette.categoricalB.length, 8);
assert.equal(palette.categoricalExtension12.length, 4);
assert.equal(palette.categoricalExtension16.length, 4);
const luminance = hex => {
  const rgb = hex.match(/[a-f\d]{2}/gi).map(v => parseInt(v, 16) / 255);
  const linear = rgb.map(v => v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4);
  return .2126 * linear[0] + .7152 * linear[1] + .0722 * linear[2];
};
const contrast = (a,b) => {const [x,y]=[luminance(a),luminance(b)].sort((x,y)=>y-x);return (x+.05)/(y+.05)};
const colorsA=[...palette.categoricalBase];colorsA[3]=palette.warmAccentCandidates.crimson;
for(const [choice,colors] of [['A',colorsA],['B',palette.categoricalB]]){
  assert.equal(colors[0],palette.brandBlue);
  assert.equal(colors[3],palette.warmAccentCandidates.crimson);
  const svg=readFileSync(join(here,'exports',`composition-${choice}.svg`),'utf8');
  for(let i=0;i<8;i++){
    const inkScore=contrast(colors[i],palette.ink), whiteScore=contrast(colors[i],'#FFFFFF');
    const matches=[...svg.matchAll(new RegExp(`<text[^>]+fill: (#[A-Fa-f0-9]{6})[^>]*>C${i+1}<\\/text>`,'g'))];
    if(i===1||i===2){
      assert.equal(matches.length,1,`${choice} C${i+1} uses one outside label`);
      assert.equal(matches[0][1].toUpperCase(),palette.ink,`${choice} outside label uses ink`);
    }else{
      assert.equal(matches.length,5,`${choice} C${i+1} has five inside labels`);
      const expected=inkScore>=whiteScore?palette.ink:'#FFFFFF';
      assert.ok(Math.max(inkScore,whiteScore)>=4.5,`${choice} C${i+1} fails inside-label contrast`);
      assert.ok(matches.every(m=>m[1].toUpperCase()===expected),`${choice} C${i+1} label color`);
    }
    console.log(`${choice} C${i+1} ${colors[i]}: ink ${inkScore.toFixed(2)}:1, white ${whiteScore.toFixed(2)}:1${i===1||i===2?' (outside label)':''}`);
  }
}
for (const [name,hex] of Object.entries({blue:palette.brandBlue,vermilion:palette.warmAccentCandidates.vermilion,crimson:palette.warmAccentCandidates.crimson,ink:palette.ink,slate:palette.slate})) {
  console.log(`${name} on paper: ${contrast(hex,palette.paper).toFixed(2)}:1; on white: ${contrast(hex,'#FFFFFF').toFixed(2)}:1`);
}
