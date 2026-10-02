# Lato default for future charts

Unmodified official Google Fonts files pinned at commit `9710da1eacb3be272583c3224dcb70f9da6eadbb`, under `ofl/lato/`. These exact bytes were checked in the NYC comparison and copied here for future charts. Source: https://github.com/google/fonts/tree/9710da1eacb3be272583c3224dcb70f9da6eadbb/ofl/lato

- Lato-Black.ttf: 900; titles (NYC: 22 pt).
- Lato-Regular.ttf: 400; subtitle, axes, annotations, footer content and signature.
- Lato-Bold.ttf: 700; direct labels and Source:/Notes: field names.

`manifest.json` records SHA-256. `Lato-OFL.txt` is the complete SIL OFL 1.1 copyright/license notice; preserve it with redistributed files and embedded SVG fonts. Upstream notices, including trailing spaces, remain unchanged; local attributes keep LF line endings stable. Font files/internal names are unchanged. No Windows-wide installation is needed: register exact paths in R, check family/style and resolved paths, and stop instead of falling back. The NYC analysis supports `TDD_LATO_FONT_DIR` for an explicit location or missing-font failure check.

Earlier Work Sans and Playfair studies remain archived exploration. This adoption applies to future charts; no historical regeneration or live website font change.
