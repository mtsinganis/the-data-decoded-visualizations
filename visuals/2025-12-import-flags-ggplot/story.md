---
title: "How to add rectangular, square or round country flags to ggplots"
slug: "import-flags-ggplot"
date: "2025-12-16"
topics: [R, ggplot, flags, DataViz, Corruption Index]
description: "An example comparing the Corruption Perception Index Europe's Big Four (France, Germany, UK and Italy) in 2024"
status: published
featured: false
charts:
  - file: plots/corruption_index_big_four_round.png
    alt: "2024 Corruption Perceptions Index scores for European countries, with France, Germany, Italy, and the United Kingdom highlighted and round flags beside country names."
  - file: plots/corruption_index_big_four_square.png
    alt: "The same 2024 European Corruption Perceptions Index comparison using square country flags."
  - file: plots/corruption_index_big_four_rect.png
    alt: "The same 2024 European Corruption Perceptions Index comparison using rectangular country flags."
---

Country flags can make familiar places quick to recognize in a chart, but they can also distract from the data or make a chart harder to read for people who do not know the flags. These three versions of the same Corruption Perceptions Index comparison show how round, square, and rectangular flags affect the presentation.

Flags can save label space and add visual appeal, particularly for familiar countries. Their strong colors can also compete with the data, and readers who do not recognize a flag still need a text label. Different flag proportions create alignment problems when a chart uses them as repeated symbols.

The original article includes a reusable R function for downloading flags and placing them in ggplot charts. The three exports here show its round, square, and rectangular options on the same CPI comparison.

## Sources and methodology

The CPI comparison uses Transparency International's 2024 results. The flag graphics come from the [flag-icons gallery](https://flagicons.lipis.dev/) by Panayiotis Lipiridis. The [original Quarto analysis](https://github.com/mtsinganis/the-data-decoded-visualizations/blob/main/visuals/2025-12-import-flags-ggplot/index.qmd) documents the flag conversion and the three chart variants.
