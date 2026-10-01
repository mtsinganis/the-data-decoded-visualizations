# The Data Decoded: local brand study

This development-only comparison is outside Astro and its production artifact. It changes no live page, historical chart, or production R template. All chart values and map regions are **synthetic demonstration data**. Markos Tsinganis appears only in website examples, never on a chart or X application.

## Preview and exports

From the repository root in PowerShell:

```powershell
python -m http.server 8765 --directory brand-exploration
```

Open <http://localhost:8765/r-prototypes/> for the current Work Sans chart-frame study. The root page at <http://localhost:8765/> retains the earlier symbol, color, and chart trials. <http://localhost:8765/typography/> archives the Work Sans versus Georgia title comparison. Stop the server with Ctrl+C. Current preview fonts are served from `fonts/` locally; no Google Fonts request is needed.

Regenerate the direct R exports from the repository root:

```powershell
& 'C:\Program Files\R\R-4.5.2\bin\Rscript.exe' brand-exploration/r-prototypes/render.R
node brand-exploration/r-prototypes/verify.mjs
```

Use your own Rscript path if R is installed elsewhere. The script requires `ggplot2`, `ragg`, `svglite`, `systemfonts`, `jsonlite`, `base64enc`, `rsvg`, and `png`. Five synthetic frames each produce a 1080 × 1920 PNG and a self-contained SVG in `r-prototypes/exports/`. The SVG contains editable chart geometry and text, three embedded Work Sans font files, and a small rasterized rendering of the lightly simplified logo. The logo source remains vector. Embedding the licensed font bytes lets a browser render the SVG without Work Sans installed; other SVG consumers may vary, so use the PNG for fixed appearance. The OFL license accompanies the font files in this repository.

The R script registers the pinned TTF files under explicit aliases, checks each file's internal family name, and checks that font matching resolves to those exact paths. A missing file stops export before opening a graphics device; it does not silently substitute Arial. To check the failure path without changing the study, set `TDD_FONT_DIR` to an empty directory when running the script. R can use the bundled TTFs without a Windows-wide installation. For other RStudio scripts that call `family = 'Work Sans'` directly, install the three TTFs with Windows Explorer, restart RStudio, and confirm `systemfonts::match_font('Work Sans')` resolves to Work Sans. Source, pinned version, hashes, license, and Windows instructions are in [fonts/README.md](fonts/README.md).

## Confirmed identity and open choices

- **Approved family:** Work Sans alone. Titles use Bold; optional subtitles and body use Regular; labels and annotations use Regular or Medium; sources and notes use Regular at an intended readable size. Size, weight, and spacing form the hierarchy. Georgia and IBM Plex comparisons are historical exploration, not live options.
- **Confirmed blue:** `#2455FF`. On paper `#F7F5EE`, its measured WCAG contrast is 5.04:1.
- **Preferred trial mark:** `pterosaur-simplified.svg`, the lightly simplified interpretation. `pterosaur-compact.svg` remains a 24 px test only, for use where an actual-size test makes its stronger eye and feet necessary. No new logo is approved for production replacement.
- **Open warm accent:** vermilion `#D94A38` or crimson `#C83242`. On paper, their contrast ratios are 3.86:1 and 4.82:1. Vermilion is unsuitable for ordinary small text on this paper; use ink for labels. Crimson clears 4.5:1 on paper, but the categorical system still needs review.
- **Other proposed colors:** ink `#172033`, paper `#F7F5EE`, context slate `#7B8494`, and decorative lime `#D6EE42`. Lime is not a data or small-text color.

The supplied raster, `reference/blue-pterosaur-original.png`, is preserved byte-for-byte (1254 × 1254, SHA-256 `565F2D4A7D7DB62C34948E4EFE89A8931C9C5F0D327AF9F14617844393B07636`). Its sampled central blue is approximately `#0062DF`; that sample is not a brand specification. The faithful, simplified, and compact SVGs have transparent backgrounds, flat fills, clean paths, and padded viewBoxes. The silhouette retains curved sweeping wings, long beak, backward crest, eye, and feet. Earlier 24/32/48 px avatar and footer tests showed the faithful eye and feet weakening at 24 px; the simplified version is preferred and the compact version is reserved for that small case. The full silhouette fits inside the circular avatar safe area. No raster image is embedded in the logo SVGs.

## Data-color system and limits

The current frozen proposal is [palette.json](palette.json): confirmed blue, three context neutrals, eight categorical colors with a warm slot for either accent, four additional colors for a 12-category stress test, four more for a 16-category stress test, plus sequential and diverging scales. The two direct R line exports hold data, order, title, labels, spacing, and frame constant while changing only the warm slot. The current local page shows both 8/12/16 sets with numeric keys. The 12/16 sets are stress tests, not a recommendation to identify many categories by hue alone.

Use dark strokes for thin lines, plus direct labels or distinct dash patterns. Large fills can be lighter when values are labeled and adjacent areas have clear boundaries. Use ink for text on paper and light fills. The line test uses direct end labels and line patterns; the heatmap prints values in every cell. The ranked bar highlights one value in confirmed blue against neutral context. The chart frame holds title, optional subtitle, sources/notes, and a modest logo/channel signature constant while leaving the plot structure flexible. Source and note lines are 16 pt in the 7.5 × 13.33 in master; inspect the reduced phone view and open the full export for small labels.

These manual proposals are informed by [ColorBrewer's qualitative, sequential, and diverging guidance](https://colorbrewer2.org/learnmore/schemes.html), [Paul Tol's notes on categorical discrimination](https://sronpersonalpages.nl/~pault/data/colourschemes.pdf), and [Crameri and colleagues on perceptual color maps](https://doi.org/10.1038/s41467-020-19160-7). They are not copied or certified versions of those palettes. The current page calculates nearest categorical pairs with Oklab after full-severity protanopia, deuteranopia, tritanopia, and grayscale approximations using the [Machado et al. model](https://pubmed.ncbi.nlm.nih.gov/19834201/). Standard-display nearest pairs are 02/06 at distance 7.6 for eight categories, 07/12 at 3.4 for twelve, and 12/16 at 1.5 for sixteen. In the eight-color set, vermilion's closest pair under simulated deuteranopia is 03/04 at 2.2, while crimson's is 02/07 at 2.7. Both variants have an eight-color grayscale collision at 02/03 (rounded distance 0.0). These figures flag possible collisions, not accessibility thresholds. The earlier root page has separate diagnostics for its **earlier** categorical set. Human review is still needed before a template. Do not call either palette color-blind safe; use grouping, texture, facets, and labels.

## Archived comparisons and font rights

The [Georgia comparison](typography/index.html) has four 360 × 640 frames: Work Sans throughout versus Georgia Bold in the title, each with a short and a wrapped question. Its old PNG captures freeze the historical rendered appearance. Its SVG sources now refer to local Work Sans files and the viewer's Georgia installation; they remain an archive, separate from the reproducible R exports above. Run `node brand-exploration/typography/generate.mjs` and `node brand-exploration/typography/verify.mjs` to check their sources and dimensions.

[Microsoft's Georgia listing](https://learn.microsoft.com/en-us/typography/font-list/georgia) describes it as a Windows font. [Microsoft's font FAQ](https://learn.microsoft.com/en-us/typography/fonts/font-faq) says Windows font files generally cannot be redistributed, uploaded as webfonts, or converted without additional rights; rendered graphics are a separate use. No Georgia file is in this repository. Work Sans is redistributed under the [SIL Open Font License 1.1](fonts/OFL.txt), with its copyright notice and pinned source recorded next to the TTFs. The earlier IBM Plex and sampled-blue/raspberry trials remain in the root comparison for historical context.

## Remaining decisions

Review the simplified logo at actual X avatar and chart-footer sizes on real devices, choose the warm accent, assess revised categorical extensions under color-vision simulations and grayscale, then decide whether a reusable R chart template is warranted. The live website, historical charts, and X account remain unchanged.
