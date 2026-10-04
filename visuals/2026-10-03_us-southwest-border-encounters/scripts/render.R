# Run from repository root. Layout-only rendering of verified processed data.
suppressPackageStartupMessages({library(readr);library(dplyr);library(ggplot2);library(scales);library(grid)})
project <- 'visuals/2026-10-03_us-southwest-border-encounters'
monthly <- read_csv(file.path(project,'data/processed/monthly_encounters.csv'),show_col_types=FALSE)
source(file.path(project,'scripts/term_index.R'))
peak <- monthly |> slice_max(average_daily_encounters,n=1,with_ties=FALSE)
# Optional key renders only the requested chart; default renders both.
args <- commandArgs(trailingOnly=TRUE)
render_target <- if(length(args)) args[[1]] else 'all'
stopifnot(render_target %in% c('all','monthly-timeline','presidential-term-index'))
source(file.path(project,'scripts/charts.R'))
