# SVG font optimisation — 10 October 2026

Applied **subsetted WOFF2** to all **28 main SVGs**: 27 country charts and the separate Greece/Spain/Germany/EU chart. No data, text, geometry, colours, line styling or chart dimensions changed. All 29 PNG files, including the contact sheet, retain their original SHA-256 hashes. Chart PNGs remain 3,600 × 2,700 at 300 dpi; SVGs retain the 864 × 648 viewBox and scalable vector geometry.

## Size comparison

Netherlands, using the approved single-country export:

| Format | Bytes | Reduction from original | Text remains editable |
|---|---:|---:|---|
| Original full TTF embeds | 2,799,866 | — | Yes |
| Character subsets, WOFF2 | 216,935 | 92.3% | Yes |
| Character subsets, WOFF | 229,077 | 91.8% | Yes |
| Text converted to vector paths | 573,294 | 79.5% | Shapes only |

The 28 main SVGs together shrink from **78,395,955 to 6,064,623 bytes (92.3%)**. The whole project falls from **119.9 to about 51.7 MiB (56.9% smaller)**, including the code, validation reports and outlined sample. PNGs and source data are retained unchanged. The outlined experiment adds one 573 KB SVG under `plots/alternatives/`; original comparison copies and test raster renders are outside the project. Final project totals, including code, data and validation reports, are recorded in `data/svg_optimization_summary.json`.

## Typography and character coverage

Subsetting uses the original pinned Lato Regular 400, Bold 700 and Black 900 sources. Each SVG is scanned for actual text runs, inherited weights and nested title spans; only weights used by that chart are embedded (all current charts use these three). Every character is included, including spaces, country names, digits, percentage signs, punctuation, en/em dashes and the middle dot. Each weight has its own character subset. OpenType shaping closure retains required composite and substitution glyphs.

Hinting, kerning and layout features are retained. Before accepting an export, the helper checks Unicode coverage, original glyph outlines and advances, and HarfBuzz-shaped glyph outlines, clusters, advances and offsets for every text run and each complete title. All SVG markup outside the font stylesheet remains byte-identical to the approved original. The stored per-chart manifests list characters, codepoints, used weights, source-font hashes and checks. The original TTF assets remain untouched. Internal derivative font family names are `TDDSVGSubset`, with the existing `Lato` CSS alias preserving chart styles; original copyright and SIL OFL notices are retained.

## Rendering and editing tests

| Viewer/tool | Test | Result |
|---|---|---|
| Edge 154, Chromium 154 | All 28 original/WOFF2 pairs, rendered at 1,800 × 1,350 | Pixel-identical; every text bounding box identical; 400/700/900 font faces loaded |
| Edge 154 | Netherlands subset WOFF | Pixel-identical to full TTF; identical text bounds |
| Edge 154 | Font-family alias controls, with and without embeds | Full TTF, WOFF2 and WOFF each loaded embedded fonts; removing embeds changed rendering, proving this was not local-font fallback |
| librsvg 2.61.0 / R rsvg 2.7.0 | All 28 pairs, local original Lato available | Pixel-identical |
| Inkscape 1.4 (86a8ad7) | Netherlands WOFF2/WOFF, Luxembourg, Hungary and the multi-highlight chart, local original Lato available | Pixel-identical |
| Inkscape 1.4 | Save editable WOFF2 SVG as plain SVG, reopen and render | 29 text elements retained; pixel-identical; saved file 223,049 bytes |
| Updated R exporter | Fresh Netherlands export | PNG and WOFF2 SVG reproduced byte-for-byte |

**Desktop compatibility limitation:** Inkscape 1.4 and librsvg 2.61.0 ignore embedded `@font-face` in full TTF, subsetted WOFF2 and subsetted WOFF alike. Unique font-family alias controls rendered identically to the no-font fallback in both desktop tools. They require locally available original Lato fonts for faithful viewing/editing, as the original exports already did. Subsetted WOFF does not fix this limitation. WOFF2 is smaller, correctly self-contained in the tested browser, and introduces no regression in the existing desktop setup.

Visual review included title/subtitle comparisons, long-title and close-label exports, footer and branding. Existing chart validation checks passed for shared axes, endpoint values/dates, layout and clipping. The PNG contact sheet remains unchanged.

## Vector-path alternative

`plots/alternatives/youth-unemployment-netherlands-eu-text-paths.svg` contains zero text elements. It preserves the illustrated letter shapes without requiring fonts, but wording can only be changed by replacing/editing shapes or returning to the R source and regenerating. It is about 2.6 times larger than the subsetted WOFF2 sample.

Conversion was performed with Inkscape and the original local Lato fonts. Glyph fills and strokes were explicitly preserved to avoid svglite's path CSS changing the converted letters. Compared with the editable original at 1,800 × 1,350, the corrected conversion differs in 411 pixels in Inkscape and 82,371 pixels in Edge. The reviewed title/subtitle is visually consistent, but conversion is not pixel-identical across renderers. The editable WOFF2 export is therefore the default.

## Reproduction

Install `requirements-svg.txt` into the Python environment selected by `TDD_PYTHON`, then run `analysis.R` from the repository root. It checks Python dependencies first and runs `optimize-svg-fonts.py` automatically for every SVG. `TDD_SVG_FONT_FORMAT=woff2` is the default; `woff` is available for explicitly tested use. New wording automatically triggers new character subsets; editing an SVG directly to add unsupported characters requires regenerating its font subset.

Run `verify-svg-fonts.py` with that Python environment to inspect actual embeds, weights, character coverage and licences. Run the existing `verify-country-exports.py` and `verify-render.py` with Pillow for chart checks. Optional path reproduction: `python outline-svg-text.py input.svg output.svg --inkscape PATH`, with original Lato available locally.

Evidence: `data/svg_font_optimization/`, `data/svg_font_validation.json`, `data/svg_batch_browser_comparison.json`, `data/svg_batch_rsvg_comparison.json`, the other `data/svg_*comparison.json` reports, and `data/svg_optimization_summary.json`.

Implementation references: [fontTools subsetting](https://fonttools.readthedocs.io/en/stable/subset/index.html), [Inkscape CLI](https://wiki.inkscape.org/wiki/Using_the_Command_Line), [Inkscape @font-face support](https://wiki.inkscape.org/wiki/%40font-face_Support).

No publishing or deployment was performed.
