# Run from repository root after scripts/retrieve.R and scripts/extract_pdf.py.
suppressPackageStartupMessages({library(readr);library(dplyr);library(tidyr);library(lubridate);library(rvest);library(ggplot2);library(scales);library(grid)})
project <- 'visuals/2026-10-03_us-southwest-border-encounters'
raw_dir <- file.path(project,'data/raw'); out <- file.path(project,'data/processed')
fy_date <- function(fy,m) as.Date(sprintf('%d-%02d-01',fy-as.integer(m>=10),m))
stopifnot(fy_date(2018,10)==as.Date('2017-10-01'),fy_date(2020,2)==as.Date('2020-02-01'),days_in_month(fy_date(2020,2))==29)
historical <- lapply(2017:2019,function(y) {
 t <- html_table(read_html(file.path(raw_dir,paste0('fy',y,'.html'))),fill=TRUE)[[1]]
 stopifnot(names(t)[1]=='USBP')
 row <- t[grepl('Southwest Border Total',t[[2]],fixed=TRUE),]
 stopifnot(nrow(row)==1)
 n <- parse_number(as.character(unlist(row[3:14])))
 stopifnot(length(n)==12,all(!is.na(n)),sum(n)==parse_number(as.character(row[[15]])))
 tibble(fiscal_year=y,month=c(10:12,1:9),date=fy_date(y,c(10:12,1:9)),monthly_encounters=n,
 source_release=paste0('CBP FY',y,' monthly HTML'),rank=0L)
}) |> bind_rows()
pdf <- read_csv(file.path(out,'pdf_monthly_check.csv'),show_col_types=FALSE)
pdf_check <- inner_join(historical,pdf,by=c('fiscal_year','month'),suffix=c('_html','_pdf'))
stopifnot(nrow(pdf_check)==24,all(pdf_check$monthly_encounters_html==pdf_check$monthly_encounters_pdf))
write_csv(pdf_check,file.path(out,'pdf_reconciliation.csv'))
sectors <- c('Big Bend Sector','Del Rio Sector','El Centro Sector','El Paso Sector','Laredo Sector',
 'Rio Grande Valley Sector','San Diego Sector','Tucson Sector','Yuma Sector')
releases <- c('fy20-fy23-aor.csv','fy21-fy24-aor.csv','fy22-fy25-aor.csv','latest-aor.csv')
details <- lapply(seq_along(releases),function(i) {
 d <- read_csv(file.path(raw_dir,releases[i]),col_types=cols(.default=col_character()),show_col_types=FALSE)
 names(d) <- tolower(gsub('[^a-z0-9]+','_',tolower(names(d))))
 d <- d |> mutate(fiscal_year=parse_number(fiscal_year),month=match(month_abbv_,toupper(month.abb)),encounter_count=as.numeric(encounter_count))
 stopifnot(!anyNA(d$month),!anyNA(d$encounter_count),all(d$encounter_count>=0),all(d$encounter_count==floor(d$encounter_count)))
 keys <- c('fiscal_year','month','component','land_border_region','area_of_responsibility','demographic','citizenship','title_of_authority','encounter_type')
 stopifnot(!anyDuplicated(d[keys]))
 d <- d |> filter(component=='U.S. Border Patrol',land_border_region=='Southwest Land Border')
 stopifnot(all(d$demographic %in% c('FMUA','Single Adults','UC / Single Minors','UAC')),
 !any(grepl('TOTAL|ALL',d$citizenship)),!anyNA(d$citizenship))
 stopifnot(all(d$area_of_responsibility %in% sectors),all(d$encounter_type %in% c('Apprehensions','Expulsions')),
 all((d$title_of_authority=='Title 8' & d$encounter_type=='Apprehensions') | (d$title_of_authority=='Title 42' & d$encounter_type=='Expulsions')))
 d |> group_by(fiscal_year,month) |> summarise(monthly_encounters=sum(encounter_count),title42=sum(encounter_count[title_of_authority=='Title 42']),.groups='drop') |>
 mutate(date=fy_date(fiscal_year,month),source_release=releases[i],rank=i)
}) |> bind_rows()
stopifnot(all(details$title42[details$date<as.Date('2020-03-01') | details$date>as.Date('2023-05-01')]==0))
# Audit revisions; choose the whole newer monthly release, never sum releases.
revisions <- details |> arrange(date,rank) |> group_by(date) |> mutate(previous=lag(monthly_encounters),revision=monthly_encounters-previous) |> ungroup()
write_csv(revisions,file.path(out,'release_overlap_audit.csv'))
preferred <- details |> arrange(date,desc(rank)) |> distinct(date,.keep_all=TRUE)
fy2020_table <- html_table(read_html(file.path(raw_dir,'fy2020.html')),fill=TRUE)[[1]]
row20 <- fy2020_table[grepl('Southwest Border Total',fy2020_table[[2]],fixed=TRUE),]
check20 <- preferred |> filter(fiscal_year==2020) |> arrange(match(month,c(10:12,1:9)))
stopifnot(all(check20$monthly_encounters==parse_number(as.character(unlist(row20[3:14])))))
write_csv(preferred |> group_by(fiscal_year) |> summarise(months=n(),total=sum(monthly_encounters),.groups='drop'),file.path(out,'fiscal_totals.csv'))
# Prior-year tables establish inclusion from at least October 2023, not October 2025.
source(file.path(project,'scripts/scope_audit.R'))
recent <- split
write_csv(recent |> select(date,total,at_large,at_entry,days_in_month,total_daily,at_entry_daily,difference_daily),file.path(out,'recent_scope_reconciliation.csv'))
latest <- max(preferred$date)
stopifnot(latest==max(recent$date))
historical_totals <- bind_rows(historical,preferred) |> filter(date>=as.Date('2017-01-01'))
write_csv(historical_totals |> mutate(calendar_year=year(date),days_in_month=days_in_month(date),average_daily_encounters=monthly_encounters/days_in_month,
 definition_flag=if_else(date>=min(split$date),'At Large included: confirmed by split table','Interior exclusion unestablished: split unavailable')),file.path(out,'reported_total_series.csv'))
entry <- recent |> transmute(date,monthly_encounters=at_entry,month=month(date),fiscal_year,
 calendar_year=year(date),days_in_month=days_in_month(date),average_daily_encounters=at_entry/days_in_month,
 source_release=table_source,definition_flag='at_entry_excludes_at_large_pre_oct2023_equivalence_unresolved',series='At entry sensitivity')
write_csv(entry,file.path(out,'at_entry_sensitivity.csv'))
monthly <- tibble(date=seq(as.Date('2017-01-01'),latest,by='month')) |> left_join(historical_totals,by='date') |>
 mutate(calendar_year=year(date),month=month(date),days_in_month=days_in_month(date),
 average_daily_encounters=monthly_encounters/days_in_month,
 series='Published total',
 definition_flag=if_else(date>=min(split$date),'At Large included: confirmed by split table','Interior exclusion unestablished: split unavailable'),
 title42_period=date>=as.Date('2020-03-01') & date<=as.Date('2023-05-01'),
 split_available=date>=min(split$date))
stopifnot(nrow(monthly)==116,!anyDuplicated(monthly$date),!anyNA(monthly$monthly_encounters))
stopifnot(identical(monthly$monthly_encounters,historical_totals$monthly_encounters),all(monthly$series=='Published total'))
write_csv(monthly |> select(date,calendar_year,month,days_in_month,monthly_encounters,average_daily_encounters,source_release,definition_flag,series,title42_period,split_available),file.path(out,'monthly_encounters.csv'))
source(file.path(project,'scripts/term_index.R'))
write_csv(tibble(check=c('Expected months Jan2017-Aug2026','Duplicate monthly keys','Missing observations','PDF vs HTML monthly values','FY2020 HTML vs CSV','FY2024-FY2026 total = entry + large = CSV'),
 result=c('116/116','0','0','24/24 exact','12/12 exact','35/35 exact')),file.path(out,'validation.csv'))
peak <- monthly |> slice_max(average_daily_encounters,n=1,with_ties=FALSE)
aug <- monthly |> filter(month==8,calendar_year %in% c(2024,2025,2026))
write_csv(aug,file.path(out,'august_comparisons.csv'))
total_latest <- recent$total[nrow(recent)]/days_in_month(latest)
comparisons <- tibble(comparator=c('August 2024 historical','August 2025 historical','Historical peak'),
 baseline_daily=c(split$total_daily[split$date==as.Date('2024-08-01')],split$total_daily[split$date==as.Date('2025-08-01')],max(historical_totals$monthly_encounters/days_in_month(historical_totals$date))),
 latest_total_daily=total_latest,percent_change=100*(latest_total_daily/baseline_daily-1),
 status='Reported-total comparison: all these comparator months demonstrably include At Large; not an At Entry comparison')
write_csv(comparisons,file.path(out,'provisional_total_comparisons.csv'))
write_csv(comparisons,file.path(out,'published_total_comparisons.csv'))
turning_points <- monthly |> filter(date %in% as.Date(c('2023-12-01','2024-01-01','2024-06-01','2024-12-01','2025-01-01','2025-02-01','2025-12-01','2026-08-01')))
write_csv(turning_points,file.path(out,'timeline_findings.csv'))
write_csv(tibble(check=c('Timeline equals published totals throughout','Total = entry + large','Three starting January indices = 100',
 'Leap-year February uses 29 days','Future second-term months 21-48 missing','No clipped index peaks'),
 result=c('116/116 exact','35/35 exact','3/3 exact','Independent count/day checks','28/28 missing','Upper limit derived from observed maximum')),
 file.path(out,'chart_validation.csv'))
cat('Latest',as.character(latest),'total',total_latest,'peak',as.character(peak$date),peak$average_daily_encounters,'max index',max(term_indexed$index,na.rm=TRUE),'\n')
print(comparisons)
source(file.path(project,'scripts/charts.R'))


