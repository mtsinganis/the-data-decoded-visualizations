# The Data Decoded

Data visualizations by Markos Tsinganis. Browse the [website](https://mtsinganis.github.io/the-data-decoded-visualizations/) or follow [The Data Decoded on X](https://x.com/TheDataDecoded).

R and ggplot2 prepare the analysis and finished charts. The Astro website reads each published project's `story.md` and the chart exports listed there; building the website does not run R. Pushing published work to `main` triggers the existing GitHub Actions build and GitHub Pages deployment. Posting to X is manual.

## Repository map

| Path | Purpose |
| --- | --- |
| `visuals/<topic>/` | One folder per topic. New topics normally have `data/`, `analysis.R`, `plots/`, `story.md`, and `post.md`. Older topics may also retain `index.qmd`. |
| `R/` | Shared R theme and functions, plus `new_story_project.R` for new Astro projects. `new_visual.R` remains for the older Quarto workflow. |
| `website/` | Astro source, package lockfile, build, verification, and local draft preview. |
| `assets/` | Shared assets. |
| `docs/`, `_quarto.yml`, `index.qmd` | Retained Quarto site output and configuration for legacy URLs and rollback. They do not drive the current homepage. |
| `.github/workflows/deploy-astro.yml` | Builds and verifies the site; publishes from `main` while `ASTRO_PAGES_ENABLED=true`. |

`story.md` is the website's source for title, stable slug, date, topics, description, publication status, ordered charts and alt text, introduction, sources, and methodology. Only `status: published` stories appear in the public gallery. The first chart in `charts` is the gallery preview. Drafts are visible only in the local development preview. Keep chart inputs in `data/` and finished exports in `plots/`; new Astro project pages use only designated exports. Legacy routes retain their required assets and one Somalia SVG compatibility link.

## Make the next post on Windows with RStudio

The commands below use `2026-10-my-next-topic` as an example folder and `my-next-topic` as its URL slug. Replace both consistently for your topic. Use a **PowerShell** terminal for shell commands and the **RStudio Console** for R commands. Run this workflow from `C:\Code\the-data-decoded-visualizations`, not the OneDrive copy. You need R, Node, and pnpm; the deployment workflow uses Node 24.19.0 and pnpm 11.19.0.

### 1. Open the project and start a topic branch

In PowerShell, open the repository's RStudio project:

```powershell
Set-Location 'C:\Code\the-data-decoded-visualizations'
Invoke-Item '.\the-data-decoded-visualizations.Rproj'
```

In the RStudio Console, confirm that the project root is the working directory:

```r
getwd()
stopifnot(file.exists("the-data-decoded-visualizations.Rproj"), dir.exists("visuals"), dir.exists("website"))
```

In an RStudio **PowerShell Terminal**, check for existing work, update `main`, and create a branch. If `git status` shows unrelated changes, pause and preserve them separately before the checkout; do not reset or stash them automatically.

```powershell
Set-Location 'C:\Code\the-data-decoded-visualizations'
git status --short --branch
git checkout main
git pull --ff-only origin main
git checkout -b codex/2026-10-my-next-topic
```

### 2. Create the draft and make the charts

For future charts, use bundled **Lato Black 900** titles, **Lato Regular 400** supporting text/annotations/footer content, and **Lato Bold 700** direct labels and Source:/Notes: field names. Exact files/license and current starting sizes are in [brand notes](brand-exploration/README.md) and [font notes](brand-exploration/fonts/lato/README.md). Load exact files and reject substitution. Keep mandatory Source, optional Notes, compact paragraphs with one space after each colon, and the established divider/pterosaur signature. Existing historical exports and comparison studies stay intact; do not extract shared R functions yet.


In the RStudio Console, source the initializer from the repository root. It refuses to reuse an existing project path and creates a draft `story.md`:

```r
source("R/new_story_project.R")
new_story_project("2026-10-my-next-topic", "Working title")
```

Put source files in `visuals/2026-10-my-next-topic/data/`. For example, after replacing the input path with your real file:

```r
file.copy("C:/path/to/input.csv", "visuals/2026-10-my-next-topic/data/input.csv")
file.edit("visuals/2026-10-my-next-topic/analysis.R")
```

Write data preparation, calculations, chart construction, and exports in `analysis.R`. Run it from the repository root in the RStudio Console:

```r
source("visuals/2026-10-my-next-topic/analysis.R")
```

Save finished charts to the project's `plots/` folder. For example, once your analysis has created a ggplot object named `p`, this line can go in `analysis.R`:

```r
ggplot2::ggsave("visuals/2026-10-my-next-topic/plots/main.png", plot = p, width = 8, height = 6, dpi = 300)
```

Do not put raw data or analysis files in the website folder.

### 3. Write and preview the draft

Open the two writing files in the RStudio Console:

```r
file.edit("visuals/2026-10-my-next-topic/story.md")
file.edit("visuals/2026-10-my-next-topic/post.md")
```

In `story.md`, replace the starter text with a reader-facing introduction and a **Sources and methodology** section. Complete its date, topics, description, and stable slug. Add the finished charts in reading order, with descriptive alt text, for example:

```yaml
status: draft
charts:
  - file: plots/main.png
    alt: "Describe what this chart shows."
```

Keep `status: draft` while reviewing. `post.md` holds proposed X copy and image notes; it is not published by Astro and does not post to X.

In an RStudio PowerShell Terminal, install the locked website dependencies when setting up the checkout, then start Astro:

```powershell
Set-Location 'C:\Code\the-data-decoded-visualizations\website'
node --version
pnpm --version
pnpm install --frozen-lockfile
pnpm dev
```

Leave that terminal running. Astro prints a **Local** URL, usually `http://localhost:4321/the-data-decoded-visualizations/`. If it prints a different port, use that port. In a second PowerShell Terminal, set `$previewPort` to the printed port and open the draft route:

```powershell
$previewPort = 4321
Start-Process "http://localhost:$previewPort/the-data-decoded-visualizations/draft/my-next-topic/"
```

Review the copy, chart order, proportions, alt text, sources, and every full-size chart link. The draft route exists only while `pnpm dev` is running.

### 4. Build, approve, and publish

In the second PowerShell Terminal, build and verify while the story is still a draft. These commands must run in `website/`:

```powershell
Set-Location 'C:\Code\the-data-decoded-visualizations\website'
pnpm build
pnpm verify
```

When the content is ready, change `status: draft` to `status: published` in `visuals/2026-10-my-next-topic/story.md`. Stop the development server with **Ctrl+C** in its terminal and restart it with `pnpm dev` so Astro picks up the new route. From the second `website/` terminal, rerun `pnpm build` and `pnpm verify`, then review the project in the local gallery and at its published route:

```powershell
pnpm build
pnpm verify
Start-Process "http://localhost:$previewPort/the-data-decoded-visualizations/"
Start-Process "http://localhost:$previewPort/the-data-decoded-visualizations/projects/my-next-topic/"
```

From the repository root, stage only this topic, inspect the staged changes, commit, and push its branch:

```powershell
Set-Location 'C:\Code\the-data-decoded-visualizations'
git status --short --branch
git add -- visuals/2026-10-my-next-topic/
git diff --cached --check
git diff --cached --stat
git commit -m "Publish my next topic"
git push -u origin codex/2026-10-my-next-topic
```

Open a pull request to `main` from that branch and wait for the **Astro site** build check. In PowerShell, open the compare page:

```powershell
Start-Process 'https://github.com/mtsinganis/the-data-decoded-visualizations/compare/main...codex/2026-10-my-next-topic?expand=1'
```

On GitHub, review the files and passing check, then merge the pull request into `main`. That push to `main` automatically updates GitHub Pages. Check the [Astro site workflow](https://github.com/mtsinganis/the-data-decoded-visualizations/actions/workflows/deploy-astro.yml), then open the public gallery and project page:

```powershell
Start-Process 'https://mtsinganis.github.io/the-data-decoded-visualizations/'
Start-Process 'https://mtsinganis.github.io/the-data-decoded-visualizations/projects/my-next-topic/'
```

Check the published chart and full-size link there. Post to [X](https://x.com/TheDataDecoded) manually after reviewing `post.md`.

For migration history and the Quarto rollback procedure, see [MIGRATION.md](MIGRATION.md).
