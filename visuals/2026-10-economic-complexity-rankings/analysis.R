# Run from the repository root. Cached, checksum-verified version 12.0 by default.
# Set TDD_REFRESH=1 to re-download that pinned version; never silently change vintage.
project <- 'visuals/2026-10-economic-complexity-rankings'
required <- c('ggplot2','ggbump','dplyr','tidyr','ggrepel','ragg','svglite',
              'systemfonts','rsvg','png','readr','jsonlite','digest','curl','xml2')
missing <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop('Missing R packages: ',paste(missing,collapse=', '))
suppressPackageStartupMessages({library(dplyr);library(tidyr);library(ggplot2);library(grid)})
data_dir <- file.path(project,'data'); plot_dir <- file.path(project,'plots')
source(file.path(project,'scripts/01_download_data.R'),encoding='UTF-8')
source(file.path(project,'scripts/02_validate_analyze.R'),encoding='UTF-8')
source(file.path(project,'scripts/03_create_chart.R'),encoding='UTF-8')
writeLines(capture.output(sessionInfo()),file.path(data_dir,'session-info.txt'))
