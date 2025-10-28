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
