import { readFile } from 'node:fs/promises';
import { getProjects } from '../../../lib/projects.js';

export async function getStaticPaths() {
  return (await getProjects()).flatMap((project) => project.charts.map((chart) => ({
    params: { slug: project.slug, file: chart.name },
    props: { chart },
  })));
}

export async function GET({ props }) {
  const chart = props.chart;
  const contentType = chart.name.toLowerCase().endsWith('.svg') ? 'image/svg+xml' :
    chart.name.toLowerCase().endsWith('.png') ? 'image/png' :
    chart.name.toLowerCase().endsWith('.webp') ? 'image/webp' : 'image/jpeg';
  return new Response(await readFile(chart.file), { headers: { 'Content-Type': contentType } });
}
