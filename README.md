<p align="center">
  <img src="https://raw.githubusercontent.com/your-username/The-Data-Decoded/main/plots/banner.png" width="800" alt="The Data Decoded">
</p>

<h3 align="center">Turning data into insight — one chart at a time</h3>

<p align="center">
  <a href="https://x.com/TheDataDecoder">X (Twitter)</a> •
  <a href="https://yourusername.github.io/The-Data-Decoded">Website</a>
</p>

---


# 🧠 The Data Decoded Visualizations

Welcome to **The Data Decoded Visualizations** — a public collection of data-driven stories and charts shared on [X (Twitter)](https://x.com/TheDataDecoded).  
Each visualization is built with **R** and **Quarto**, combining open data, transparent code, and thoughtful design.

---

## 📁 Repository Structure

```text
the-data-decoded-visualizations/
│
├── _quarto.yml          # Quarto configuration file (website setup)
├── index.qmd            # Homepage listing all visuals
│
├── data/                # Raw or processed datasets
│   └── airbnb_demand_uk_2018_2024.csv
│
├── visuals/             # Each chart as its own Quarto file (.qmd)
│   ├── 2025-01_airbnb-demand.qmd
│   └── 2025-02_example-chart.qmd
│
├── plots/               # Final exported images (PNG, SVG, PDF)
│
├── R/                   # Reusable R functions and themes
│   └── theme_data_decoder.R
│
└── docs/                # Auto-generated HTML files (GitHub Pages output)

Each .qmd file inside visuals/ contains:

The R code that generates the visualization

The rendered chart

A short explanation and data source

The homepage (index.qmd) automatically lists all visuals.
