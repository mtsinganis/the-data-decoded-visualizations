---
title: "Why Europe travels together: the drivers behind the July–August peak across the continent's short-term rental markets"
slug: "str-europe-peak-season"
date: "2025-11-26"
topics: [STR, Europe, occupancy, AirDNA, Tourism]
description: "An analysis of occupancy data from Europe's top 25 largest short-term rental markets in 2024"
status: published
featured: false
charts:
  - file: plots/thumb.png
    alt: "Heatmap of monthly short-term rental occupancy across 25 European markets in 2024, with July and August highlighted as the peak period."
  - file: plots/line_chart.svg
    alt: "Lines comparing normalized monthly short-term rental occupancy patterns across European countries in 2024."
  - file: plots/share_of_year_at_occupancy.svg
    alt: "Chart comparing how much of the year European short-term rental markets remain near their peak occupancy."
---

Europe's short-term rental markets show a shared summer peak despite differences in climate and location. The charts examine 2024 occupancy data for 25 large markets, comparing monthly patterns and the length of each market's busy season.

## Reading the seasonal pattern

School holidays, workplace leave, transport schedules, climate, and seasonal accommodation supply may all shape when people travel. [Eurostat's 2024 regional tourism statistics](https://ec.europa.eu/eurostat/statistics-explained/SEPDF/cache/1945.pdf?v=7690771989285447) also show that July and August were the busiest months for overnight stays in most EU regions. That broader measure is consistent with a summer peak, but it does not establish which of these factors caused the AirDNA occupancy pattern or how much each contributed.

## Sources and methodology

The occupancy data are attributed to AirDNA (2025) in the original charts. The Quarto analysis selects the 25 European markets with the most average active listings in 2024, normalizes each market's monthly occupancy to its own annual range, and calculates the share of the year above each normalized occupancy threshold. Its processing steps and definitions remain in the [original analysis](https://github.com/mtsinganis/the-data-decoded-visualizations/blob/main/visuals/2025-11-str-europe-peak-season/index.qmd). Eurostat's overnight-stay measure is separate from AirDNA's occupancy series.
