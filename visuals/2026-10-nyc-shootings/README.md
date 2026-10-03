# NYC shootings: reproducibility

Run from the repository root with R 4.5.2:

```r
source("visuals/2026-10-nyc-shootings/analysis.R")
```

The script checks its required packages, reads the saved snapshot, validates incident IDs/dates and the verified June cutoff, creates diagnostic tables in data/, then writes the approved cumulative and monthly PNG/SVG pairs. No download is required. Fonts and signature are loaded from assets/fonts/lato/ and assets/brand/, with explicit exact-font checks. Set TDD_EXPORT_ONLY=monthly to render just monthly when needed. Generated CSV tables are ignored by Git; the snapshot and provenance remain tracked. Original supplied R script is retained for the methodological audit; duplicate old chart exports and typography comparisons remain on codex/2026-10-nyc-shootings-brand-trial.

Sources, definitions and editorial text live in story.md. Cumulative leads; monthly supports. Only their two designated PNGs enter the public website build. SVGs remain repository exports. post.md is unapproved X copy and does not publish automatically. No annual projection is made for 2026.

Validated in this focused checkout: both PNG/SVG pairs regenerate byte-identically to the approved trial, exact embedded Lato weights 400/700/900, R guards and snapshot-derived statistics, website build/verify and desktop/phone project page. Existing limitations: amber 2021 text is faint at phone width and footer metadata is compact; full-size links are available.
