sources <- data.frame(file=c('harvard_metadata.json','eci_historical_raw.csv',
  'rankings_data_dictionary.csv','eci_mirror_raw.csv'),url=c(
  'https://dataverse.harvard.edu/api/datasets/:persistentId/versions/12.0?persistentId=doi:10.7910/DVN/XTAQMC',
  'https://dataverse.harvard.edu/api/access/datafile/13439575',
  'https://dataverse.harvard.edu/api/access/datafile/13439574',
  'https://nationsinquiry.com/datasets/economic-complexity/all.csv'))
manifest_path <- file.path(data_dir,'sources.csv')
refresh <- identical(Sys.getenv('TDD_REFRESH'),'1')
if(refresh || !file.exists(manifest_path)) {
  manifest <- lapply(seq_len(nrow(sources)),function(i) {
    path <- file.path(data_dir,sources$file[i])
    if(refresh || !file.exists(path)) {
      temp <- tempfile(tmpdir=data_dir)
      tryCatch(curl::curl_download(sources$url[i],temp,quiet=TRUE,mode='wb'),
        error=function(e)stop('Download failed for ',sources$url[i],': ',conditionMessage(e),
          '. Use the documented checksum-verified cache; no fabricated fallback.'))
      stopifnot(file.size(temp)>0,file.copy(temp,path,overwrite=TRUE)); unlink(temp)
    }
    data.frame(file=sources$file[i],url=sources$url[i],vintage='Harvard Dataverse 12.0 / HS92',
      accessed_berlin=format(Sys.time(),tz='Europe/Berlin',format='%Y-%m-%d'),
      sha256=digest::digest(file=path,algo='sha256'))
  })
  readr::write_csv(bind_rows(manifest),manifest_path)
}
manifest <- readr::read_csv(manifest_path,show_col_types=FALSE)
stopifnot(identical(manifest$file,sources$file),identical(manifest$url,sources$url))
for(i in seq_len(nrow(manifest))) stopifnot(identical(
  digest::digest(file=file.path(data_dir,manifest$file[i]),algo='sha256'),manifest$sha256[i]))
metadata <- jsonlite::fromJSON(file.path(data_dir,'harvard_metadata.json'),simplifyVector=FALSE)$data
if(!is.null(metadata[['latestVersion',exact=TRUE]])) metadata <- metadata[['latestVersion',exact=TRUE]]
stopifnot(metadata$versionNumber==12,metadata$versionMinorNumber==0)
raw <- readr::read_csv(file.path(data_dir,'eci_historical_raw.csv'),show_col_types=FALSE)
rank_file <- Filter(function(f)f$dataFile$id==13439575,metadata$files)[[1]]$dataFile
stopifnot(identical(unname(tools::md5sum(file.path(data_dir,'eci_historical_raw.csv'))),rank_file$checksum$value))
mirror_lines <- readLines(file.path(data_dir,'eci_mirror_raw.csv'),warn=FALSE)
header <- grep('^edition,data_year,global_rank,country,country_code,eci_score$',mirror_lines)
stopifnot(length(header)==1)
mirror <- readr::read_csv(file.path(data_dir,'eci_mirror_raw.csv'),skip=header-1,show_col_types=FALSE)
