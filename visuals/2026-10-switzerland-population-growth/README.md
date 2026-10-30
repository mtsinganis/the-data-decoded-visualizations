# Switzerland population growth: reproduction

Run from the repository root with R 4.5 and the packages listed in `analysis.R`:

```powershell
& 'C:/Program Files/R/R-4.5.2/bin/Rscript.exe' visuals/2026-10-switzerland-population-growth/analysis.R
```

The script reads the archived response offline, checks all 55 years, the balance equation, 2025 checkpoints and the companion project's migration series, then writes the processed CSV and PNG/SVG. The signed bar bounds place positive natural increase above zero and negative migration below it. The script explicitly stops if natural increase is negative, since that would require revising the stacking logic. SVGs embed the repository Lato fonts and the archived SemiBold font under the repository's Lato OFL license.

`data/query.json` selects Switzerland, all citizenship and sexes, 1971–2025, and components 1, 2, 3, 8, 13 and 15 from the [FSO demographic balance table](https://www.pxweb.bfs.admin.ch/pxweb/en/px-x-0102020000_101/-/px-x-0102020000_101.px/). `data/metadata.json` records the dimensions; `data/fso-response.json` is the retrieved API snapshot (2026-10-30). The API's `updated` field is unreliable; the table reports August 2026. To retrieve a fresh snapshot separately, run `acquire.ps1` from the repository root, then check revisions and source metadata before replacing the archived response. The chart is reproducible without network access. See `story.md` for definitions and source notes.

To regenerate the German companion, run `Rscript visuals/2026-10-switzerland-population-growth/analysis-de.R` from the repository root. It reuses the validated data and chart code and creates separate German PNG and SVG exports. German ALT text is in `post-de.md`.
