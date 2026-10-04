# Run from repository root. Existing snapshots are immutable; remove nothing automatically.
library(xml2); library(rvest); library(readr); library(dplyr)
project <- 'visuals/2026-10-03_us-southwest-border-encounters'
raw_dir <- file.path(project,'data/raw')
fetch <- function(url,file) {
  dest <- file.path(raw_dir,file)
  if(!file.exists(dest)) download.file(url,dest,mode='wb',method='libcurl')
  dest
}
listing_url <- 'https://www.cbp.gov/document/stats/nationwide-encounters'
listing <- fetch(listing_url,'official-listing.html')
links <- html_attr(html_elements(read_html(listing),'a'),'href')
aor <- unique(links[!is.na(links) & grepl('nationwide-encounters.*aor.*\\.csv$',links)])
stopifnot(length(aor)>0)
# The saved listing is ordered newest first. Never guess a release filename.
latest_url <- paste0('https://www.cbp.gov',aor[1])
sources <- tibble(file=c('official-listing.html','latest-aor.csv','fy22-fy25-aor.csv',
 'fy21-fy24-aor.csv','fy20-fy23-aor.csv','nationwide.html','fy2017.html','fy2018.html',
 'fy2019.html','fy2020.html','fy2018-monthly.pdf','data-dictionary.pdf','cbp_resp.csv','tidytuesday-readme.md','southwest.html'),
 url=c(listing_url,latest_url,
 'https://www.cbp.gov/sites/default/files/2025-11/nationwide-encounters-fy22-fy25-aor.csv',
 'https://www.cbp.gov/sites/default/files/2024-10/nationwide-encounters-fy21-fy24-aor.csv',
 'https://www.cbp.gov/sites/default/files/assets/documents/2023-Nov/nationwide-encounters-fy20-fy23-aor.csv',
 'https://www.cbp.gov/newsroom/stats/nationwide-encounters',
 'https://www.cbp.gov/newsroom/stats/sw-border-migration-fy2017',
 'https://www.cbp.gov/newsroom/stats/sw-border-migration/fy-2018',
 'https://www.cbp.gov/newsroom/stats/sw-border-migration/fy-2019',
 'https://www.cbp.gov/newsroom/stats/sw-border-migration-fy2020',
 'https://www.cbp.gov/sites/default/files/assets/documents/2019-Mar/bp-total-monthly-apps-sector-area-fy2018.pdf',
 'https://www.cbp.gov/sites/default/files/assets/documents/2023-Sep/nationwide-encounters-data-dictionary.pdf',
 'https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2024/2024-11-26/cbp_resp.csv',
 'https://raw.githubusercontent.com/rfordatascience/tidytuesday/main/data/2024/2024-11-26/readme.md',
 'https://www.cbp.gov/newsroom/stats/southwest-land-border-encounters'),
 coverage=c('Listing through August 2026','FY2023-FY2026 through August', 'FY2022-FY2025',
 'FY2021-FY2024','FY2020-FY2023','FY2026 October-August; definitions', 'FY2017','FY2018',
 'FY2019','FY2020','FY2000-FY2018','Dictionary September 2023','FY2020-FY2024 combined mirror',
 'Mirror provenance and cleaning code','Dashboard; no static tables'))
for(i in seq_len(nrow(sources))) fetch(sources$url[i],sources$file[i])
sources <- sources |> mutate(retrieval_date='2026-10-03',original_attribution='U.S. Customs and Border Protection',
 retrieval_location=url,md5=unname(tools::md5sum(file.path(raw_dir,file))),
 definitions=case_when(file=='latest-aor.csv' ~ 'USBP southwest FY2026 includes At Large; do not join as border-only',
 file=='cbp_resp.csv' ~ 'Mirror bind_rows + unique is not release precedence; audit only, not analytical input',
 TRUE ~ 'See narrative methodology; filter component and geography; never sum subtotals with detail'))
extra <- tibble(file=c('nationwide-fy2024.html','nationwide-fy2025.html','fy21-fy24-dec2023-aor.csv','ohss-dictionary-listing.html','ohss-cbp-dictionary.xlsx'),
 url=c('https://www.cbp.gov/newsroom/stats/nationwide-encounters-fy2024',
 'https://www.cbp.gov/newsroom/stats/nationwide-encounters-fy2025',
 'https://www.cbp.gov/sites/default/files/assets/documents/2024-Jan/nationwide-encounters-fy21-fy24-dec-aor.csv',
 'https://ohss.dhs.gov/about-our-data/governance/data-dictionaries/key-homeland-security-metrics-cbp-encounters',
 'https://ohss.dhs.gov/system/files/2026-05/Data-Dictionary-KHSM-CBP-Encounters.xlsx'),
 coverage=c('FY2024 complete monthly total/entry/large split','FY2025 complete monthly total/entry/large split',
 'FY2021-FY2024 through December 2023; early release audit only','KHSM dictionary listing May 2026','KHSM dictionary May 2026; separate report, not the CBP portal schema'))
for(i in seq_len(nrow(extra))) fetch(extra$url[i],extra$file[i])
extra <- extra |> mutate(retrieval_date='2026-10-04',original_attribution=if_else(grepl('ohss',file),'DHS Office of Homeland Security Statistics','U.S. Customs and Border Protection'),
 retrieval_location=url,md5=unname(tools::md5sum(file.path(raw_dir,file))),
 definitions=if_else(grepl('ohss',file),'Separate KHSM product; not evidence of a CBP portal counting-rule change',
 'Historical scope audit; earliest confirmed split October 2023; not a proven inclusion start date'))
listing_check <- tibble(file='official-listing-2026-10-04.html',url=listing_url,
 coverage='Fresh verification: latest AOR remains August 2026',retrieval_date='2026-10-04',
 original_attribution='U.S. Customs and Border Protection',retrieval_location=listing_url,
 md5=unname(tools::md5sum(file.path(raw_dir,'official-listing-2026-10-04.html'))),
 definitions='Latest availability check only; original snapshots preserved')
check_links <- html_attr(html_elements(read_html(file.path(raw_dir,listing_check$file)),'a'),'href')
check_aor <- unique(check_links[!is.na(check_links) & grepl('nationwide-encounters.*aor.*\\.csv$',check_links)])
stopifnot(check_aor[1]==aor[1])
write_csv(bind_rows(sources,extra,listing_check),file.path(project,'data/source_manifest.csv'))
cat('Frozen official listing newest release:',latest_url,'\n')
