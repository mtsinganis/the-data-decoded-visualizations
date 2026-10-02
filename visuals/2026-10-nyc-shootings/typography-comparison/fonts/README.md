# Official comparison fonts

Unmodified files retrieved October 2, 2026 from the official Google Fonts repository, pinned to commit `9710da1eacb3be272583c3224dcb70f9da6eadbb`.

- Playfair Display: `https://github.com/google/fonts/tree/9710da1eacb3be272583c3224dcb70f9da6eadbb/ofl/playfairdisplay` (upstream: clauseggers/Playfair-Display). Original filename `PlayfairDisplay[wght].ttf`; only filesystem filename simplified locally. Font contents and internal names unchanged.
- Lato: `https://github.com/google/fonts/tree/9710da1eacb3be272583c3224dcb70f9da6eadbb/ofl/lato` (Regular, Medium, Bold, Black).

Both are SIL Open Font License 1.1. Complete notices/licenses retained as `PlayfairDisplay-OFL.txt` and `Lato-OFL.txt`; reserved names preserved. These licenses permit embedding and redistribution with the notices. Work Sans continues to use the existing pinned files and OFL in `brand-exploration/fonts/`. Full required notices for used families are included inside exported SVG metadata. `manifest.json` records SHA-256 for downloaded files.

R checks every exact file path and internal family, resolves aliases to the pinned paths, and stops if fonts are missing or substituted. Playfair's named Bold instance is index `262144` (700); its variable file remains unmodified. SVG explicitly declares weight 700 because svglite otherwise describes this named instance as normal weight. Browser CSS embeds the official variable file with its 400–900 range. No fonts installed system-wide.

Upstream license notices are kept byte-for-byte, including their trailing spaces. Local attributes keep license LF line endings stable for hash verification on Windows.
