# Project guidance

- The Data Decoded is the primary brand and X identity for Markos Tsinganis's independent visualization collection. Show Markos as the creator with secondary credit on the website only; do not put his name on charts or any X account surface. Use a typographic wordmark until a new logo is decided. Prioritize clear questions, sound analysis, source attribution, accessible explanation, and consistent design without assuming a final brand system.
- Read [MIGRATION.md](MIGRATION.md) before migration work; it records decisions and current status.
- Keep one topic per existing `visuals/` folder. Preserve folder names, original inputs, exports, and legacy `index.qmd` during the transition.
- Use R and ggplot2 for analysis and exports. New projects normally use one `analysis.R`, plus `data/`, `plots/`, `story.md`, and `post.md`.
- `story.md` is the single source for website metadata and reader-facing prose. Only `status: published` projects enter Astro; only chart files listed in `charts` may enter its new project pages. The one extra output asset is the old U.S.–Somalia `plots/thumb.svg` direct URL, retained for backward compatibility and checked by the output allowlist. Website builds must not run R.
- GitHub Pages now publishes Astro from `main` through `.github/workflows/deploy-astro.yml` when `ASTRO_PAGES_ENABLED=true`. Keep Quarto's `docs/` and `_quarto.yml` intact as the rollback source; see `MIGRATION.md` for the publishing and rollback steps.
