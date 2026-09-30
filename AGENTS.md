# Project guidance

- The Data Decoded is the primary brand and X identity for Markos Tsinganis's independent visualization collection. Show Markos as the creator with secondary author credit. Use a typographic wordmark until a new logo is decided. Prioritize clear questions, sound analysis, source attribution, accessible explanation, and consistent design without assuming a final brand system.
- Read [MIGRATION.md](MIGRATION.md) before migration work; it records decisions and current status.
- Keep one topic per existing `visuals/` folder. Preserve folder names, original inputs, exports, and legacy `index.qmd` during the transition.
- Use R and ggplot2 for analysis and exports. New projects normally use one `analysis.R`, plus `data/`, `plots/`, `story.md`, and `post.md`.
- `story.md` is the single source for website metadata and reader-facing prose. Only `status: published` projects enter Astro; only chart files listed in `charts` may enter its output. Website builds must not run R.
- Keep the Quarto `docs/` site and its publishing configuration intact until the replacement is explicitly approved. Do not deploy or merge the migration branch as part of the first milestone.
