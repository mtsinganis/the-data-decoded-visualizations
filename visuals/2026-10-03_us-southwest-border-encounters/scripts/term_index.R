# Three calendar-year approximations to presidential terms; monthly observations.
out <- file.path(project,'data/processed')
terms <- tibble(term_id=c('trump_first','biden','trump_second'),
 term=c('Trump \u00b7 first term','Biden','Trump \u00b7 second term'),
 start_year=c(2017L,2021L,2025L),end_year=c(2020L,2024L,2028L))
term_baselines <- terms |> mutate(baseline_date=as.Date(paste0(start_year,'-01-01'))) |>
 left_join(monthly |> select(baseline_date=date,baseline_total=monthly_encounters,baseline_days=days_in_month,baseline_daily=average_daily_encounters),by='baseline_date') |>
 mutate(denominator_status=case_when(is.na(baseline_daily) ~ 'missing January',baseline_daily<=0 ~ 'nonpositive January',TRUE ~ 'valid'))
write_csv(term_baselines,file.path(out,'presidential_term_baselines.csv'))
stopifnot(all(term_baselines$denominator_status=='valid'))
term_grid <- bind_rows(lapply(seq_len(nrow(terms)),function(i) tibble(term_id=terms$term_id[i],term_month=1:48,
 date=seq(as.Date(paste0(terms$start_year[i],'-01-01')),by='month',length.out=48))))
term_indexed <- term_grid |> left_join(term_baselines,by='term_id') |>
 left_join(monthly |> select(date,monthly_encounters,days_in_month,average_daily_encounters,source_release,definition_flag),by='date') |>
 mutate(term_year=(term_month-1L)%/%12L+1L,index=100*(average_daily_encounters/baseline_daily),
 availability=if_else(is.na(average_daily_encounters),'not yet available','observed'))
stopifnot(nrow(term_indexed)==144,all(term_indexed$index[term_indexed$term_month==1]==100),
 sum(!is.na(term_indexed$index))==116,
 all(is.na(term_indexed$index[term_indexed$term_id=='trump_second' & term_indexed$term_month>20])))
term_coverage <- term_indexed |> filter(!is.na(index)) |> group_by(term_id,term) |>
 summarise(first_date=min(date),last_date=max(date),observations=n(),last_term_month=max(term_month),.groups='drop')
stopifnot(identical(term_coverage$observations[match(terms$term_id,term_coverage$term_id)],c(48L,48L,20L)),
 all(term_indexed$date[term_indexed$term_month==13]==as.Date(c('2018-01-01','2022-01-01','2026-01-01'))),
 all(term_coverage$last_date[match(terms$term_id,term_coverage$term_id)]==as.Date(c('2020-12-01','2024-12-01','2026-08-01'))))
write_csv(term_indexed,file.path(out,'presidential_term_index.csv'))
write_csv(term_coverage,file.path(out,'presidential_term_coverage.csv'))
checks <- term_indexed |> filter(date %in% as.Date(c('2019-05-01','2020-02-01','2023-12-01','2024-02-01','2025-02-01','2026-08-01'))) |>
 mutate(independent_index=100*((monthly_encounters/days_in_month)/(baseline_total/baseline_days)),difference=index-independent_index)
stopifnot(all(abs(checks$difference)<1e-10))
write_csv(checks |> select(term,date,term_month,monthly_encounters,days_in_month,baseline_total,baseline_days,index,independent_index,difference),file.path(out,'presidential_term_independent_checks.csv'))
write_csv(tibble(check=c('Baseline indices = 100','Observed monthly counts per term','Month 13 = next January','Four-year endpoints exclude following January','Second term ends August 2026 at month 20','Unavailable months remain missing','Independent count/day checks'),
 result=c('3/3 exact','48 / 48 / 20','3/3 exact','December 2020 / December 2024','Exact','28 missing; no interpolation','6/6 exact')),file.path(out,'presidential_term_validation.csv'))
print(term_baselines |> select(term,baseline_date,baseline_daily))
cat('Term index maximum:',max(term_indexed$index,na.rm=TRUE),'\n')
