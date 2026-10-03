# Chart signature asset

pterosaur-simplified.svg is the existing lightly simplified pterosaur approved for the NYC chart signature, copied unchanged from the brand trial. Fill: #2455FF; intrinsic viewBox: 1220 × 900. Preserve its proportions. NYC analysis reads this asset directly; it does not depend on the broader brand-exploration study. This PR does not replace the live website wordmark or regenerate historical charts.

Website preview: the-data-decoded-lockup.svg reproduces the chart signature arrangement with the unchanged blue symbol and embedded Lato Regular 400 wordmark. Its public copy is under website/public/brand/. The Lato OFL notice accompanies the public font files.

Homepage display exception: “Interesting questions, explored through data.” uses the explicit `"Segoe UI", sans-serif` stack, bold 700, 1.12 line height, responsive `clamp(2.15rem, 4vw, 3.25rem)` size and original heading margins. Every other Astro website text element uses Lato. Windows browsers with Segoe UI installed render the named face; other platforms use their sans-serif fallback. Microsoft supplies Segoe UI with Windows rather than as a generally redistributable webfont.
