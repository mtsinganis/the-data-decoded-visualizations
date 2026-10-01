---
title: "A global clock for science: timing patterns in arXiv submissions"
slug: "arxiv-submission-timing-history"
date: "2026-01-30"
topics: [arXiv, Scientific publications]
description: "A global clock for science: timing patterns in arXiv submissions"
status: published
featured: false
charts:
  - file: plots/arxiv_heatmap.png
    alt: "Heatmap of arXiv submission counts from 1991 to January 2026 by month and UTC time of day, showing changes around submission cutoffs."
  - file: plots/arxiv_ridgelines_time_of_day.png
    alt: "Ridgeline chart comparing the distribution of arXiv submission times of day across periods in the archive's history."
  - file: plots/arxiv_ridgelines_month.png
    alt: "Ridgeline chart comparing the distribution of arXiv submissions across months of the year."
  - file: plots/arxiv_monthly_submissions.png
    alt: "Line chart of the monthly number of arXiv submissions over the archive's history."
---

These charts look at when arXiv papers are submitted: across the archive's history, within a day, and through the year. The heatmap groups submissions into monthly by five-minute UTC bins; its colors use a logarithmic count scale. The labels describing eras in the monthly chart are an interpretive framing borrowed from Faruk Alpay's article, not periods or causes established by the submission counts.

## Sources and methodology

The analysis uses arXiv metadata provided by Cornell University and accessed through the [Kaggle arXiv dataset](https://www.kaggle.com/datasets/Cornell-University/arxiv), version 270. The original chart notes data through January 29, 2026. The monthly chart attributes its era labels to [Faruk Alpay's article](https://lightcapai.medium.com/the-event-horizon-of-knowledge-why-3-million-arxiv-papers-are-a-warning-signal-48fc9b74fb33); its first era ends in 2011 on the chart and in 2010 in the article. The [original Quarto analysis](https://github.com/mtsinganis/the-data-decoded-visualizations/blob/main/visuals/2026-01-arXiv-submission-timing-history/index.qmd) parses submission timestamps and produces the heatmap, ridgeline views, and monthly series.
