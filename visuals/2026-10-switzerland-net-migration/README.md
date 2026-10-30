# Switzerland net migration: reproduction

Run from the repository root with R 4.5 and the packages listed at the top of `analysis.R`:

```powershell
& 'C:/Program Files/R/R-4.5.2/bin/Rscript.exe' visuals/2026-10-switzerland-net-migration/analysis.R
```

The script reads the preserved `data/fso-response.json` offline, checks the 55 years and selected extrema, creates `data/annual-net-migration.csv`, and exports the PNG and SVG. It uses the repository Lato fonts, theme and pterosaur asset. It does not need a website build or network access.

`data/query.json` is the exact PxWeb API selection. `data/metadata.json` records its dimension codes. To obtain a new snapshot, POST the query as JSON to `https://www.pxweb.bfs.admin.ch/api/v1/en/px-x-0102020000_101/px-x-0102020000_101.px`; preserve the response and check the table's current vintage, dimensions, revisions and notes before replacing the snapshot. Retrieved 2026-10-29. The API response's `updated` field says 2010; the FSO table's own metadata states August 2026 and data through 2025, so the API timestamp is not used as the vintage. The chart uses the national total and includes status changes, as described in `story.md`.

The chart note summarizes the FSO definition change in 2011 and the inclusion in 2023 of people who fled Ukraine in 2022 and subsequently joined the permanent-resident population. See the linked FSO documentation and fuller explanation in `story.md`. The 2025 label is positioned just above and to the right of its column to avoid overlap with the 2023 bar and label.

Historical annotation sources and interpretation are documented in `story.md`.

The historical annotations use the official Lato SemiBold 600 font, preserved as `data/Lato-SemiBold.ttf` from the same pinned [Google Fonts revision](https://github.com/google/fonts/tree/9710da1eacb3be272583c3224dcb70f9da6eadbb/ofl/lato) as the repository fonts, under the existing Lato OFL license. The SVG embeds this font.
