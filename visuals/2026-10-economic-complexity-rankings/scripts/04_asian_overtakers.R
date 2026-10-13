# Supplemental question audit. Run from repository root after analysis.R.
suppressPackageStartupMessages({library(dplyr);library(readr)})
project <- 'visuals/2026-10-economic-complexity-rankings'
data_dir <- file.path(project,'data')
# Transcribed from the UN M49 Asia rows, verified 2026-10-13:
# https://unstats.un.org/unsd/methodology/m49/overview/
regions <- list('Central Asia'=c('KAZ','KGZ','TJK','TKM','UZB'),
  'Eastern Asia'=c('CHN','HKG','MAC','PRK','JPN','MNG','KOR'),
  'South-eastern Asia'=c('BRN','KHM','IDN','LAO','MYS','MMR','PHL','SGP','THA','TLS','VNM'),
  'Southern Asia'=c('AFG','BGD','BTN','IND','IRN','MDV','NPL','PAK','LKA'),
  'Western Asia'=c('ARM','AZE','BHR','CYP','GEO','IRQ','ISR','JOR','KWT','LBN','OMN','QAT','SAU','PSE','SYR','TUR','ARE','YEM'))
geography <- bind_rows(lapply(names(regions),function(r)data.frame(country_code=regions[[r]],
  subregion=r,classification='UN M49',source='https://unstats.un.org/unsd/methodology/m49/overview/',accessed='2026-10-13')))
stopifnot(nrow(geography)==50,!anyDuplicated(geography$country_code))
# Atlas reports Taiwan separately. Include it in the geographic screening;
# it is not a separate row in the UN M49 overview.
geography <- bind_rows(geography,data.frame(country_code='TWN',subregion='Eastern Asia',
  classification='Supplement: separately reported Atlas economy',
  source='https://doi.org/10.7910/DVN/XTAQMC',accessed='2026-10-13'))
write_csv(geography,file.path(data_dir,'asia_geography.csv'))
d <- read_csv(file.path(data_dir,'eci_historical_clean.csv'),show_col_types=FALSE)
australia <- d %>% filter(country_code=='AUS') %>% select(year,australia_rank=global_rank)
pairs <- d %>% inner_join(geography,by='country_code') %>% inner_join(australia,by='year') %>%
  filter(!is.na(global_rank)) %>% group_by(country_code) %>% arrange(year,.by_group=TRUE) %>%
  mutate(difference=global_rank-australia_rank,previous_difference=lag(difference),
    previous_year=lag(year),asian_overtake=year-previous_year==1 & previous_difference>0 & difference<0,
    australia_overtake=year-previous_year==1 & previous_difference<0 & difference>0) %>% ungroup()
crossings <- pairs %>% filter(asian_overtake | australia_overtake) %>%
  transmute(country_code,country,subregion,from_year=previous_year,to_year=year,
    overtaking=ifelse(asian_overtake,country_code,'AUS'),global_rank,australia_rank)
write_csv(crossings,file.path(data_dir,'asian_australia_crossovers.csv'))
summary <- pairs %>% group_by(country_code,country,subregion) %>% summarise(
  rank_1995=if(any(year==1995))global_rank[year==1995] else NA_real_,
  rank_2024=if(any(year==2024))global_rank[year==2024] else NA_real_,
  overtaking_intervals=paste(paste0(previous_year[which(asian_overtake)],'-',year[which(asian_overtake)]),collapse='; '),
  overtake_count=sum(asian_overtake,na.rm=TRUE),
  last_overtake=if(any(asian_overtake,na.rm=TRUE))max(year[which(asian_overtake)]) else NA_real_,
  observed_years=n(),.groups='drop') %>%
  mutate(started_behind_ended_ahead=rank_1995>33 & rank_2024<73,
    other_than_china_vietnam=!country_code %in% c('CHN','VNM')) %>% arrange(subregion,rank_2024)
write_csv(summary,file.path(data_dir,'asian_australia_summary.csv'))
cat('Started behind Australia in 1995, ended ahead in 2024 (excluding China/Vietnam):\n')
print(as.data.frame(filter(summary,started_behind_ended_ahead,other_than_china_vietnam)))
cat('\nOther economies with observed overtakes (including reversals):\n')
print(as.data.frame(filter(summary,overtake_count>0,other_than_china_vietnam)))
