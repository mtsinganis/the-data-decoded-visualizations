# NYC cumulative chart typography comparison

Comparison only; final choice awaits Markos's review. Work Sans remains the approved production direction. Current master PNG/SVG files, story/post, original files, saved snapshot and calculations are untouched. Only the cumulative chart is compared at this stage.

## View and rerun

Local side-by-side preview: `http://127.0.0.1:8766/visuals/2026-10-nyc-shootings/typography-comparison/index.html`.

The page shows A/B/C at 390px, full-size 2112px PNG views, SVG views, and individual file links. `exports/comparison-phone.png` is a direct R review sheet with three 390px charts. Run from repository root:

```powershell
& 'C:\Program Files\R\R-4.5.2\bin\Rscript.exe' visuals/2026-10-nyc-shootings/typography-comparison/render.R
python -m http.server 8766 --bind 127.0.0.1
```

The renderer contains a frozen local copy of the current analysis/design, omitting calculated-table and master-export writes. It uses the same committed snapshot. This duplication is isolated comparison code, not a shared production chart function or template.

## Controlled measurements

| Treatment | Title | Everything else | Title lines | Plot frame height |
|---|---|---|---:|---:|
| A | Playfair Display Bold | Work Sans | 2 | 5.6535 in |
| B | Playfair Display Bold | Lato | 2 | 5.6535 in |
| C | Work Sans Bold | Work Sans | 2 | 5.6535 in |

Sizes identical throughout: title 22 pt; subtitle and ticks 14.5 pt; direct labels and comparison annotation 4.6 mm (about 13.1 pt); metadata 13 pt; signature 14 pt. Canvas 8.8 × 8.8 in at 240 dpi (2112 × 2112 PNG). Title leading 1.08, metadata leading 0.195 in, Source/Notes gap 0.035 in, mark width 0.60 in at intrinsic 1220:900 ratio, signature gap 0.14 in. No colored title words.

All title, subtitle, Source and Notes wrapping is device-measured. Each subtitle and each metadata field fits one line. A/B wrap after “record”, leaving “low in 2025” on line 2. C wraps after “a”, keeping “record low in 2025” on line 2. No sizes or positions changed to improve a particular treatment. Axis allocations are frozen to C's measured ggplot gtable (left allocation 0.5539 in; bottom allocation 0.3162 in), preventing font widths from moving the panel or any data geometry. `measurements.csv` records bounds and line counts. C's PNG is pixel-identical to the current master.

## Export and collision checks

All three XML documents have one SVG root, internal metadata and embedded official font bytes. Every used font's full OFL notice is retained in repository and SVG metadata. Exact font path and family checks stop on missing/substituted fonts. Playfair named Bold instance (index 262144) is checked explicitly and SVG weight is declared as 700; variable file bytes are unchanged. The renderer also restores the headline en dash if the Windows locale replaces it during SVG serialization. No fallback fonts accepted.

The first gtable measurement used R's default PDF device and produced font warnings; the final renderer measures on ragg's capture device, eliminating those warnings. Remaining R startup warnings concern unavailable C.UTF-8 locale settings. An initial SVG omitted the named instance's bold weight; final browser renders confirm weight 700. PNGs and SVGs reviewed at full layout size and 390px. Browser reports loaded Playfair/Work Sans for A, Playfair/Lato for B, and Work Sans for C. All XML line/marker/grid/connector coordinates and logo image placements are identical across treatments.

Browser text rectangles show no clipping. No endpoint, annotation, axis, Source/Notes, or signature text overlaps. A/B's title metric rectangles overlap by about 0.99 screen pixel at the reviewed SVG scale; their visible glyphs do not touch. C has no text-rectangle overlaps. Logo/signature gap remains unchanged and positive. Tiny metadata remains compact at 390px, and the unchanged amber labels remain faint (2.47:1 contrast), regardless of font. These are size/color limits of the fixed comparison, not fixed by switching families.

## Recommendation

Prefer C for this chart at phone width: it has the clearest compact headline and keeps “record low” together. A is the strongest alternative for a more editorial serif title, with familiar Work Sans elsewhere. B's narrower body text saves some horizontal room without changing line counts or plot space, and does not provide a clear readability gain over A/C. This is a review recommendation, not a brand decision. Final choice remains open.

Fonts and licenses: see `fonts/README.md` and `fonts/manifest.json`. Official Google Fonts revision `9710da1eacb3be272583c3224dcb70f9da6eadbb`; Playfair Display and Lato use SIL OFL 1.1. No new system-wide font install and no historical exports regenerated. These comparison assets are not listed in story.md and do not enter the public build.
