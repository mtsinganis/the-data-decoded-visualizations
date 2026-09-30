import { defineConfig } from 'astro/config';

export default defineConfig({
  output: 'static',
  site: 'https://mtsinganis.github.io',
  base: '/the-data-decoded-visualizations/',
  outDir: './dist',
});
