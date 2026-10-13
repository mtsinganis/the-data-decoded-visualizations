# Official ranks are preserved. Names come from the mirror; identifiers stay official.
names_map <- mirror %>% distinct(country_code,country)
stopifnot(!anyDuplicated(names_map$country_code),!anyDuplicated(raw[c('country_iso3_code','year')]))
all_data <- raw %>% transmute(country_id,country_code=country_iso3_code,year,
  in_rankings,global_rank=eci_rank_hs92,eci_score=eci_hs92) %>%
  left_join(names_map,by='country_code') %>% arrange(country_code,year)
d <- all_data %>% filter(!is.na(global_rank))
stopifnot(setequal(d$year,1995:2024),all(d$global_rank>=1),
  all(d$global_rank==floor(d$global_rank)),all(grepl('^[A-Z]{3}$',d$country_code)),
  all(!is.na(d$eci_score)),all(!is.na(d$country)))
readr::write_csv(all_data,file.path(data_dir,'eci_historical_clean.csv'),na='NA')
comparison <- full_join(d %>% select(country_code,year,official_rank=global_rank,official_score=eci_score),
  mirror %>% transmute(country_code,year=data_year,mirror_rank=global_rank,mirror_score=eci_score),
  by=c('country_code','year')) %>% mutate(matched=!is.na(official_rank) & !is.na(mirror_rank) &
    official_rank==mirror_rank & abs(official_score-mirror_score)<1e-9)
readr::write_csv(comparison,file.path(data_dir,'mirror_crosscheck.csv'))
stopifnot(all(comparison$matched))
coverage <- d %>% group_by(year) %>% summarise(economies=n(),min_rank=min(global_rank),
  max_rank=max(global_rank),duplicate_ranks=n()-n_distinct(global_rank),
  rounded_score_ties=n()-n_distinct(eci_score),.groups='drop')
stopifnot(coverage$economies[1]==140,tail(coverage$economies,1)==145,
  all(coverage$duplicate_ranks==0),all(coverage$max_rank==coverage$economies))
readr::write_csv(coverage,file.path(data_dir,'coverage_by_year.csv'))
readr::write_csv(all_data %>% filter(is.na(global_rank)),file.path(data_dir,'unranked_observations.csv'))
readr::write_csv(d %>% group_by(year,eci_score) %>% filter(n()>1) %>% ungroup(),
  file.path(data_dir,'rounded_score_ties.csv'))
highlight_codes <- c('VNM','CHN','AUS','PHL')
colors <- c(VNM='#8056B3',CHN='#168765',AUS='#2455FF',PHL='#D08A28')
h <- d %>% filter(country_code %in% highlight_codes) %>% group_by(country_code) %>%
  arrange(year,.by_group=TRUE) %>% mutate(annual_rank_improvement=lag(global_rank)-global_rank,
    annual_score_change=eci_score-lag(eci_score)) %>% ungroup()
stopifnot(nrow(h)==120,all(table(h$country_code)==30),!anyNA(h$global_rank))
summary <- h %>% group_by(country_code,country) %>% summarise(initial_rank=first(global_rank),
  final_rank=last(global_rank),net_improvement=initial_rank-final_rank,
  total_absolute_movement=sum(abs(annual_rank_improvement),na.rm=TRUE),
  greatest_annual_improvement=max(annual_rank_improvement,na.rm=TRUE),
  greatest_annual_deterioration=-min(annual_rank_improvement,na.rm=TRUE),
  improvement_intervals=paste(paste0(year[annual_rank_improvement==max(annual_rank_improvement,na.rm=TRUE) & !is.na(annual_rank_improvement)]-1,'\u2013',year[annual_rank_improvement==max(annual_rank_improvement,na.rm=TRUE) & !is.na(annual_rank_improvement)]),collapse=';'),
  deterioration_intervals=paste(paste0(year[annual_rank_improvement==min(annual_rank_improvement,na.rm=TRUE) & !is.na(annual_rank_improvement)]-1,'\u2013',year[annual_rank_improvement==min(annual_rank_improvement,na.rm=TRUE) & !is.na(annual_rank_improvement)]),collapse=';'),
  improving_years=sum(annual_rank_improvement>0,na.rm=TRUE),
  deteriorating_years=sum(annual_rank_improvement<0,na.rm=TRUE),unchanged_years=sum(annual_rank_improvement==0,na.rm=TRUE),
  initial_score=first(eci_score),final_score=last(eci_score),score_change=final_score-initial_score,
  rank_year_spearman=cor(year,global_rank,method='spearman'),
  score_year_spearman=cor(year,eci_score,method='spearman'),.groups='drop')
targets <- data.frame(country_code=highlight_codes,expected_initial=c(119,42,33,69),expected_final=c(44,10,73,38))
checks <- left_join(summary,targets,by='country_code') %>% mutate(
  matched=initial_rank==expected_initial & final_rank==expected_final)
stopifnot(all(checks$matched))
readr::write_csv(checks,file.path(data_dir,'endpoint_checks.csv'))
readr::write_csv(summary,file.path(data_dir,'trajectory_summary.csv'))
readr::write_csv(h,file.path(data_dir,'highlighted_trajectories.csv'))
readr::write_csv(h %>% filter(!is.na(annual_rank_improvement)),file.path(data_dir,'annual_movements.csv'))
crossovers <- bind_rows(lapply(combn(highlight_codes,2,simplify=FALSE),function(pair) {
  a <- filter(h,country_code==pair[1]); b <- filter(h,country_code==pair[2])
  difference <- a$global_rank-b$global_rank
  idx <- which(sign(difference[-1])!=sign(head(difference,-1)))+1L
  data.frame(country_a=rep(pair[1],length(idx)),country_b=rep(pair[2],length(idx)),
    from_year=a$year[idx-1],to_year=a$year[idx],
    overtaking=as.character(ifelse(difference[idx]<0,pair[1],pair[2])),
    a_rank_before=a$global_rank[idx-1],b_rank_before=b$global_rank[idx-1],
    a_rank_after=a$global_rank[idx],b_rank_after=b$global_rank[idx])
}))
readr::write_csv(crossovers,file.path(data_dir,'crossover_analysis.csv'))
# All economies are displayed; there is no background sampling.
# Split every series at missing annual observations. No smoothing across gaps.
d <- d %>% group_by(country_code) %>% arrange(year,.by_group=TRUE) %>%
  mutate(segment=cumsum(c(TRUE,diff(year)!=1)),line_group=paste(country_code,segment)) %>% ungroup()
audit <- list(vintage='12.0',classification='HS92',release_utc=metadata$releaseTime,
  ranked_rows=nrow(d),years=sort(unique(d$year)),economies=n_distinct(d$country_code),
  duplicate_country_years=0,rank_ties=0,mirror_matches=sum(comparison$matched),
  rank_recalculation=FALSE,interpolation=FALSE,background_count=141,highlight_count=4,
  missing_highlighted=0,identifiers='Official country_id and country_iso3_code retained',
  aggregate_check='All ranked identifiers match the mirror country list; no region or income aggregate',
  rounded_score_ties='Rounded ECI scores can tie; supplied global ranks remain unique. No re-ranking.')
jsonlite::write_json(audit,file.path(data_dir,'audit.json'),pretty=TRUE,auto_unbox=TRUE)
print(summary); print(crossovers)

