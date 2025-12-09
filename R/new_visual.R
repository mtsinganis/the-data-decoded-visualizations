# =====================================================
# Function: new_visual()
# Purpose : Create a new visualization folder structure
#           with template files and subdirectories.
# =====================================================

new_visual <- function(slug, title, date = Sys.Date()) {
    # ---- Base folders ----
    base_dir <- "visuals"
    visual_dir <- file.path(base_dir, slug)
    data_dir  <- file.path(visual_dir, "data")
    plots_dir <- file.path(visual_dir, "plots")
    
    # ---- Create directories ----
    dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
    dir.create(plots_dir, recursive = TRUE, showWarnings = FALSE)
    
    # ---- Create index.qmd template ----
    index_path <- file.path(visual_dir, "index.qmd")
    
    if (!file.exists(index_path)) {
        template <- sprintf(
            "---
title: \"%s\"
date: \"%s\"
categories: []
image: plots/thumb.svg
description: \"\"
format: html
execute:
  dir: project
  echo: false
  output: false
---

# Text explaining chart

```{r echo=FALSE, output=FALSE}
# Load required packages
library(tidyverse)
# library(rprojroot)  # optional, if needed for root detection

# Source custom ggplot theme if applicable
# source(\"R/theme_data_decoded.R\")
# theme_set(theme_data_decoded())

# Read dataset (adjust path and filename)
# data <- read_csv(\"visuals/%s/data/your_dataset.csv\")

# Create plot (edit this example)
# p <- ggplot(data, aes(x, y)) +
#   geom_line(linewidth = 1.2, color = \"#192951\") +
#   geom_point(size = 2.5, color = \"#192951\")

# Display plot
# p

# Save thumbnail for homepage listing



if (!dir.exists(\"visuals/%s/plots\")) dir.create(\"visuals/%s/plots\", recursive = TRUE)

ggsave(\"visuals/%s/plots/thumb.png\", p, width = 8, height = 5, dpi = 220)

", 
            title, date, slug, slug, slug, slug
        )
        writeLines(template, index_path)
    }
}