import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const mark = readFileSync(join(here, '..', 'pterosaur-simplified.svg'), 'utf8').match(/<path[^>]+d="([^"]+)"/)[1];
const variants = [
  { key: 'a-short', font: 'sans', lines: ['Where did it rise most?'] },
  { key: 'b-short', font: 'serif', lines: ['Where did it rise most?'] },
  { key: 'a-long', font: 'sans', lines: ['Where did the index rise', 'most across six sample', 'years?'] },
  { key: 'b-long', font: 'serif', lines: ['Where did the index rise', 'most across six sample', 'years?'] },
];

const values = [28, 24, 19, 13, 8];
const barLabels = ['Region A', 'Region B', 'Region C', 'Region D', 'Region E'];
const title = (lines, font) => lines.map((line, i) => `<text class="title-${font}" x="24" y="${55 + i * 32}">${line}</text>`).join('');
const bars = values.map((value, i) => {
  const y = 241 + i * 53;
  return `<text class="row" x="24" y="${y + 16}">${barLabels[i]}</text>
    <rect x="117" y="${y}" width="188" height="24" fill="#D8DDE1"/>
    <rect x="117" y="${y}" width="${value / 30 * 188}" height="24" fill="${i === 0 ? '#0062DF' : '#647184'}"/>
    <text class="value" x="331" y="${y + 17}" text-anchor="end">${value}</text>`;
}).join('');

for (const variant of variants) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 640" width="360" height="640" role="img" aria-label="Synthetic ranked bar chart, ${variant.font === 'serif' ? 'Georgia Bold' : 'Work Sans'} title: ${variant.lines.join(' ')}">
  <style>
    @font-face{font-family:'Work Sans';src:url('../fonts/WorkSans-Regular.ttf') format('truetype');font-weight:400}
    @font-face{font-family:'Work Sans';src:url('../fonts/WorkSans-Medium.ttf') format('truetype');font-weight:500}
    @font-face{font-family:'Work Sans';src:url('../fonts/WorkSans-Bold.ttf') format('truetype');font-weight:700}
    .title-${variant.font}{font-family:${variant.font === 'serif' ? "Georgia,serif" : "'Work Sans',Arial,sans-serif"};font-size:27px;font-weight:700;letter-spacing:-.025em;fill:#172033}
    .sans,.row,.value,.footer{font-family:'Work Sans',Arial,sans-serif;fill:#172033}
    .sans{font-size:13px}.row{font-size:13px;font-weight:600}.value{font-size:14px;font-weight:700}.footer{font-size:10px;font-weight:700;letter-spacing:.02em}
  </style>
  <rect width="360" height="640" fill="#F7F5EE"/>
  ${title(variant.lines, variant.font)}
  <text class="sans" x="24" y="157">Change in a synthetic index, 2019–2025</text>
  <line x1="24" x2="336" y1="184" y2="184" stroke="#D7D9D7"/>
  <text class="sans" x="24" y="211">Index-point change</text>
  ${bars}
  <text class="sans" x="24" y="532">Five invented regions · values are illustrative</text>
  <line x1="24" x2="336" y1="588" y2="588" stroke="#D7D9D7"/>
  <text class="footer" x="24" y="614">SYNTHETIC DATA</text>
  <g transform="translate(181 598) scale(.0197 .02) translate(-20 -180)"><path d="${mark}" fill="#0062DF"/></g>
  <text class="footer" x="213" y="614">THE DATA DECODED</text>
</svg>
`;
  writeFileSync(join(here, `${variant.key}.svg`), svg);
}
