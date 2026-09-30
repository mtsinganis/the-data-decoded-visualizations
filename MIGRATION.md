# Astro migration

## Decisions

- One repository, with one existing folder per topic under `visuals/`; do not rename past projects.
- The Data Decoded is the primary brand and X identity. Markos Tsinganis receives secondary creator credit on the gallery, project pages, and footer. Use typography for the wordmark until a new logo is decided.
- R and ggplot2 remain the chart production tools. Astro builds the professional website for Markos Tsinganis from finished exports, without rerunning R.
- New projects use `data/`, `analysis.R`, `plots/`, `story.md`, and `post.md`. A project may split R code when necessary. Existing `index.qmd` analyses may stay in place.
- `story.md` holds title, stable slug, date, topics, description, publication status, ordered chart list, optional featured flag, and reader-facing copy with sources and methodology. It is the only website metadata file.
- A published story enters the gallery automatically. Drafts stay out. Astro emits only the chart files explicitly listed by published stories.
- Gallery previews use each chart's natural aspect ratio and full card width. Cards may have different heights and align at the top. Use one column on phones and two equal columns on desktop within a centered, shared content width.
- GitHub Pages hosts Astro through GitHub Actions from `main`. Domain, logo, final design, and any X automation remain later decisions. The current workflow prepares X copy and images only.

## Stages

1. **Pilot and local prototype (complete on this branch):** Preserve the Quarto site; extract aviation R chunks; add pilot story and post starter; add Astro gallery, project page, and project initializer; validate a local build.
2. **Pilot refinement (deployed):** Establish The Data Decoded as the primary typographic identity with secondary Markos Tsinganis credit; show gallery previews at natural proportions; keep the project reading order and full-size chart links; check reader-facing prose against the R analysis and inspect desktop and mobile layouts.
3. **Wider migration (two projects deployed):** Add `story.md` to further projects one at a time and mark each ready project published. The U.S.–Somalia Fragile States Index is the second project and uses one existing chart. Existing charts can be shown without rewriting their `index.qmd` analyses.
4. **Website design pass (complete locally):** Align the header, introduction, two-column gallery, project pages, and footer within a responsive content width; refine type and spacing while keeping the charts prominent. Later, choose the final identity, logo, and domain, and add richer article layouts or navigation only as needed.
5. **Publishing preparation (complete):** Build and verify Astro in CI without deploying `astro-migration`; retain old project URLs and local draft previews.
6. **Cutover (complete):** Astro now serves the live site through GitHub Actions. The Quarto output remains committed for rollback.

## Current status

- The prepared `astro-migration` branch was fast-forward merged into `main` at `9b2da16` after successful build-only CI on both branches. The branch remains available and does not publish the live site.
- Pilot: `visuals/2026-03-global-aviation-co2-emissions/`. Original `index.qmd`, data, and chart exports are retained. `analysis.R` contains its 13 R chunks in the same order, with no calculation edits.
- The pilot `story.md` reuses the established title, description, chart exports, source, and method from `index.qmd`. Its introduction now explains the 2020 decline and subsequent rise in daily averages. Those figures were checked against the Carbon Monitor workbook using the date parsing, country/sector sums, and annual means in `analysis.R`: 3.54 MtCO₂/day in 2019, 1.94 in 2020, and 3.88 in 2025. Its `post.md` remains a draft starter, not approved post copy.
- Second local project: `visuals/2025-12-us-somalia-fragile-states-index/` now has a published `story.md` and draft `post.md`. Its original `index.qmd`, saved CSV, cache, and exports remain in place. The story uses the existing 758 KB PNG export as its sole website chart. Its roughly 29 MB SVG is staged only at its original direct URL to preserve existing bookmarks; it is not used by the gallery or new project page. The saved CSV confirms Somalia ranked 1st in 2013 and 2023, while the U.S. moved from 159th to 141st; it contains 178 countries per year through 2020 and 179 from 2021 through 2023.
- Astro lives in `website/` and reads `story.md` and designated existing exports directly. GitHub Pages now uses the gated Actions deployment from `main`; the legacy `docs/` website remains intact for rollback.
- Validation: `pnpm build` and `pnpm verify` pass for both projects. The build emits the gallery, two project pages, stylesheet, the pilot's three SVG charts, and the second project's one PNG. The check confirms both entries, section order, full-size links, chart order and paths, draft exclusion, and no raw data or analysis files in output. The local preview rendered both projects.
- Rendered review: the header uses The Data Decoded wordmark, the gallery headline is “Interesting questions, explored through data.”, and “By Markos Tsinganis” appears as smaller credit. Header, introduction, gallery, project pages, and footer share a centered width capped at 1160px. At 1280px the gallery has two equal 536px columns with a 24px gap; the pilot's square SVG and second project's 2000 × 1857 PNG retain their natural ratios and different card heights. At 390px the cards stack, both project pages remain readable, navigation fits, all four full-size chart links are present, and none of the three pages has horizontal overflow. Small chart annotations are inherently hard to read at phone width; readers can open the full-size exports. Earlier temporary portrait and landscape fixtures were removed. This cutover kept both stories' wording unchanged.
- Whitespace check: the pilot SVG has a square 720 × 720 viewBox. Its corresponding 2000 × 2000 PNG export has nonwhite bounds from approximately (49, 46) to (1942, 1950), leaving about 2–3% white margin at each edge inside the chart itself. The former wide gallery frame added letterboxing; that frame is gone.
- R 4.5.2 parsed `analysis.R`, and an exact source comparison confirmed its 13 chunks match `index.qmd` in order and content. All required R packages were present. Running the extraction against a temporary data copy completed with exit code 0 and produced all six original export filenames. ggplot2 reported a deprecated `size` aesthetic and the local font/locale produced encoding warnings; the original exports were not overwritten.
- The new initializer was run in a temporary workspace and created the expected draft files and directories. The temporary validation copies were removed afterward.
- Next: review the 15 draft stories on the content-migration branch, resolve the three source-folder gaps below, and publish projects individually after editorial approval. Final logo and brand system remain open.

## Existing content migration (drafts for review)

Branch `codex/content-migration` starts from deployed `main` at `3068e53`. It adds `story.md` to each of the 15 remaining folders under `visuals/` that has an `index.qmd`; all are `status: draft`. Chart order follows the rendered Quarto pages. Each chart uses an existing export, usually the smaller PNG when a PNG and SVG represent the same figure. No chart, analysis, input, rendered page, or public route was changed. The two published stories and public gallery remain unchanged.

Start the local preview with `cd website` and `pnpm dev`, then open the draft URLs below. The normal address is `http://localhost:4321/the-data-decoded-visualizations/draft/<slug>/`; use the port Astro prints if 4321 is occupied. Draft charts have local full-size links and are absent from the production build.

| Existing project folder | Status | Draft slug or gap |
| --- | --- | --- |
| `2025-01-airbnb-demand` | Blocked | Only a rendered page and chart remain in `docs/`; no source folder, `index.qmd`, or analytical method is present. Its page still says “Text explaining chart.” Recover the source and complete the explanation before creating a story. |
| `2025-11-04-str-europe-peak-season` | Blocked as a separate story | Rendered page and chart files duplicate `2025-11-str-europe-peak-season`; no separate source folder or `index.qmd`. Keep its old URL, but do not create a duplicate gallery entry. |
| `2025-11-str-europe-peak-season` | Ready for draft review | `str-europe-peak-season` — causal explanations in the original article need supporting citations before publication. |
| `2025-12-corruption-index-by-region` | Ready for draft review | `corruption-index-by-region` |
| `2025-12-europe-capitals-temperature-extremes` | Ready for draft review | `europe-capitals-temperature-extremes` |
| `2025-12-europe-military-expenditure` | Ready for draft review | `europe-military-expenditure` — review explanatory annotations in the exports separately; the charts were not edited. |
| `2025-12-import-flags-ggplot` | Ready for draft review | `import-flags-ggplot` |
| `2025-12-israel-tourist-arrivals-by-continent` | Ready for draft review | `israel-tourist-arrivals-by-continent` |
| `2025-12-us-somalia-corruption-index` | Ready for draft review | `us-somalia-corruption-index` |
| `2025-12-us-somalia-fragile-states-index` | Published | Existing public story; no changes. |
| `2026-01-arXiv-submission-timing-history` | Ready for draft review | `arxiv-submission-timing-history` — the existing monthly chart labels three eras using an article named in its caption; review that attribution before publication. |
| `2026-01-venezuela-refugees-maduro` | Ready for draft review | `venezuela-refugees-maduro` — chart annotations make historical and causal claims beyond the cited UNHCR counts; confirm their sources before publication. |
| `2026-02-puerto-rican-population-in-us-and-pr` | Ready for draft review | `puerto-rican-population-in-us-and-pr` — original Quarto description is blank; draft description comes from the existing chart subtitle and needs editorial approval. |
| `2026-02-us-foreign-born-population-by-county` | Ready for draft review | `us-foreign-born-population-by-county` |
| `2026-02-us-national-pride-by-party` | Ready for draft review | `us-national-pride-by-party` |
| `2026-03-global-aviation-co2-emissions` | Published | Existing public pilot; no changes. |
| `2026-04-denmark-tax-revenue` | Ready for draft review | `denmark-tax-revenue` |
| `2026-04-denmark-tax-revenue-burden` | Blocked as a separate story | Rendered page and chart files duplicate `2026-04-denmark-tax-revenue`; no separate source folder or `index.qmd`. Keep its old URL, but do not create a duplicate gallery entry. |
| `2026-05-03-england-wales-jews-geo` | Ready for draft review | `england-wales-jews-geo` |
| `2026-05-england-wales-muslims-geo` | Ready for draft review | `england-wales-muslims-geo` |

Validation on this branch: `pnpm build` and `pnpm verify` pass with exactly two published projects, 18 preserved legacy pages, two old-route redirects, and no drafts or draft charts in `website/dist/`. The development server used port 4322 because 4321 was occupied and returned 200 for all 15 draft pages and their 34 selected chart routes; every page carried the local-only draft label and links to its charts. The three blocked rendered URLs remain covered by the legacy staging rules.

The two duplicate rendered folders each have plot files identical by hash to their source-backed counterpart (six short-term-rental files and three Denmark files). Several original chart captions name a data provider without a direct dataset link; the drafts preserve the provider attribution and link to the original analysis, while stable source links should be checked during editorial review. No missing citation was filled with a guessed URL.

## GitHub Pages publishing and rollback

### Previous hosting and rollback reference

- Before cutover, GitHub Pages used **Deploy from a branch: `main`, `/docs`**. The live URL was and remains `https://mtsinganis.github.io/the-data-decoded-visualizations/`; there is no custom domain, and HTTPS is enforced. The previous live deployment was [the generated Pages run](https://github.com/mtsinganis/the-data-decoded-visualizations/actions/runs/25470615741) on May 7, 2026. Commit `802d91d` is the pre-migration `main` reference. The `docs/` tree and `_quarto.yml` on deployed `9b2da16` match that reference exactly.
- `_quarto.yml` renders `index.qmd` and `visuals/*/index.qmd` into `docs/`, and publishes plot and shared asset resources. The committed `docs/index.html`, `docs/visuals/<existing-folder>/index.html`, and their support files currently serve the website. Keep `docs/` and `_quarto.yml` unchanged through the switch so rollback remains available.

### Completed preparation

1. `website/astro.config.mjs` now sets `site: 'https://mtsinganis.github.io'` and retains the `/the-data-decoded-visualizations/` base path. The static build reads finished exports and never runs R.
2. `.github/workflows/deploy-astro.yml` runs build and verification on pushes to `astro-migration` and `main`. It uses Node 24.19.0, pnpm 11.19.0, and `pnpm install --frozen-lockfile` in `website/`. Artifact upload and deployment require **both** `main` and repository variable `ASTRO_PAGES_ENABLED=true`. Migration-branch runs remain build-only. The workflow uploads only `website/dist/`; the deploy job has Pages and ID-token permissions and uses the `github-pages` environment. No step enables Pages or changes repository settings.
3. `website/scripts/stage-legacy.mjs` runs after Astro's build. It creates static redirect pages with visible fallback links for the two migrated projects at their original `/visuals/<folder>/` routes. It also retains each designated chart at its old direct path. The sole extra media exception is `visuals/2025-12-us-somalia-fragile-states-index/plots/thumb.svg`, copied byte for byte to preserve its old direct URL while the new pages use the PNG. For the 18 unmigrated projects, it stages their existing rendered HTML and only assets referenced by those pages or their CSS, plus Quarto's generated `search.json`. The explicit extension allowlist admits HTML pages, CSS, JS, chart images, and fonts, and rejects missing or forbidden dependencies. Quarto's root stylesheet is renamed to `legacy-styles.css` in output to avoid overwriting Astro's `styles.css`; the archived pages' stylesheet link is adjusted. `docs/` itself is untouched.
4. `pnpm dev` exposes a **development-only** page at `http://localhost:4321/the-data-decoded-visualizations/draft/<slug>/` for each draft story, including designated draft charts. It labels the page as unpublished. The public gallery, production project routes, and production output exclude drafts. `pnpm verify` checks routes, redirects, referenced assets, chart order and links, base paths, drafts, and the exact output file allowlist. A temporary draft chart/page was viewed locally and removed afterward.
5. Local `pnpm build` and `pnpm verify` pass. The production preview returned 200 for the home page, both new project pages, representative archived pages, redirected old project paths, and full-size charts; unknown and draft routes returned 404. The 18 archived pages keep their Quarto presentation. [GitHub Actions run #1](https://github.com/mtsinganis/the-data-decoded-visualizations/actions/runs/36785626322) succeeded on `astro-migration`: build and verification passed, artifact upload was skipped, and the deploy job was skipped.

**Backward-compatibility exception:** The old U.S.–Somalia Quarto page embedded `visuals/2025-12-us-somalia-fragile-states-index/plots/thumb.svg` (about 29 MB). Its original direct URL remains available through one explicit staging and verification rule. Git stores this text SVG with LF line endings (28,963,328 bytes); a Windows working copy with CRLF line endings can be 28,964,284 bytes. The live SHA-256 matches the committed Git blob. No other unlisted migrated export is included. No retained unmigrated page required a forbidden file during the audit.

### Cutover result and rollback

1. `astro-migration` CI [run #3](https://github.com/mtsinganis/the-data-decoded-visualizations/actions/runs/36787282042) passed with deployment skipped. The merge advanced `main` to `9b2da16`; its [build-only run #4](https://github.com/mtsinganis/the-data-decoded-visualizations/actions/runs/36787498217) passed with deployment skipped while the variable was unset.
2. Pages Source changed from `main /docs` to **GitHub Actions**. Repository Actions variable `ASTRO_PAGES_ENABLED` was set to `true`, and manual [Astro site run #5](https://github.com/mtsinganis/the-data-decoded-visualizations/actions/runs/36787673307) on `main` successfully built, uploaded `website/dist/`, and deployed it. Public checks passed for the homepage, both new project pages and full-size charts, all 20 old project routes (18 preserved pages and two redirects), the Somalia SVG and representative old assets, and expected 404s for draft and unknown routes. The live SVG matched the committed export by SHA-256.
3. To roll back: set repository Actions variable `ASTRO_PAGES_ENABLED=false` (or remove it) under **Settings → Secrets and variables → Actions → Variables**. In **Settings → Pages → Build and deployment**, choose **Deploy from a branch**, select `main` and `/docs`, then save. The unchanged Quarto output remains on `main`; wait for the generated Pages build and verify the homepage and representative old project pages. Compare with the [previous Pages run](https://github.com/mtsinganis/the-data-decoded-visualizations/actions/runs/25470615741) and pre-migration commit `802d91d`. Re-enable Astro only after fixing the cause and checking the public routes again. GitHub documents [the source setting](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site) and [artifact deployment](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages); Astro documents [the base path](https://docs.astro.build/en/guides/deploy/github/).

### Everyday publishing workflow

1. From the repository root, source `R/new_story_project.R` and run `new_story_project("YYYY-MM-topic", "Working title")`. It creates one topic folder with `data/`, `analysis.R`, `plots/`, `story.md`, and `post.md`, with the story in draft status.
2. Keep inputs in `data/`; use R and ggplot2 in `analysis.R` to check sources, calculate results, and export finished charts to `plots/`. Write the reader-facing introduction, sources, methodology, stable slug, chart order, and accessible chart descriptions in `story.md`. Prepare X copy in `post.md` for review; posting remains manual.
3. Run `pnpm dev` from `website/` and open `http://localhost:4321/the-data-decoded-visualizations/draft/<slug>/` to review copy and charts locally. The slug comes from `story.md`. Run `pnpm build` and `pnpm verify` to confirm the public artifact still excludes the draft and any unlisted data or exports.
4. After editorial approval, change only that project's `story.md` status to `published`, rerun build and verification, review its gallery and project pages, then commit and push to `main`. The Actions workflow publishes the new page automatically. Check the deployment and public URLs. A push to `astro-migration` alone never publishes.

## Local workflow

Run `pnpm install` in `website/`, then `pnpm dev` for local review or `pnpm build` to produce `website/dist/`. Open `http://localhost:4321/the-data-decoded-visualizations/` (Astro's default port) for a local preview. Run `pnpm verify` after a build to check routes and assets. From the repository root, source `R/new_story_project.R` and call `new_story_project("YYYY-MM-topic", "Working title")` to make a draft project. Edit its `story.md` and put finished charts in `plots/`; set `status: published` only when content is ready.
