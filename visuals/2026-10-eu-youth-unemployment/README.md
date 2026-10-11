# Youth unemployment across the EU

TDD country explorer, selected for website publication on **11 October 2026**, retrieved **9 October 2026**. Reader-facing interpretation and methodology live in [story.md](story.md); X copy is an unsent draft in [post.md](post.md).

SVG exports now embed character subsets of Lato as WOFF2. Before running R, install the pinned Python font dependencies into your chosen Python environment:

```powershell
python -m pip install -r visuals/2026-10-eu-youth-unemployment/requirements-svg.txt
$env:TDD_PYTHON=(Get-Command python).Source
```

`TDD_PYTHON` can instead point to a virtual environment's Python executable. R checks these dependencies before rendering. The Python helper only optimises SVG fonts; analysis and chart authoring remain R/ggplot2.

Run from the repository root with R 4.5.2:

```powershell
& 'C:/Program Files/R/R-4.5.2/bin/Rscript.exe' visuals/2026-10-eu-youth-unemployment/analysis.R
```

The default reads preserved official responses and checks their SHA-256 hashes. For a new Eurostat vintage, set `$env:TDD_REFRESH='1'` before running; this replaces the snapshot and regenerates audits and exports. Review story/post dates, findings and ALT text after a refresh. Required R packages are checked at startup. No website build runs R.

Selection: `une_rt_m`, `M`, `Y_LT25`, `T`, `PC_ACT`, `SA`; the current 27 members plus published `EU27_2020`, from January 2000. Available observations before accession are retained. Rates are used directly; there is no country averaging, extra smoothing or TDD interpolation. Missing values remain `NA` and explicit segment groups prevent lines crossing gaps.

Coverage: latest selected observation **September 2026 (Ireland)**. Greece, Spain, Germany, EU-27 and the other monthly series end in August; Belgium, Croatia, Cyprus, Romania and Slovenia end in June and are quarterly-based. Estonia starts in February 2000. There are 8,950 numeric observations and 38 missing country-months (37 at the end, one at the start), with no interior gaps. All 28 endpoints are in `data/coverage.csv`.

Flags `b`, `d`, `u` are preserved. There are 21 flagged breaks; Greece and Germany have January 2009 breaks. No selected values have `e` or `p` flags, but Eurostat estimation and revision caveats still apply. Germany and Netherlands use provider trend estimates within the SA selection. See story.md and preserved reference metadata for details.

Exports: `plots/youth-unemployment-greece-eu.png` (3,600 × 2,700; 300 dpi) and `.svg` (editable text with embedded Lato WOFF2 subsets). Uses the shared ggplot theme, exact bundled Lato 400/700/900, TDD blue, existing palette-B teal/crimson, and the unchanged simplified pterosaur.

Evidence: `sources.csv` records URLs/timestamps/hashes; `retrieval.json` records vintage/latest month; tidy data, coverage, missing observations, flags, breaks, metadata/footnotes and code validation are in `data/`. Five Greek observations and their flags match a separately downloaded official SDMX TSV response. All 8,950 plotted values were checked against tidy data after ggplot transformation. PNG and rendered SVG were visually inspected. Run `verify-render.py` with Python and Pillow after export to recheck typography, layout and ALT synchronization. `data/rendered_validation.json` records final export geometry and header bounds.


## Country comparison exports

The same `analysis.R` now generates one chart for each of the 27 current EU members through `plot_youth_unemployment(country)`, with the featured country in TDD blue and the published EU-27 aggregate drawn last in dark ink with the approved longer dashes. The other 26 members are grey. Every chart keeps the approved 12 × 9 inch layout, 3,600 × 2,700 PNG at 300 dpi, bundled Lato typography, subtitle, Notes, footer and branding. Only the country name is blue in each continuous title. Endpoint anchors adapt within the existing right-side space for long labels, with at least 5.5 percentage points between label centres.

- Country exports: `plots/countries/youth-unemployment-[country]-eu.png` and `.svg` (27 of each).
- Original Greece/Spain/Germany/EU multi-highlight chart: `plots/youth-unemployment-greece-eu.png` and `.svg`, preserved separately.
- Contact sheet: `plots/youth-unemployment-eu-country-contact-sheet.png`.
- Country filenames, endpoint labels, exact plotted-value checks, common layout and scale settings: `data/country_*.csv` and `data/country_chart_settings.json`.

All 27 charts reuse the same validated data vintage and filters, global January 2000–September 2026 range, identical tick positions, and common 0–70% vertical scale. Each series keeps its own available endpoint. Dates on the two direct labels make differences visible, including Ireland's September endpoint and the five quarterly-based countries' June endpoints. All original coverage, flags, series-break and revision documentation remains applicable.

By default, running `analysis.R` generates the original plus the country batch. Set `$env:TDD_COUNTRIES_ONLY='1'` to leave the approved original exports untouched; set `$env:TDD_COUNTRY_EXPORTS='0'` to render only the original. Set `$env:TDD_REFRESH='0'` to explicitly reuse the saved source responses. Afterwards, run `verify-country-exports.py` with Python and Pillow to validate all 54 exports and recreate the contact sheet. `data/country_rendered_validation.json` records its checks. The 27 country PNG/SVG pairs are explicitly selected for the country explorer in story.md. The separate multi-highlight chart, contact sheet and outlined experiment remain repository outputs.

Review completed across all 27 contact-sheet charts and selected full-size PNG/rendered SVG exports, including long names, close endpoint values and differing endpoint dates. No clipping, overlapping labels or footer collisions remain. SVG titles use one continuous text element with an inline coloured country span; explicit whitespace preservation keeps word spacing and the template's endpoint-label spacing intact. The final exporter reproduced the Netherlands PNG and optimised SVG byte for byte. Font optimisation changes only the embedded font stylesheet in all 28 main SVGs; their remaining markup is byte-identical to the approved originals. All 29 PNGs (including the contact sheet) and the validated source/tidy data remain unchanged by SHA-256. See data/country_visual_review.json and data/svg_optimization_summary.json.


## SVG font optimisation

All 27 country SVGs plus the separate multi-highlight SVG use subsetted WOFF2 fonts. Only the weights and characters actually present in each chart are embedded (currently 400/700/900); punctuation, percent signs, spaces, country names and inline title spans are included. Hinting, kerning, layout features and licence metadata are retained. Regenerating a chart rebuilds its subset automatically, so adding text requires regeneration to include new characters. The original bundled TTF files remain unchanged.

`analysis.R` calls `optimize-svg-fonts.py` for every SVG. `TDD_SVG_FONT_FORMAT` defaults to `woff2`; `woff` is available for an explicitly tested compatibility requirement. Run `verify-svg-fonts.py` with the same Python environment to verify used weights, Unicode coverage, licences and dimensions. `verify-country-exports.py` and `verify-render.py` check the approved WOFF2 output and existing layout/data invariants; Pillow is required for those raster checks.

The comparison and viewer limitation are documented in [SVG-OPTIMIZATION.md](SVG-OPTIMIZATION.md). Edge renders embedded WOFF2 correctly. Inkscape 1.4 and librsvg 2.61.0 ignore embedded `@font-face` in all three tested formats, including the old full TTF exports, and require locally available Lato fonts for faithful viewing/editing. WOFF did not improve this. Their optimised renders match the originals with Lato available.

The optional `plots/alternatives/youth-unemployment-netherlands-eu-text-paths.svg` experiment removes font dependencies but converts all text to shapes. It is larger than WOFF2 and loses text editing; it is not the normal export. Recreate it with `outline-svg-text.py input.svg output.svg --inkscape PATH`, with the original Lato fonts available locally. The optimisation tests preceded article publication; the website exports only the 54 country assets selected in story.md.

## Country explorer article

`story.md` uses `presentation: country-explorer` and explicitly lists both formats for all 27 countries, with matching country names, Eurostat codes and ALT text. The website renders an alphabetical selector, one equal-size SVG at a time, and PNG/SVG download links in every figure and in an all-country directory. Austria is the alphabetical initial view; `?country=EL` and other valid codes select a shareable view. Without JavaScript all country figures and downloads remain available. The gallery uses an equal-weight list of all 27 country names rather than giving a national chart a featured preview. Data and chart exports were not regenerated for the article rewrite.

The preserved original multi-highlight Greece/Spain/Germany chart is not included in this public article and remains available for a future separate Greece article. `post.md` is an unsent collection draft with matching country PNG ALT text; publishing the website does not post to X.
