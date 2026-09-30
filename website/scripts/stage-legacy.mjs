import { copyFile, mkdir, readFile, readdir, stat, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { getProjects } from '../src/lib/projects.js';

const docs = path.resolve('../docs');
const dist = path.resolve('dist');
const base = '/the-data-decoded-visualizations/';
const allowedAssets = new Set(['.css', '.js', '.png', '.svg', '.jpg', '.jpeg', '.webp', '.gif', '.woff', '.woff2', '.ttf', '.ico']);
const assets = new Set();
const pages = new Set();
const cssToInspect = new Set();

function outputName(relative) {
  return relative === 'styles.css' ? 'legacy-styles.css' : relative;
}

async function exists(file) {
  try { return (await stat(file)).isFile(); }
  catch (error) { if (error.code === 'ENOENT') return false; throw error; }
}

function localReference(source, url) {
  if (!url || /^(?:#|[a-z][a-z\d+.-]*:|\/\/)/i.test(url)) return null;
  const clean = decodeURIComponent(url.split(/[?#]/, 1)[0]);
  if (!clean) return null;
  const relative = clean.startsWith('/')
    ? clean.startsWith(base) ? clean.slice(base.length) : null
    : path.posix.normalize(path.posix.join(path.posix.dirname(source), clean));
  if (relative === null) throw new Error(`${source}: unexpected absolute site path ${url}`);
  if (relative === '..' || relative.startsWith('../') || path.posix.isAbsolute(relative)) {
    throw new Error(`${source}: path escapes docs: ${url}`);
  }
  return relative.endsWith('/') ? `${relative}index.html` : relative;
}

async function addReference(source, url) {
  const relative = localReference(source, url);
  if (!relative) return;
  if (relative === 'index.html') return; // Astro supplies the home page.
  const extension = path.posix.extname(relative).toLowerCase();
  if (extension === '.html') {
    if (!pages.has(relative)) throw new Error(`${source}: missing legacy page ${url}`);
    return;
  }
  if (relative === 'search.json') {
    assets.add(relative); // Quarto's search script fetches its generated page index.
    return;
  }
  if (!allowedAssets.has(extension)) {
    throw new Error(`${source}: required legacy file is not allowed in the public output: ${url}`);
  }
  if (!(await exists(path.join(docs, relative)))) {
    throw new Error(`${source}: required legacy asset is missing: ${url}`);
  }
  assets.add(relative);
  if (extension === '.css') cssToInspect.add(relative);
}

function htmlReferences(html) {
  const result = [];
  for (const match of html.matchAll(/\b(?:src|href)\s*=\s*["']([^"']+)["']/gi)) result.push(match[1]);
  for (const match of html.matchAll(/\bsrcset\s*=\s*["']([^"']+)["']/gi)) {
    result.push(...match[1].split(',').map((item) => item.trim().split(/\s+/)[0]));
  }
  return result;
}

const published = await getProjects();
const migrated = new Map(published.map((project) => [project.folder, project.slug]));
const folders = await readdir(path.join(docs, 'visuals'), { withFileTypes: true });
for (const entry of folders.filter((item) => item.isDirectory())) {
  const relative = `visuals/${entry.name}/index.html`;
  if (await exists(path.join(docs, relative))) pages.add(relative);
}
for (const folder of migrated.keys()) pages.add(`visuals/${folder}/index.html`);

let legacyCount = 0;
for (const relative of pages) {
  const folder = relative.split('/')[1];
  const target = path.join(dist, relative);
  await mkdir(path.dirname(target), { recursive: true });
  if (migrated.has(folder)) {
    const destination = `${base}projects/${migrated.get(folder)}/`;
    await writeFile(target, `<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="refresh" content="0; url=${destination}"><link rel="canonical" href="https://mtsinganis.github.io${destination}"><title>Project moved · The Data Decoded</title></head><body><main><p>This project has moved to <a href="${destination}">${destination}</a>.</p></main></body></html>\n`);
    continue;
  }
  let html = await readFile(path.join(docs, relative), 'utf8');
  for (const url of htmlReferences(html)) await addReference(relative, url);
  // Astro owns styles.css at the site root; retain Quarto's stylesheet under a distinct name.
  html = html.replaceAll('href="../../styles.css"', 'href="../../legacy-styles.css"');
  await writeFile(target, html);
  legacyCount++;
}

// The Quarto search script loads this generated index at runtime.
if (assets.has('site_libs/quarto-search/quarto-search.js')) {
  if (!(await exists(path.join(docs, 'search.json')))) throw new Error('Quarto search requires docs/search.json');
  assets.add('search.json');
}
for (const relative of cssToInspect) {
  const css = await readFile(path.join(docs, relative), 'utf8');
  for (const match of css.matchAll(/url\(["']?([^"')]+)["']?\)/gi)) await addReference(relative, match[1]);
}
for (const relative of assets) {
  const target = path.join(dist, outputName(relative));
  await mkdir(path.dirname(target), { recursive: true });
  await copyFile(path.join(docs, relative), target);
}
let migratedChartCount = 0;
for (const project of published) {
  for (const chart of project.charts) {
    const target = path.join(dist, 'visuals', project.folder, 'plots', chart.name);
    await mkdir(path.dirname(target), { recursive: true });
    await copyFile(chart.file, target); // Only explicitly designated exports retain old direct chart URLs.
    migratedChartCount++;
  }
}
// Preserve this one bookmarked Quarto export; the Astro story still uses its smaller PNG.
const somaliaFolder = '2025-12-us-somalia-fragile-states-index';
const somaliaSvg = `visuals/${somaliaFolder}/plots/thumb.svg`;
if (!migrated.has(somaliaFolder)) throw new Error('The Somalia SVG exception requires its published redirect');
const svgSource = path.resolve('..', somaliaSvg);
if (!(await exists(svgSource))) throw new Error(`Missing compatibility asset: ${svgSource}`);
const svgTarget = path.join(dist, somaliaSvg);
await mkdir(path.dirname(svgTarget), { recursive: true });
await copyFile(svgSource, svgTarget);
console.log(`Staged ${legacyCount} legacy pages, ${migrated.size} redirects, ${assets.size} required legacy assets, ${migratedChartCount} designated charts, and one SVG compatibility asset.`);
