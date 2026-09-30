import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { getProjects } from '../src/lib/projects.js';

const base = '/the-data-decoded-visualizations/';
const dist = path.resolve('dist');
const projects = await getProjects();
assert.ok(projects.length >= 2, 'the aviation pilot and Somalia project should be published');
const pilot = projects.find((item) => item.slug === 'global-aviation-co2-emissions');
const somalia = projects.find((item) => item.slug === 'us-somalia-fragile-states-index');
assert.ok(pilot && somalia, 'both projects should be discovered from story.md');
assert.deepEqual(pilot.charts.map((chart) => chart.name), [
  'thumb.svg', 'seasonal_aviation_emissions.svg', 'international-share-area-chart.svg',
]);
assert.deepEqual(somalia.charts.map((chart) => chart.name), ['us_somalia_fragile_states_index.png'],
  'Somalia project should publish only its finished PNG');

const gallery = await readFile(path.join(dist, 'index.html'), 'utf8');
assert.ok(gallery.includes('class="site-name"') && gallery.includes('>The Data Decoded</a>'), 'collection is the header wordmark');
assert.ok(gallery.includes('<h1>Interesting questions, explored through data.</h1>'), 'gallery uses the chosen headline');
assert.ok(gallery.includes('By Markos Tsinganis'), 'gallery retains secondary author credit');

for (const item of projects) {
  const project = await readFile(path.join(dist, 'projects', item.slug, 'index.html'), 'utf8');
  assert.ok(gallery.includes(`${base}projects/${item.slug}/`), `gallery links to ${item.slug}`);
  assert.ok(gallery.includes(item.title) && gallery.includes(item.description),
    `gallery shows title and description for ${item.slug}`);
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

async function filesIn(dir, prefix = '') {
  const result = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const relative = path.posix.join(prefix, entry.name);
    result.push(...(entry.isDirectory() ? await filesIn(path.join(dir, entry.name), relative) : [relative]));
  }
  return result;
}
assert.deepEqual((await filesIn(dist)).sort(), [
  'index.html', 'styles.css',
  ...projects.map((item) => `projects/${item.slug}/index.html`),
  ...projects.flatMap((item) => item.charts.map((chart) => `chart/${item.slug}/${chart.name}`)),
].sort(), 'output contains only pages, CSS, and designated charts');

const fixture = await mkdtemp(path.resolve('node_modules', '.draft-check-'));
try {
  const draft = path.join(fixture, 'sample-draft');
  await mkdir(draft);
  await writeFile(path.join(draft, 'story.md'), '---\nstatus: draft\n---\nUnapproved copy');
  assert.deepEqual(await getProjects(fixture), [], 'draft stories must be excluded');
} finally {
  await rm(fixture, { recursive: true, force: true });
}

console.log('Verified two gallery entries, page order, full-size links, chart paths, draft exclusion, and output allowlist.');
