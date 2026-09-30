import { readFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
import matter from 'gray-matter';
import { marked } from 'marked';

const visuals = path.resolve(process.cwd(), '../visuals');
const chartPattern = /^plots\/[A-Za-z0-9][A-Za-z0-9._-]*\.(?:png|svg|jpg|jpeg|webp)$/i;

export async function getProjects(root = visuals) {
  const folders = await readdir(root, { withFileTypes: true });
  const projects = [];
  const slugs = new Set();
  for (const folder of folders.filter((entry) => entry.isDirectory())) {
    const projectDir = path.join(root, folder.name);
    let source;
    try {
      source = await readFile(path.join(projectDir, 'story.md'), 'utf8');
    } catch (error) {
      if (error.code === 'ENOENT') continue; // legacy projects have no story yet
      throw error;
    }
    const { data, content } = matter(source);
    if (data.status === 'draft') continue;
    if (data.status !== 'published') throw new Error(`${folder.name}: status must be draft or published`);
    if (!data.title || !data.description || !data.date || !Array.isArray(data.topics)) {
      throw new Error(`${folder.name}: missing title, date, topics, or description`);
    }
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(data.slug || '')) {
      throw new Error(`${folder.name}: invalid stable slug`);
    }
    if (slugs.has(data.slug)) throw new Error(`Duplicate project slug: ${data.slug}`);
    slugs.add(data.slug);
    if (!Array.isArray(data.charts) || data.charts.length === 0) {
      throw new Error(`${folder.name}: a published project needs an ordered chart list`);
    }
    const sections = content.split(/^## Sources and methodology\s*$/m);
    if (sections.length !== 2 || !sections[0].trim() || !sections[1].trim()) {
      throw new Error(`${folder.name}: story needs an introduction and a Sources and methodology section`);
    }
    const charts = [];
    for (const chart of data.charts) {
      if (!chart || !chartPattern.test(chart.file) || !chart.alt) {
        throw new Error(`${folder.name}: charts need a plots/ image file and alt text`);
      }
      const file = path.join(projectDir, chart.file);
      if (!(await stat(file)).isFile()) throw new Error(`Chart is not a file: ${file}`);
      charts.push({ file, name: path.basename(file), alt: chart.alt });
    }
    projects.push({
      folder: folder.name,
      slug: data.slug,
      title: data.title,
      date: data.date instanceof Date ? data.date.toISOString().slice(0, 10) : String(data.date),
      topics: data.topics,
      description: data.description,
      featured: data.featured === true,
      charts,
      introductionHtml: await marked.parse(sections[0]),
      sourcesHtml: await marked.parse(sections[1]),
    });
  }
  return projects.sort((a, b) => Number(b.featured) - Number(a.featured) || b.date.localeCompare(a.date));
}
