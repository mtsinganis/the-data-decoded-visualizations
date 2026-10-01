# The Data Decoded: reference-led brand study

This is a local proposal, outside Astro and the production artifact. It changes no published page, historical chart, R template, or X account. The Data Decoded remains the publication name. Markos Tsinganis appears only in the website application examples. Every chart value and schematic map region is **synthetic demonstration data**.

## Preview

From the repository root in PowerShell:

```powershell
python -m http.server 8765 --directory brand-exploration
```

Open <http://localhost:8765/>. If Windows exposes Python as `py`, substitute `py -m http.server ...`. Stop with Ctrl+C. The page requests Work Sans and IBM Plex Sans from Google Fonts for this local comparison; offline fallback text is not a reliable type comparison.

Review captures: [desktop, 1280 px](screenshots/refined-desktop.jpg), [mobile, 390 px](screenshots/refined-mobile.jpg), and [deuteranopia simulation](screenshots/vision-deutan.jpg). The last capture shows how several categorical colors converge while numeric labels and line styles remain. The older `desktop.jpg` and `mobile.jpg` document the previous three-direction study.

## Supplied logo and recommendation

`reference/blue-pterosaur-original.png` is a byte-for-byte copy of the supplied 1254 × 1254 raster (SHA-256 `565F2D4A7D7DB62C34948E4EFE89A8931C9C5F0D327AF9F14617844393B07636`). The white background is part of that file. Its central blue field samples near `#0062DF`; this is an approximation from the image, **not** a previously defined brand specification. The raster is retained separately and never embedded in an SVG.

`pterosaur-mark.svg` is a manually redrawn faithful vector. `pterosaur-simplified.svg` widens the eye and removes fragile foot detail. Actual-size tests showed the eye and feet weakening in both at 24 px, so `pterosaur-compact.svg` tests an enlarged eye and stronger feet at that size. All three keep the curved upper and lower wings, long beak, backward crest, and dynamic body line. They use transparent backgrounds, a flat fill, path geometry, and a padded `viewBox` (`20 180 1220 900`). Avatar samples place each mark at 78% of circle diameter so wing tips stay inside the circular safe area. The same page checks 24, 32, and 48 px avatars and 24 px-wide chart-footer marks. The compact drawing remains a proposal, not an automatic replacement.

**Recommended next trial:** use the faithful vector for wordmarks and larger placements, the lightly simplified version at 32–48 px, and the compact trial only where a 24 px mark is unavoidable. The reference blue gives the strongest visual continuity; `#2455FF` and raspberry `#E63B7A` remain options. Test on real devices before approving a logo. Do not replace the current production logo yet.

## Type and identity color

Work Sans and IBM Plex Sans are compared with identical wording, weight, size, spacing, and layout. Work Sans is the tentative preference: its open forms suit the flowing symbol. IBM Plex Sans is a clear, slightly more technical alternative. Both are available under the SIL Open Font License 1.1 from the [Work Sans source](https://github.com/weiweihuanghuang/Work-Sans) and [IBM Plex source](https://github.com/IBM/plex). Before production use, pin a release, self-host its web fonts, keep the OFL license with redistributed files, and install matching TTF/OTF files on the Windows machine that renders R charts. Check the installed family in R with `systemfonts::match_font("Work Sans")` or `systemfonts::match_font("IBM Plex Sans")`; then set the ggplot2 text family explicitly and export with a font-aware device such as `ragg`. No font is installed by this branch.

The local comparison uses the sampled blue `#0062DF`, alternative blue `#2455FF`, and proposed raspberry `#E63B7A`, with ink `#172033`, paper `#F7F5EE`, context slate `#7B8494`, and decorative lime `#D6EE42`. The wordmark uses the publication name; the creator credit is secondary in website mockups only. The SVG silhouette is tested in one color, black, and reversed white. None of these colors is approved for production.

## Frozen data-color proposal and provenance

The exact hex values are frozen in the `P` object at the top of [`exploration.js`](exploration.js) and displayed in the comparison page. Its roles are:

- **Highlights:** sampled blue `#0062DF`, alternate blue `#2455FF`, raspberry `#E63B7A`; ink and slate provide lower-emphasis marks. Lime `#D6EE42` is decorative only.
- **Neutral context:** `#D8DDE1`, `#AEB8C1`, `#647184`.
- **Eight categorical colors:** `#1B6CB8`, `#C43D70`, `#188471`, `#A66A1D`, `#7752A3`, `#B84932`, `#4E772C`, `#52657E`.
- **12-color extension:** adds `#A04489`, `#287F9C`, `#8A634A`, `#777543`.
- **16-color extension:** adds `#6860A5`, `#966817`, `#2E8564`, `#9A5271`.
- **Sequential, low to high:** `#F0F4F4`, `#D3E4EA`, `#A8CBDD`, `#72A6CC`, `#3F7BB5`, `#20558E`, `#12365B`.
- **Diverging, negative to positive:** `#9B3652`, `#C8617A`, `#E3AAB6`, `#F2DBDB`, `#F3F1EB`, `#D4E5EF`, `#94BED9`, `#4B86B8`, `#245578`.

These are **new manual proposals**, not copied ColorBrewer, Tol, or Crameri palettes. [ColorBrewer's scheme guidance](https://colorbrewer2.org/learnmore/schemes.html) informed the separation of qualitative, sequential, and diverging roles. [Paul Tol's color notes](https://sronpersonalpages.nl/~pault/data/colourschemes.pdf) informed the caution around many categories. [Crameri and colleagues](https://doi.org/10.1038/s41467-020-19160-7) informed the avoidance of rainbow scales and the need to inspect perceptual ordering. The frozen sequential proposal was checked in [Oklab](https://bottosson.github.io/posts/oklab/): lightness steps are 96 → 91 → 82 → 70 → 57 → 44 → 33 from low to high. Values were hand-selected, then measured perceptually; they are not an optimized or certified accessible palette.

The page calculates WCAG 2.2 contrast on the **actual paper and white backgrounds** using relative luminance. On paper, ink is 14.91:1, sampled blue 5.05:1, alternate blue 5.04:1, raspberry 3.65:1, slate 3.46:1, and lime 1.19:1. The [text criterion](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) is 4.5:1 for normal text; [non-text graphics](https://www.w3.org/WAI/WCAG22/understanding/non-text-contrast.html) commonly use a 3:1 target when needed to understand content. Thus raspberry and slate can serve as larger marks with labels, but should not be normal-size text on paper; lime should not carry data meaning on paper. Use ink for labels on light fills. Thin lines need dark enough strokes plus direct labels or line patterns. Large fills can be lighter when bordered and numerically labeled.

## Stress-test results and limits

The controls apply the same six chart datasets to three highlight choices and to standard, protanopia, deuteranopia, tritanopia, and grayscale views. The vision simulations use full-severity [Machado et al. matrices](https://pubmed.ncbi.nlm.nih.gov/19834201/) on linear-light RGB, then convert back to sRGB. The page reports the nearest categorical pair under each condition using Oklab distance (×100). These distances flag collisions; they are **not** pass/fail accessibility thresholds.

| Set | Standard nearest | Protanopia nearest | Deuteranopia nearest | Tritanopia nearest | Grayscale nearest |
| --- | --- | --- | --- | --- | --- |
| 8 | 03/07: 8.6 | 04/07: 1.4 | 04/06: 3.0 | 02/06: 2.7 | 05/08: 0.0 |
| 12 | 11/12: 6.2 | 04/07: 1.4 | 11/12: 2.1 | 03/10: 1.5 | 05/08: 0.0 |
| 16 | 03/15: 2.2 | 02/16: 0.5 | 03/16: 1.1 | 03/15: 0.4 | 05/08: 0.0 |

The eight-color set already has weak pairs in simulated color-vision conditions. The 12/16-color extensions contain more near duplicates and should not be used as the only way to identify categories. The eight-series line chart therefore uses direct end labels and dash patterns; the bar, heatmap, map, and stress charts include values or numbered labels. The schematic map has invented regions and is not a geographic visualization. These tests do not establish universal readability or color-blind safety. Human testing, print checks, and real content remain necessary before any production palette is chosen.

The prior abstract `decode-mark.svg` and `tdd-mark.svg` are retained as historical exploratory files; the previous angular Flight drawing has been replaced by the reference-based vector. None enters `website/dist/`.
