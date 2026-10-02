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
