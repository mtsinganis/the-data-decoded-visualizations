# Licensed Lato chart assets

Unmodified official Google Fonts files, pinned at commit `9710da1eacb3be272583c3224dcb70f9da6eadbb`: https://github.com/google/fonts/tree/9710da1eacb3be272583c3224dcb70f9da6eadbb/ofl/lato

- Lato-Black.ttf: 900, chart titles.
- Lato-Regular.ttf: 400, subtitles, axes, footer content and signature.
- Lato-Bold.ttf: 700, direct year labels, highlighted annotations and Source:/Notes: field names in the NYC project.

The files are byte-identical to the approved NYC exports. manifest.json records SHA-256; Lato-OFL.txt retains the complete SIL OFL 1.1 copyright/license notice. Preserve notices with redistributed files and embedded SVG fonts. Font internal names are unchanged. R loads exact file paths and rejects missing files or substitution; no system-wide install is required. NYC analysis supports TDD_LATO_FONT_DIR for an explicit override. Permanent location: assets/fonts/lato/. No shared chart functions are introduced.
