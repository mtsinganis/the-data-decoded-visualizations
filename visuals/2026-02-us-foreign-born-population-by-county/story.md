---
title: "Where in the U.S. do most foreign-born nationals live?"
slug: "us-foreign-born-population-by-county"
date: "2026-02-17"
topics: [U.S., Immigration]
description: "Share of foreign-born nationals by U.S. county and change from 2009 to 2024"
status: draft
featured: false
charts:
  - file: plots/foreign_born_2024_annotated.png
    alt: "U.S. county map of the foreign-born share of residents in the 2020–2024 American Community Survey estimates, with several high-share counties annotated."
  - file: plots/change_foreign_born_annotated.png
    alt: "U.S. county map comparing foreign-born population share in the 2005–2009 and 2020–2024 ACS estimates, with the largest increases and decreases annotated."
  - file: plots/cumulative_counties_annotated.png
    alt: "Cumulative curve of U.S. counties by foreign-born resident share, showing that 94% of counties have a share below 15%, alongside a county map."
---

The maps show where foreign-born residents live by county and how county shares changed over the period covered by the analysis. The third chart looks at how the foreign-born population is distributed across counties.

## Sources and methodology

The source is the U.S. Census Bureau's American Community Survey five-year estimates, including table B05012, retrieved with `tidycensus`. The original chart notes that estimates have sampling variability and margins of error, especially in counties with smaller populations. The [original Quarto analysis](https://github.com/mtsinganis/the-data-decoded-visualizations/blob/main/visuals/2026-02-us-foreign-born-population-by-county/index.qmd) contains the county calculations and map preparation.
