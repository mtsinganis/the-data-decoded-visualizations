import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, readdir, rm, stat, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { getDraftProjects, getProjects } from '../src/lib/projects.js';

const base = '/the-data-decoded-visualizations/';
const dist = path.resolve('dist');
const docs = path.resolve('../docs');
const projects = await getProjects();
const config = await readFile('astro.config.mjs', 'utf8');
assert.match(config, /site:\s*'https:\/\/mtsinganis\.github\.io'/);
assert.match(config, /base:\s*'\/the-data-decoded-visualizations\/'/);
assert.ok(projects.length >= 16, 'the 16 existing published stories must remain available');
const draftSlugs = new Set((await getDraftProjects()).map((item) => item.slug));
assert.ok(draftSlugs.has('venezuela-refugees-maduro'), 'Venezuela must remain a draft');
for (const folder of ['2025-01-airbnb-demand', '2025-11-04-str-europe-peak-season', '2026-04-denmark-tax-revenue-burden']) {
  assert.ok(!projects.some((item) => item.folder === folder), `${folder} must stay out of the gallery`);
}
const pilot = projects.find((item) => item.slug === 'global-aviation-co2-emissions');
const somalia = projects.find((item) => item.slug === 'us-somalia-fragile-states-index');
assert.ok(pilot && somalia, 'both projects should be discovered from story.md');
assert.deepEqual(pilot.charts.map((chart) => chart.name), [
  'thumb.svg', 'seasonal_aviation_emissions.svg', 'international-share-area-chart.svg',
]);
assert.deepEqual(somalia.charts.map((chart) => chart.name), ['us_somalia_fragile_states_index.png'],
  'Somalia project should publish only its finished PNG');

const gallery = await readFile(path.join(dist, 'index.html'), 'utf8');
const htmlText = (value) => value.replaceAll('&', '&amp;').replaceAll("'", '&#39;').replaceAll('"', '&quot;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
assert.ok(gallery.includes('class="site-name"') && gallery.includes('alt="The Data Decoded — homepage"'), 'collection is the header wordmark');
assert.ok(gallery.includes('<h1>Interesting questions, explored through data.</h1>'), 'gallery uses the chosen headline');
assert.ok(gallery.includes('By Markos Tsinganis'), 'gallery retains secondary author credit');
assert.equal((gallery.match(/>Follow on X<\/a>/g) || []).length, 2, 'header and footer expose confirmed X profile');
const firstProject = gallery.match(/href="[^"]*\/projects\/([^/]+)\/"/);
assert.equal(firstProject?.[1], projects[0].slug, 'gallery follows project ordering');
for (const file of ['Lato-Regular.ttf', 'Lato-Bold.ttf', 'Lato-OFL.txt']) {
  assert.deepEqual(await readFile(path.join(dist, 'fonts', file)), await readFile(path.resolve('../assets/fonts/lato', file)), 'public Lato must match licensed asset');
}
assert.deepEqual(await readFile(path.join(dist, 'brand/the-data-decoded-lockup.svg')), await readFile(path.resolve('../assets/brand/the-data-decoded-lockup.svg')), 'public logo matches permanent asset');


for (const item of projects) {
  const project = await readFile(path.join(dist, 'projects', item.slug, 'index.html'), 'utf8');
  assert.ok(gallery.includes(`${base}projects/${item.slug}/`), `gallery links to ${item.slug}`);
  assert.ok(gallery.includes(htmlText(item.title)) && gallery.includes(htmlText(item.description)),
    `gallery shows title and description for ${item.slug}`);
  assert.equal(project.includes('Discuss this chart on X'), Boolean(item.xPostUrl), 'discussion links require a published X post');
  assert.ok(project.includes('By Markos Tsinganis'), `${item.slug} retains author credit`);
  const positions = [
    project.indexOf('<h1>'),
    project.indexOf('class="lede"'),
    project.indexOf('aria-label="Introduction"'),
    project.indexOf('class="charts"'),
    project.indexOf('id="sources-heading"'),
  ];
  assert.ok(positions.every((position, index) => position >= 0 && (index === 0 || position > positions[index - 1])),
    `${item.slug} sections must be title, description, introduction, charts, sources`);
  const imagePaths = item.charts.map((chart) => `${base}chart/${item.slug}/${chart.name}`);
  let previous = -1;
  for (const imagePath of imagePaths) {
    const position = project.indexOf(imagePath);
    assert.ok(position > previous, `chart order or path is wrong: ${imagePath}`);
    previous = position;
    assert.ok((await readFile(path.join(dist, 'chart', item.slug, path.basename(imagePath)))).length > 0);
  }
  assert.equal((project.match(/aria-label="View full-size chart /g) || []).length, item.charts.length,
    `${item.slug} needs one accessible full-size link per chart`);
}
assert.ok(!gallery.includes(`chart/${somalia.slug}/thumb.svg`), 'Somalia gallery must use the PNG');
for (const slug of draftSlugs) {
  assert.ok(!gallery.includes(`${base}projects/${slug}/`), `${slug} draft must stay out of gallery`);
}
const somaliaPage = await readFile(path.join(dist, 'projects', somalia.slug, 'index.html'), 'utf8');
assert.ok(!somaliaPage.includes(`chart/${somalia.slug}/thumb.svg`), 'Somalia project must use the PNG');

async function filesIn(dir, prefix = '') {
  const result = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const relative = path.posix.join(prefix, entry.name);
    result.push(...(entry.isDirectory() ? await filesIn(path.join(dir, entry.name), relative) : [relative]));
  }
  return result;
}
const expected = new Set([
  'index.html', 'styles.css', 'fonts/Lato-Regular.ttf', 'fonts/Lato-Bold.ttf', 'fonts/Lato-OFL.txt', 'brand/the-data-decoded-lockup.svg',
  ...projects.map((item) => `projects/${item.slug}/index.html`),
  ...projects.flatMap((item) => item.charts.map((chart) => `chart/${item.slug}/${chart.name}`)),
]);

function localTarget(source, url) {
  if (!url || /^(?:#|[a-z][a-z\d+.-]*:|\/\/)/i.test(url)) return null;
  const clean = decodeURIComponent(url.split(/[?#]/, 1)[0]);
  if (!clean) return null;
  const result = clean.startsWith(base) ? clean.slice(base.length) :
    clean.startsWith('/') ? null : path.posix.normalize(path.posix.join(path.posix.dirname(source), clean));
  assert.ok(result && !result.startsWith('../') && !path.posix.isAbsolute(result), `invalid local URL in ${source}: ${url}`);
  return result.endsWith('/') ? `${result}index.html` : result;
}

function references(text) {
  const refs = [...text.matchAll(/\b(?:src|href)\s*=\s*["']([^"']+)["']/gi)].map((match) => match[1]);
  for (const match of text.matchAll(/\bsrcset\s*=\s*["']([^"']+)["']/gi)) {
    refs.push(...match[1].split(',').map((part) => part.trim().split(/\s+/)[0]));
  }
  return refs;
}

const legacyRoot = path.join(docs, 'visuals');
const folders = await readdir(legacyRoot, { withFileTypes: true });
let legacyCount = 0;
const redirects = new Set();
for (const entry of folders.filter((item) => item.isDirectory())) {
  const relative = `visuals/${entry.name}/index.html`;
  let original;
  try { original = await readFile(path.join(docs, relative), 'utf8'); }
  catch (error) { if (error.code === 'ENOENT') continue; throw error; }
  expected.add(relative);
  const output = await readFile(path.join(dist, relative), 'utf8');
  const migrated = projects.find((item) => item.folder === entry.name);
  if (migrated) {
    const destination = `${base}projects/${migrated.slug}/`;
    assert.ok(output.includes(`content="0; url=${destination}"`), `${relative} must redirect to its new route`);
    assert.ok(output.includes(`href="${destination}"`), `${relative} needs a visible fallback link`);
    redirects.add(migrated.folder);
    continue;
  }
  legacyCount++;
  assert.equal(output, original.replaceAll('href="../../styles.css"', 'href="../../legacy-styles.css"'),
    `${relative} must preserve its rendered legacy page, apart from the CSS collision`);
  for (const url of references(output)) {
    const target = localTarget(relative, url);
    if (!target || target === 'index.html') continue;
    assert.ok((await stat(path.join(dist, target))).isFile(), `${relative} has a broken local reference: ${url}`);
    if (!target.endsWith('.html')) expected.add(target);
  }
}
for (const item of projects.filter((project) => !redirects.has(project.folder))) {
  const relative = `visuals/${item.folder}/index.html`;
  const output = await readFile(path.join(dist, relative), 'utf8');
  const destination = `${base}projects/${item.slug}/`;
  assert.ok(output.includes(`content="0; url=${destination}"`) && output.includes(`href="${destination}"`),
    `${relative} needs a redirect and visible fallback link`);
  expected.add(relative);
}
assert.ok(legacyCount > 0, 'unmigrated legacy pages must remain available');
assert.equal(legacyCount + redirects.size, 20, 'all 20 existing project routes must be covered');
assert.ok(legacyCount >= 3, 'the three archived exceptions should retain rendered pages');
for (const item of projects) {
  for (const chart of item.charts) {
    const relative = `visuals/${item.folder}/plots/${chart.name}`;
    assert.deepEqual(await readFile(path.join(dist, relative)), await readFile(chart.file),
      `${relative} must preserve the designated chart at its old direct URL`);
    expected.add(relative);
  }
}
const somaliaSvg = `visuals/${somalia.folder}/plots/thumb.svg`;
assert.deepEqual(await readFile(path.join(dist, somaliaSvg)),
  await readFile(path.resolve('..', somaliaSvg)),
  'the single Somalia SVG compatibility asset must match the original export byte for byte');
expected.add(somaliaSvg);
assert.equal((await readFile(path.join(dist, 'legacy-styles.css'), 'utf8')), await readFile(path.join(docs, 'styles.css'), 'utf8'));
expected.add('search.json'); // Quarto search loads this file dynamically.
assert.equal((await readFile(path.join(dist, 'search.json'), 'utf8')), await readFile(path.join(docs, 'search.json'), 'utf8'));
for (const relative of [...expected].filter((file) => file.endsWith('.css') && file !== 'styles.css')) {
  const css = await readFile(path.join(dist, relative), 'utf8');
  for (const match of css.matchAll(/url\(["']?([^"')]+)["']?\)/gi)) {
    const target = localTarget(relative, match[1]);
    if (!target) continue;
    assert.ok((await stat(path.join(dist, target))).isFile(), `${relative} has a broken CSS asset: ${match[1]}`);
    expected.add(target);
  }
}
assert.ok(!(await filesIn(dist)).some((file) => file.startsWith('draft/') || file.startsWith('draft-chart/')),
  'draft routes and charts must be absent from production');
assert.deepEqual((await filesIn(dist)).sort(), [...expected].sort(),
  'public output must contain only Astro pages, designated charts, legacy pages, and required legacy assets');

const fixture = await mkdtemp(path.resolve('node_modules', '.draft-check-'));
try {
  const draft = path.join(fixture, 'sample-draft');
  await mkdir(draft);
  await mkdir(path.join(draft, 'plots'));
  await writeFile(path.join(draft, 'plots', 'draft.svg'), '<svg xmlns="http://www.w3.org/2000/svg"/>');
  await writeFile(path.join(draft, 'story.md'), '---\ntitle: "Unapproved"\nslug: sample-draft\nstatus: draft\ncharts:\n  - file: plots/draft.svg\n    alt: Unapproved chart\n---\nUnapproved copy');
  assert.deepEqual(await getProjects(fixture), [], 'draft stories must be excluded');
  const previews = await getDraftProjects(fixture);
  assert.equal(previews.length, 1, 'draft story must be available to local preview');
  assert.equal(previews[0].charts[0].name, 'draft.svg');
} finally {
  await rm(fixture, { recursive: true, force: true });
}

console.log(`Verified ${projects.length} published projects, ${legacyCount} preserved legacy pages, ${projects.length} redirects, local assets, draft exclusion, base paths, and output allowlist.`);
