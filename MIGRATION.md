# Astro migration

## Decisions

- One repository, with one existing folder per topic under `visuals/`; do not rename past projects.
- The Data Decoded is the primary brand and X identity. Markos Tsinganis receives secondary creator credit on the gallery, project pages, and footer. Use typography for the wordmark until a new logo is decided.
- R and ggplot2 remain the chart production tools. Astro builds the professional website for Markos Tsinganis from finished exports, without rerunning R.
- New projects use `data/`, `analysis.R`, `plots/`, `story.md`, and `post.md`. A project may split R code when necessary. Existing `index.qmd` analyses may stay in place.
- `story.md` holds title, stable slug, date, topics, description, publication status, ordered chart list, optional featured flag, and reader-facing copy with sources and methodology. It is the only website metadata file.
- A published story enters the gallery automatically. Drafts stay out. Astro emits only the chart files explicitly listed by published stories.
- Gallery previews use each chart's natural aspect ratio and full card width. Cards may have different heights and align at the top. Use one column on phones and two equal columns on desktop within a centered, shared content width.
- GitHub Pages remains the intended free host. GitHub Actions deployment, domain, logo, final design, and any X automation are later decisions. The initial workflow prepares X copy and images only.

## Stages

1. **Pilot and local prototype (complete on this branch):** Preserve the Quarto site; extract aviation R chunks; add pilot story and post starter; add Astro gallery, project page, and project initializer; validate a local build.
2. **Pilot refinement (implemented locally; editorial approval pending):** Establish The Data Decoded as the primary typographic identity with secondary Markos Tsinganis credit; show gallery previews at natural proportions; keep the project reading order and full-size chart links; check reader-facing prose against the R analysis and inspect desktop and mobile layouts.
3. **Wider migration (started locally):** Add `story.md` to further projects one at a time and mark each ready project published. The U.S.–Somalia Fragile States Index is the second project and uses one existing chart. Existing charts can be shown without rewriting their `index.qmd` analyses. Editorial review remains before deployment.
4. **Website design pass (complete locally):** Align the header, introduction, two-column gallery, project pages, and footer within a responsive content width; refine type and spacing while keeping the charts prominent. Later, choose the final identity, logo, and domain, and add richer article layouts or navigation only as needed.
5. **Cutover:** Add GitHub Actions deployment for Astro, check the Pages build and links, then change Pages settings and retire the Quarto output only after approval.

## Current status

- Working branch: `astro-migration`, created from clean `main` at `802d91d`.
- Pilot: `visuals/2026-03-global-aviation-co2-emissions/`. Original `index.qmd`, data, and chart exports are retained. `analysis.R` contains its 13 R chunks in the same order, with no calculation edits.
- The pilot `story.md` reuses the established title, description, chart exports, source, and method from `index.qmd`. Its introduction now explains the 2020 decline and subsequent rise in daily averages. Those figures were checked against the Carbon Monitor workbook using the date parsing, country/sector sums, and annual means in `analysis.R`: 3.54 MtCO₂/day in 2019, 1.94 in 2020, and 3.88 in 2025. Its `post.md` remains a draft starter, not approved post copy.
- Second local project: `visuals/2025-12-us-somalia-fragile-states-index/` now has a published `story.md` and draft `post.md`. Its original `index.qmd`, saved CSV, cache, and exports remain in place. The story uses the existing 758 KB PNG export as its sole website chart; the roughly 29 MB SVG stays out of the website output. The saved CSV confirms Somalia ranked 1st in 2013 and 2023, while the U.S. moved from 159th to 141st; it contains 178 countries per year through 2020 and 179 from 2021 through 2023.
- Astro lives in `website/` and reads `story.md` and designated existing exports directly. No deployment is configured. The legacy `docs/` website remains intact.
- Validation: `pnpm build` and `pnpm verify` pass for both projects. The build emits the gallery, two project pages, stylesheet, the pilot's three SVG charts, and the second project's one PNG. The check confirms both entries, section order, full-size links, chart order and paths, draft exclusion, and no raw data or analysis files in output. The local preview rendered both projects.
- Rendered review: the header uses The Data Decoded wordmark, the gallery headline is “Interesting questions, explored through data.”, and “By Markos Tsinganis” appears as smaller credit. Header, introduction, gallery, project pages, and footer share a centered width capped at 1160px. At 1280px the gallery has two equal 536px columns with a 24px gap; the pilot's square SVG and second project's 2000 × 1857 PNG retain their natural ratios and different card heights. At 390px the cards stack, both project pages remain readable, navigation fits, all four full-size chart links are present, and none of the three pages has horizontal overflow. Small chart annotations are inherently hard to read at phone width; readers can open the full-size exports. Earlier temporary portrait and landscape fixtures were removed. Both local stories still need Markos's editorial review before deployment.
- Whitespace check: the pilot SVG has a square 720 × 720 viewBox. Its corresponding 2000 × 2000 PNG export has nonwhite bounds from approximately (49, 46) to (1942, 1950), leaving about 2–3% white margin at each edge inside the chart itself. The former wide gallery frame added letterboxing; that frame is gone.
- R 4.5.2 parsed `analysis.R`, and an exact source comparison confirmed its 13 chunks match `index.qmd` in order and content. All required R packages were present. Running the extraction against a temporary data copy completed with exit code 0 and produced all six original export filenames. ggplot2 reported a deprecated `size` aesthetic and the local font/locale produced encoding warnings; the original exports were not overwritten.
- The new initializer was run in a temporary workspace and created the expected draft files and directories. The temporary validation copies were removed afterward.
- Next: review both local stories and chart presentation, then decide whether to add another project. Final logo and brand system remain open. Deployment and Pages settings remain a later cutover step.

## Local workflow

Run `pnpm install` in `website/`, then `pnpm dev` for local review or `pnpm build` to produce `website/dist/`. Open `http://localhost:4321/the-data-decoded-visualizations/` (Astro's default port) for a local preview. Run `pnpm verify` after a build to check routes and assets. From the repository root, source `R/new_story_project.R` and call `new_story_project("YYYY-MM-topic", "Working title")` to make a draft project. Edit its `story.md` and put finished charts in `plots/`; set `status: published` only when content is ready.
