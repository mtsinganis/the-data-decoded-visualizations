---
title: "Puerto Rican Residents in the United States: Mainland Diaspora and Island Population (2024)"
slug: "puerto-rican-population-in-us-and-pr"
date: "2026-02-11"
topics: [U.S., Puerto Rico, Bad Bunny]
description: "Puerto Rican-origin population in U.S. counties and total residents of Puerto Rico's municipios in 2024."
status: published
featured: false
charts:
  - file: plots/puerto_ricans_us.png
    alt: "Map of Puerto Rican-origin residents by U.S. county with a Puerto Rico inset, beside bars ranking the largest counties and municipios in 2024."
  - file: plots/northeast.png
    alt: "County map of the number of Puerto Rican-origin residents in the northeastern United States in 2024."
  - file: plots/florida.png
    alt: "County map of the number of Puerto Rican-origin residents in Florida in 2024."
  - file: plots/puerto_rico.png
    alt: "Map of total resident population by Puerto Rican municipio in 2024."
---

The first chart combines a mainland county map, a Puerto Rico inset, and a ranking of counties and municipios. The following maps look more closely at the northeastern U.S., Florida, and Puerto Rico.

## Sources and methodology

The source is the U.S. Census Bureau's 2020–2024 American Community Survey five-year estimates, retrieved with `tidycensus`. For the 50 states and D.C., the chart counts people reporting Puerto Rican origin or descent (table B03001_005E). For Puerto Rico, it uses total resident population by municipio (table B01003_001E); these are different measures. Alaska, Hawaii, and Puerto Rico are repositioned and rescaled in the overview for visibility. The [original Quarto analysis](https://github.com/mtsinganis/the-data-decoded-visualizations/blob/main/visuals/2026-02-puerto-rican-population-in-us-and-pr/index.qmd) contains the map and ranking calculations.
