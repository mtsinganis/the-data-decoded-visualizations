# Presentation revision review — October 2, 2026

Visual approval remains pending. Story remains draft; X post remains unapproved.

- R exports: one 8.8 × 8.8 inch PNG/SVG master per chart; PNGs are 2112 × 2112 pixels. Original supplied script and historical reference charts preserved. Superseded web/X trial variants removed after validation.
- Both SVGs passed Python ElementTree XML parsing: one SVG root, internal metadata/style and embedded licensed Work Sans. Actual browser renders showed chart geometry, no visible license text, and loaded Regular/Medium/Bold Work Sans. Explicit bundled-font path checks remain in R.
- Both PNGs and SVGs reviewed at full layout size and 390px display width. Larger axes, annotations and metadata; dark endpoint text with colored markers/leaders; complete endpoint totals without clipping; June-only 2026; solid lines; white panels and labels. Signature retains the 1220:900 intrinsic ratio and main-content alignment. Metadata remains smaller than chart labels and is compact at phone width; full-resolution files remain available.
- Windows Explorer thumbnails could not be inspected because native app control is unavailable. This is an unperformed thumbnail check, not evidence of a rendering failure.
- Calculated tables and saved October 2 snapshot unchanged. December 2025's 35 incidents remains the lowest observed month in saved coverage.
- Reusable-frame lessons: allow chart-specific width/height and endpoint-label space; measure metadata and title wrapping on the export device; support mandatory Source and optional nonempty Notes with hanging indents; insert font metadata only inside the SVG root. Defaults documented in AGENTS.md and brand-study README; no shared production functions extracted.
- `pnpm build` and `pnpm verify` passed. Draft slug/assets absent from public output.

## Typography and compact metadata refinement

Supersedes the earlier larger-type / dark endpoint / hanging-indent presentation above. Actual font sizes: title 25 to 22 pt; subtitle and ticks 17 to 14.5 pt; year labels and main annotations 5.4 to 4.6 mm; December annotation 5.1 to 4.35 mm; metadata 16 to 13 pt. Metadata leading is 0.195 inch, field gap 0.035 inch. Signature, logo proportions, square dimensions and 240 dpi resolution unchanged.

Supporting gray #666666 measures 5.74:1 on white. Highlight-specific labels and connectors match line colors. Amber measures 2.47:1 and remains faint on phones, below the 4.5:1 small-text target; palette preserved as requested. Compact Source/Notes paragraphs use bold labels, one normal space, regular content and left-margin continuation lines. Notes define the annual-record scope. Shared headline and reader prose updated; story draft / post unapproved.

Direct R PNG and SVG exports, full-size and 390px reviews completed; no collisions or clipping found. Both SVGs have one valid XML root, internal metadata and three embedded licensed font weights; actual browser reports loaded Work Sans. PNG writes now use a temporary render and checked replacement after an initial write failure. Calculated data tables and original files unchanged. Build and verify passed, with draft exclusion. Chart sizing remains provisional; other projects and production functions unchanged.

## Lato adoption — October 3, 2026

Lato is now the default for future charts; earlier Work Sans and Playfair comparisons remain preserved exploration. Both NYC masters use exact bundled Lato-Black.ttf (900) for 22 pt titles, Lato-Regular.ttf (400) for 14.5 pt subtitles/ticks, 4.6 mm main annotations, 4.35 mm December annotation, 13 pt metadata and 14 pt signature, and Lato-Bold.ttf (700) for 4.6 mm direct year labels and metadata field names. Official font files, SHA256 manifest and full SIL OFL 1.1 notice are retained in brand-exploration/fonts/lato. R checks exact internal styles and resolved file paths, and stops clearly if files are missing.

Both titles retain two measured lines. White square 8.8 inch canvases, 240 dpi / 2112 px PNGs, colors, data geometry, solid lines, June-only 2026 and footer/logo proportions are retained. Supporting gray is #666666 (5.74:1 on white). Source is mandatory; Notes optional; bold field names followed by one normal space, compact regular-weight paragraphs with left-margin continuation lines, 0.195 inch leading and 0.035 inch field gap.

Monthly historical lines are reduced from 0.42 / alpha 0.65 to 0.30 / alpha 0.45. The 2026 label moves from x=6.3, y=100 to x=6.4, y=103 with its solid teal connector. Highlighted years remain identifiable in the denser monthly chart. Full-size PNG and browser SVG renders and paired 390 px reviews found no clipping or text collisions. Both browser SVGs reported loaded Lato 400/700/900; both passed XML parsing with one root, embedded exact fonts and internal license metadata. Missing-font failure was exercised. Amber 2021 text remains faint at phone width (2.47:1 on white); palette retained. Footer text is compact at phone width and best read in the full-resolution export.

pnpm build and pnpm verify passed: 16 published projects, preserved legacy pages/assets, output allowlist and draft exclusion. NYC story remains draft and post unapproved. Verified tables, saved snapshot, original files, typography comparison exports and other projects are unchanged. PNG replacement uses a checked temporary render and reversible previous-file rename. No shared R functions extracted.

## Data boundary and overlap refinement

Both master pairs regenerated directly from R. Gridlines and the single darker zero baseline stop at December; the blank margin beyond December contains only full-year endpoint labels and short solid connectors. Highlighted 2020/2021/2025/2026 strokes all use 1.2 mm (SVG stroke width 2.56 pt). The 1.65 mm white underlay is limited to 2026's January-June segment and immediately precedes its teal line. It provides a small separation where blue and teal overlap, without excessive removal of context lines. Gray historical strokes remain unchanged and thinner.

The cumulative annotation now reads "2025 had less than half / the shootings of 2021", left-aligned at February and vertically centered around 1,250 in supporting gray. Full-size PNG and 390 px PNG/SVG browser reviews found no collisions or clipping. XML checks confirmed one zero baseline per chart and all grid endpoints matching December; highlighted widths are equal. Both browser SVGs loaded Lato 400/700/900; exact-file R checks passed. The amber 2021 text remains faint at phone width and footer text remains compact; no new visual issues observed.

pnpm build and pnpm verify passed, including draft exclusion and output allowlist. Saved snapshot, calculations, original reference exports and unrelated files remain unchanged. Story remains draft and X post unapproved.

### Monthly title and 2026 annotation follow-up

Monthly title now reads: "The summer 2020 spike stands out against 2025’s lower monthly counts". The 2026 annotation moves below the observed line to x=6.4, y=34, with Lato Regular 400 at the same 4.6 mm size as the July annotation, no white text background, and its solid teal connector retained. Full-size regenerated PNG reviewed: the text is clear of historical lines and the December annotation. Cumulative exports and verified calculations are unchanged. PNG/SVG regenerated directly from R; no build or test rerun for this presentation-only follow-up.
Monthly 2026 annotation position refined to x=6.4, y=61: both lines now sit below the blue series and above the 50-incident gridline. Regenerated PNG/SVG and visually reviewed; Regular weight and transparent background retained.
Monthly 2020 endpoint connector now slopes below the amber 2021 point, with 2020 label at 105 and 2021 at 140. Multiline series labels and annotations on both charts now use 0.95 lineheight (previously 1.05; cumulative comparison previously 1.15). Regenerated PNG/SVG exports and visually reviewed; title, footer, typography sizes and calculations retained.
Clarified endpoint printing order: monthly connectors now render before endpoint points, so the amber 2021 point covers the red 2020 connector. Restored original label positions (2020 above, 2021 below). Restored monthly "2026: 322" and shortened its connector by 0.10 month to leave a gap before the text. July 2020 annotation adds "highest month since 2006", supported by the saved monthly table maximum (243). Regenerated monthly PNG/SVG and visually reviewed.
Right-hand label margin reduced: shared x-domain upper limit 15.3 to 14.4, reducing reserved December-to-edge space by about 22% and widening the historical data area by about 6.6%. Square canvas, title/footer alignment and export resolution retained. Both PNG/SVG pairs regenerated; full-size review found endpoint totals clear of the right edge, with no annotation collisions.
