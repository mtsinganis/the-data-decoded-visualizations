# The Data Decoded: local brand exploration

These are three proposals, not production assets. The standalone comparison page and its SVG marks live outside `website/` and are not read by Astro. No historical charts, existing logo, X profile, or live website have been changed. All chart and project-card values on the page are **synthetic demonstration data** (Jan–Jun: 24, 30, 27, 42, 48, 54). Creator credit appears only in the website-header examples, never in the chart signatures or X avatars.

From the repository root, run:

```powershell
python -m http.server 8765 --directory brand-exploration
```

Open <http://localhost:8765/>. If `python` is unavailable, use `py -m http.server 8765 --directory brand-exploration`. Stop the server with Ctrl+C. The page requests Google Fonts for this **local comparison only** and falls back to Arial when offline. A selected direction should self-host a pinned font release for the website and install the same TTF files on the R export machine; those production changes are outside this branch.

Review captures: [1280px desktop](screenshots/desktop.jpg) and [390px mobile](screenshots/mobile.jpg). Both show the full page, including each synthetic chart and website treatment.

| Direction | What works | What needs care |
| --- | --- | --- |
| **Flight** | Connects to the current pterosaur association; one-color silhouette works in small social and chart-footer placements. | The creature can imply a nature or prehistory niche unless the wordmark and data stories stay prominent. Inspect its silhouette at 32–48 px before adopting it. |
| **Signal** | Subject-neutral data metaphor; square cells adapt well to favicons, avatars, and interface labels. | Grids are common in analytical branding. Distinctiveness and trademark clearance need evaluation before adoption. The small accent cell should still read in monochrome. |
| **Type** | Name is unmistakably primary; minimal ornament leaves charts in charge; TDD monogram packs into a small avatar. | The initials are generic in isolation. The full name needs to accompany the monogram in headers and shared content until recognition grows. |

## Type and color proposals

| Direction | Families | Ink / accent / background / secondary text |
| --- | --- | --- |
| Flight | Work Sans 700 for identity; Work Sans 400 for copy and charts | `#123F47` / `#D88B56` / `#F5F2EC` / `#425058` |
| Signal | IBM Plex Sans 700 and 400; IBM Plex Mono 500 for short data labels | `#203149` / `#C35639` / `#F3F5F4` / `#58636C` |
| Type | Inter 800 for identity; Inter 400 for copy and charts | `#242821` / `#789568` / `#F7F6F1` / `#60655D` |

[Work Sans](https://github.com/weiweihuanghuang/Work-Sans), [IBM Plex](https://github.com/IBM/plex), and [Inter](https://github.com/rsms/inter) are available under the **SIL Open Font License 1.1** according to their maintainers. Obtain desktop TTF/OTF files from those projects' release/download links, keep the corresponding OFL license with redistributed font files, and install the chosen family in Windows before using it in R. For reproducible R/ggplot2 exports, explicitly set `family` in the theme and render through a font-aware graphics device such as `ragg` after verifying the installed face with `systemfonts`. Pin the font version if the direction is chosen; font availability and metrics can otherwise change text wrapping across machines. The current page is a visual proposal and does not install fonts or implement chart templates.

The three marks are original lightweight SVG concepts: `pterosaur-mark.svg`, `decode-mark.svg`, and `tdd-mark.svg`. Their transparent backgrounds let the same asset sit in a wordmark, avatar, or chart footer. They are not a legal clearance or final production logo.
