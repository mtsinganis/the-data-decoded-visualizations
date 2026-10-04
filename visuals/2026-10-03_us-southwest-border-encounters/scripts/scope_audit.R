# Run from repository root after analysis.R. Does not change any source file.
suppressPackageStartupMessages({library(readr);library(dplyr);library(tidyr);library(lubridate);library(rvest)})
project <- 'visuals/2026-10-03_us-southwest-border-encounters'
raw_dir <- file.path(project,'data/raw'); out <- file.path(project,'data/processed')
fy_date <- function(fy,m) as.Date(sprintf('%d-%02d-01',fy-as.integer(m>=10),m))
parse_split <- function(file,fy) {
 tables <- html_table(read_html(file.path(raw_dir,file)),fill=TRUE)
 t <- tables[[which(vapply(tables,function(t) any(t[[1]]=='Southwest Border Total Apprehensions'),logical(1)))]]
 r <- which(t[[1]]=='Southwest Border Total Apprehensions')
 stopifnot(length(r)==1,t[[1]][r+1]=='At Large',t[[1]][r+2]=='At Entry')
 m <- c(10:12,1:9)
 stopifnot(ncol(t)==13)
 tibble(date=fy_date(fy,m),fiscal_year=fy,
 total=parse_number(as.character(unlist(t[r,2:13])),na=c('','-')),
 at_large=parse_number(as.character(unlist(t[r+1,2:13])),na=c('','-')),
 at_entry=parse_number(as.character(unlist(t[r+2,2:13])),na=c('','-')),
 table_source=file) |> filter(!is.na(total))
}
split <- bind_rows(parse_split('nationwide-fy2024.html',2024),parse_split('nationwide-fy2025.html',2025),parse_split('nationwide.html',2026))
stopifnot(nrow(split)==35,!anyDuplicated(split$date),all(split$total==split$at_entry+split$at_large))
releases <- c('fy20-fy23-aor.csv','fy21-fy24-dec2023-aor.csv','fy21-fy24-aor.csv','fy22-fy25-aor.csv','latest-aor.csv')
release_data <- lapply(releases,function(file) {
 d <- read_csv(file.path(raw_dir,file),col_types=cols(.default=col_character()),show_col_types=FALSE)
 d <- d |> filter(Component=='U.S. Border Patrol',`Land Border Region`=='Southwest Land Border') |>
 mutate(fiscal_year=parse_number(`Fiscal Year`),month=match(`Month (abbv)`,toupper(month.abb)),n=as.numeric(`Encounter Count`))
 stopifnot(!anyNA(d$month),!anyNA(d$n))
 d |> group_by(fiscal_year,month) |> summarise(csv_total=sum(n),.groups='drop') |>
 mutate(date=fy_date(fiscal_year,month),release=file)
}) |> bind_rows()
audit <- inner_join(release_data,split,by=c('date','fiscal_year')) |> mutate(csv_minus_table=csv_total-total)
write_csv(audit,file.path(out,'scope_release_reconciliation.csv'))
current <- audit |> filter(release=='latest-aor.csv')
stopifnot(nrow(current)==35,all(current$csv_minus_table==0))
final_historical <- audit |> filter(release=='fy21-fy24-aor.csv')
stopifnot(nrow(final_historical)==12,all(final_historical$csv_minus_table==0))
fy25 <- audit |> filter(release=='fy22-fy25-aor.csv')
stopifnot(nrow(fy25)==24,all(fy25$csv_minus_table==0))
split <- split |> mutate(days_in_month=days_in_month(date),difference=total-at_entry,
 total_daily=total/days_in_month,at_entry_daily=at_entry/days_in_month,difference_daily=difference/days_in_month,
 at_large_share_of_total=100*at_large/total,total_excess_over_at_entry_percent=100*difference/at_entry,
 inclusion_status='At Large inclusion confirmed; first inclusion date unknown')
write_csv(split,file.path(out,'scope_monthly_differences.csv'))
table_lines <- sprintf('| %s | %s | %s | %s | %.2f | %.2f%% |',format(split$date,'%Y-%m'),
 format(split$total,big.mark=',',trim=TRUE),format(split$at_entry,big.mark=',',trim=TRUE),
 format(split$difference,big.mark=',',trim=TRUE),split$difference_daily,split$at_large_share_of_total)
writeLines(c('# Verified monthly Total minus At Entry differences',
 '', 'All values refer to southwest U.S. Border Patrol. Difference = At Large. Daily differences divide by actual days in the calendar month.',
 '', '| Month | Total | At Entry | Difference: At Large | Difference/day | At Large / Total |',
 '| --- | ---: | ---: | ---: | ---: | ---: |',table_lines,
 '', 'Sources: [CBP FY2024](https://www.cbp.gov/newsroom/stats/nationwide-encounters-fy2024), [CBP FY2025](https://www.cbp.gov/newsroom/stats/nationwide-encounters-fy2025), [CBP FY2026](https://www.cbp.gov/newsroom/stats/nationwide-encounters). All 35 monthly totals exactly reconcile to the current official AOR release.',
 '', 'January 2017–September 2023: split unavailable. At Large difference is unknown, not zero. October 2023 is the first quantified month, not a proven inclusion start.'),
 file.path(project,'narrative/monthly-scope-differences.md'))
write_csv(split |> group_by(fiscal_year) |> summarise(months=n(),total=sum(total),at_entry=sum(at_entry),at_large=sum(at_large),
 at_large_share_of_total=100*at_large/total,.groups='drop'),file.path(out,'scope_fiscal_summary.csv'))
all_dates <- tibble(date=seq(as.Date('2017-01-01'),max(split$date),by='month'))
coverage <- all_dates |> left_join(split |> select(date,at_large,at_entry),by='date') |>
 mutate(status=if_else(is.na(at_large),'Split unavailable: interior exclusion unestablished, difference unknown',
 'At Large included in original CSV total; difference quantified'))
write_csv(coverage,file.path(out,'scope_evidence_coverage.csv'))
peak <- split |> slice_max(at_entry_daily,n=1,with_ties=FALSE)
latest <- split |> slice_max(date,n=1)
comparisons <- split |> filter(date %in% c(as.Date('2024-08-01'),as.Date('2025-08-01'),peak$date)) |>
 transmute(comparator_date=date,baseline_at_entry_daily=at_entry_daily,latest_at_entry_daily=latest$at_entry_daily,
 percent_change=100*(latest_at_entry_daily/baseline_at_entry_daily-1),
 status='Same published At Entry classification; not proof of causal effect or crossings that month')
write_csv(comparisons,file.path(out,'comparable_at_entry_comparisons.csv'))
write_csv(tibble(check=c('Published split months Oct2023-Aug2026','CSV total = entry + large (latest)','FY2024 final release = table total','FY2025 final release = table total'),
 result=c('35/35','35/35 exact','12/12 exact','24/24 exact')),file.path(out,'scope_validation.csv'))
cat('First quantifiable included month:',as.character(min(split$date)),'\n');print(split |> select(date,total,at_entry,difference,difference_daily,at_large_share_of_total),n=35)
cat('Early release revisions (not an inclusion-rule change):\n');print(audit |> filter(release=='fy21-fy24-dec2023-aor.csv') |> select(date,csv_total,total,csv_minus_table))
print(comparisons)
