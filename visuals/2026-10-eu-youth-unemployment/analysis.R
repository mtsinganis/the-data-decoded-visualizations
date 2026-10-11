# Run from the repository root: Rscript visuals/2026-10-eu-youth-unemployment/analysis.R
# Offline snapshot by default. Set TDD_REFRESH=1 to retrieve a new official vintage.
required <- c('jsonlite','readr','readxl','dplyr','ggplot2','grid','ragg','svglite',
              'systemfonts','rsvg','png','digest','curl','xml2')
missing <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop('Missing packages: ',paste(missing,collapse=', '))
suppressPackageStartupMessages({library(dplyr); library(ggplot2); library(grid)})
project <- 'visuals/2026-10-eu-youth-unemployment'
data_dir <- file.path(project,'data'); plot_dir <- file.path(project,'plots')

# Font subsetting is an export post-process; plotting remains R/ggplot2.
svg_optimizer <- file.path(project,'optimize-svg-fonts.py')
svg_python <- Sys.getenv('TDD_PYTHON',unset=Sys.which('python'))
svg_font_format <- Sys.getenv('TDD_SVG_FONT_FORMAT',unset='woff2')
stopifnot(svg_font_format %in% c('woff2','woff'))
if(!nzchar(svg_python)) stop('Python is required for SVG font subsetting; set TDD_PYTHON. See README.md.')
font_check <- system2(svg_python,c(shQuote(svg_optimizer),'--check'),stdout=TRUE,stderr=TRUE)
if(!is.null(attr(font_check,'status')) && attr(font_check,'status')!=0)
  stop(paste(font_check,collapse='\n'),'\nSet TDD_PYTHON to the interpreter with requirements-svg.txt installed.')
font_audit_dir <- file.path(data_dir,'svg_font_optimization')
dir.create(font_audit_dir,recursive=TRUE,showWarnings=FALSE)

stopifnot(file.exists('R/theme_data_decoded.R'))
dir.create(data_dir,recursive=TRUE,showWarnings=FALSE)
dir.create(plot_dir,recursive=TRUE,showWarnings=FALSE)
geos <- c('BE','BG','CZ','DK','DE','EE','IE','EL','ES','FR','HR','IT','CY',
          'LV','LT','LU','HU','MT','NL','AT','PL','PT','RO','SI','SK','FI','SE','EU27_2020')
filters <- c(freq='M',s_adj='SA',age='Y_LT25',unit='PC_ACT',sex='T')
base_url <- 'https://ec.europa.eu/eurostat/api/dissemination/'
query_url <- paste0(base_url,'statistics/1.0/data/une_rt_m?lang=en&',
  paste(paste(names(filters),filters,sep='='),collapse='&'),
  '&sinceTimePeriod=2000-01&',paste(paste0('geo=',geos),collapse='&'))
sources <- data.frame(file=c('une_rt_m.json','une_rt_m_structure.xml','une_rt_m_esms.html',
                             'une_rt_m_footnotes.xlsx','greek-crosscheck.tsv'),
  url=c(query_url,paste0(base_url,'sdmx/2.1/datastructure/ESTAT/UNE_RT_M?references=children'),
    'https://ec.europa.eu/eurostat/cache/metadata/en/une_rt_m_esms.htm',
    'https://ec.europa.eu/eurostat/cache/metadata/Annexes/une_rt_m_esms_an_footnote.xlsx',
    paste0(base_url,'sdmx/2.1/data/une_rt_m/M.SA.Y_LT25.PC_ACT.T.EL?startPeriod=2000-01&format=TSV')))
manifest_file <- file.path(data_dir,'sources.csv')
refresh <- identical(Sys.getenv('TDD_REFRESH'),'1')
if(refresh || !file.exists(manifest_file)) {
  manifest <- lapply(seq_len(nrow(sources)),function(i) {
    target <- file.path(data_dir,sources$file[i]); temp <- tempfile(tmpdir=data_dir)
    curl::curl_download(sources$url[i],temp,quiet=TRUE,mode='wb')
    stopifnot(file.size(temp)>0,file.copy(temp,target,overwrite=TRUE)); unlink(temp)
    data.frame(file=sources$file[i],url=sources$url[i],
      retrieved_utc=format(Sys.time(),tz='UTC',format='%Y-%m-%dT%H:%M:%SZ'),
      retrieved_date_berlin=format(Sys.time(),tz='Europe/Berlin',format='%Y-%m-%d'),
      sha256=digest::digest(file=target,algo='sha256'))
  })
  readr::write_csv(bind_rows(manifest),manifest_file)
}
manifest <- readr::read_csv(manifest_file,col_types=readr::cols(.default=readr::col_character()),show_col_types=FALSE)
stopifnot(identical(manifest$file,sources$file),identical(manifest$url,sources$url),
  all(vapply(seq_len(nrow(manifest)),function(i)
    identical(digest::digest(file=file.path(data_dir,manifest$file[i]),algo='sha256'),
              manifest$sha256[i]),logical(1))))

# Verify selection against both JSON-stat metadata and the official SDMX DSD/codelists.
j <- jsonlite::fromJSON(file.path(data_dir,'une_rt_m.json'),simplifyVector=FALSE)
stopifnot(identical(j$extension$id,'UNE_RT_M'),setequal(j$id,c(names(filters),'geo','time')))
for(d in names(filters)) stopifnot(identical(names(j$dimension[[d]]$category$index),unname(filters[d])))
stopifnot(setequal(names(j$dimension$geo$category$index),geos))
dsd <- xml2::read_xml(file.path(data_dir,'une_rt_m_structure.xml'))

code_name <- function(list_id,code) {
  node <- xml2::xml_find_first(dsd,paste0('.//s:Codelist[@id="',list_id,'"]/s:Code[@id="',code,'"]/c:Name[@xml:lang="en"]'))
  # Prefer English labels; the first label is a fallback for a code without English text.
  if(inherits(node,'xml_missing')) node <- xml2::xml_find_first(dsd,
    paste0('.//s:Codelist[@id="',list_id,'"]/s:Code[@id="',code,'"]/c:Name[1]'))
  stopifnot(!inherits(node,'xml_missing')); xml2::xml_text(node)
}
dimensions <- bind_rows(lapply(names(filters),function(d) {
  list_id <- xml2::xml_attr(xml2::xml_find_first(dsd,paste0('.//s:Dimension[@id="',d,'"]/s:LocalRepresentation/s:Enumeration/Ref')),'id')
  stopifnot(!is.na(list_id))
  data.frame(dimension=d,code=filters[[d]],dsd_codelist=list_id,
             dsd_label=code_name(list_id,filters[[d]]),json_label=j$dimension[[d]]$category$label[[filters[[d]]]])
}))
readr::write_csv(dimensions,file.path(data_dir,'dimension_validation.csv'))
geo_labels <- vapply(geos,function(g) j$dimension$geo$category$label[[g]],character(1))
stopifnot(geo_labels['EL']=='Greece')
geo_validation <- data.frame(geo=geos,name=geo_labels,
  dsd_name=vapply(geos,function(g)code_name('GEO',g),character(1)))
readr::write_csv(geo_validation,file.path(data_dir,'geography_validation.csv'))
flag_nodes <- xml2::xml_find_all(dsd,'.//s:Codelist[@id="OBS_FLAG"]/s:Code')
flag_dictionary <- data.frame(flag=xml2::xml_attr(flag_nodes,'id'),
  meaning=vapply(flag_nodes,function(n)xml2::xml_text(xml2::xml_find_first(n,'./c:Name[1]')),character(1)))
readr::write_csv(flag_dictionary,file.path(data_dir,'flag_dictionary.csv'))

# Decode sparse JSON-stat indices using the declared dimension order and strides.
# Construct every country-month combination; an absent value remains NA.
size <- unlist(j$size)
strides <- vapply(seq_along(size),function(i) if(i==length(size)) 1 else prod(size[(i+1):length(size)]),numeric(1))
stride <- setNames(strides,j$id)
time_index <- unlist(j$dimension$time$category$index)
api_months <- as.Date(paste0(names(time_index),'-01'))
months <- seq(as.Date('2000-01-01'),max(api_months),by='month')
geo_index <- unlist(j$dimension$geo$category$index)
lookup_value <- function(k) {
  x <- j$value[[as.character(k)]]
  if(is.null(x)) NA_real_ else as.numeric(x)
}
lookup_flag <- function(k) {
  x <- j$status[[as.character(k)]]
  if(is.null(x)) '' else as.character(x)
}
tidy <- bind_rows(lapply(geos,function(g) {
  t <- unname(time_index[format(months,'%Y-%m')])
  k <- unname(geo_index[g])*stride['geo']+t*stride['time']
  tibble(geo=g,country=unname(geo_labels[g]),month=months,
         rate=vapply(k,lookup_value,numeric(1)),flag=vapply(k,lookup_flag,character(1)),
         json_stat_index=as.integer(k))
}))
latest <- max(tidy$month[!is.na(tidy$rate)])
api_time_end <- max(api_months)
tidy <- tidy %>% filter(month<=latest) %>% mutate(
  freq='M',age='Y_LT25',sex='T',unit='PC_ACT',s_adj='SA',
  retrieved_date=manifest$retrieved_date_berlin[1])
stopifnot(n_distinct(tidy$geo)==28,!anyDuplicated(tidy[c('geo','month')]),
          all(tidy$rate[!is.na(tidy$rate)]>=0 & tidy$rate[!is.na(tidy$rate)]<=100))
readr::write_csv(tidy,file.path(data_dir,'youth_unemployment_monthly.csv'),na='NA')
coverage <- tidy %>% group_by(geo,country) %>% summarise(
  first_month=min(month[!is.na(rate)]),latest_month=max(month[!is.na(rate)]),
  final_rate=tail(rate[!is.na(rate)],1),expected_months=n(),observed_months=sum(!is.na(rate)),
  missing_months=sum(is.na(rate)),
  leading_missing=sum(is.na(rate) & month<min(month[!is.na(rate)])),
  internal_missing=sum(is.na(rate) & month>=min(month[!is.na(rate)]) & month<=max(month[!is.na(rate)])),
  trailing_missing=sum(is.na(rate) & month>max(month[!is.na(rate)])),
  flags=paste(sort(unique(flag[nzchar(flag)])),collapse=';'),.groups='drop')
readr::write_csv(coverage,file.path(data_dir,'coverage.csv'))
readr::write_csv(filter(tidy,is.na(rate)),file.path(data_dir,'missing_observations.csv'))
flagged <- tidy %>% filter(nzchar(flag))
readr::write_csv(flagged,file.path(data_dir,'flagged_observations.csv'))
readr::write_csv(flagged %>% count(geo,country,flag,name='observations'),file.path(data_dir,'flag_summary.csv'))
readr::write_csv(filter(tidy,grepl('b',flag,fixed=TRUE)),file.path(data_dir,'series_breaks.csv'))
# Keep all source footnotes, including quarterly basis for BE/HR/CY/RO/SI.
footnotes <- readxl::read_excel(file.path(data_dir,'une_rt_m_footnotes.xlsx'),sheet='Footnotes',skip=4,col_types='text')
readr::write_csv(footnotes,file.path(data_dir,'source_footnotes.csv'))
metadata <- xml2::read_html(file.path(data_dir,'une_rt_m_esms.html'))
writeLines(xml2::xml_text(xml2::xml_find_all(metadata,'.//p')),file.path(data_dir,'reference_metadata.txt'),useBytes=TRUE)
summary <- list(dataset='une_rt_m',latest_available_month=format(latest,'%Y-%m'),
  api_time_dimension_end=format(api_time_end,'%Y-%m'),source_updated=j$updated,
  retrieved_utc=manifest$retrieved_utc[1],retrieved_date_berlin=manifest$retrieved_date_berlin[1],
  observations=sum(!is.na(tidy$rate)),missing=sum(is.na(tidy$rate)),geographies=geos)
jsonlite::write_json(summary,file.path(data_dir,'retrieval.json'),auto_unbox=TRUE,pretty=TRUE)

# Independent official delivery/decoder: SDMX TSV, rather than re-reading JSON values.
# Same dataset and vintage, so this checks retrieval/decoding, not an independent survey.
tsv <- readr::read_tsv(file.path(data_dir,'greek-crosscheck.tsv'),
  col_types=readr::cols(.default=readr::col_character()),name_repair='minimal',show_col_types=FALSE)
stopifnot(nrow(tsv)==1,tsv[[1]][1]=='M,SA,Y_LT25,PC_ACT,T,EL')
colnames(tsv) <- trimws(colnames(tsv))
check_months <- unique(c('2000-01','2009-01','2013-07','2021-01',format(max(tidy$month[tidy$geo=='EL' & !is.na(tidy$rate)]),'%Y-%m')))
crosscheck <- bind_rows(lapply(check_months,function(m) {
  cell <- trimws(tsv[[m]][1]); val <- as.numeric(sub(' .*','',cell))
  flag <- trimws(sub('^[0-9.]+','',cell))
  row <- filter(tidy,geo=='EL',format(month,'%Y-%m')==m)
  tibble(month=m,json_rate=row$rate,sdmx_tsv_rate=val,json_flag=row$flag,
    sdmx_tsv_flag=flag,matched=identical(as.numeric(row$rate),val) && identical(row$flag,flag))
}))
stopifnot(all(crosscheck$matched))
readr::write_csv(crosscheck,file.path(data_dir,'greek_crosscheck.csv'))

# Shared TDD theme, bundled exact Lato faces, palette B teal and crimson accents.
source('R/theme_data_decoded.R')
paper <- '#FFFFFF'; ink <- '#172033'; support <- '#666666'
colours <- c(EL='#2455FF',ES='#C83242',DE='#087F79',EU27_2020=ink)
font_dir <- Sys.getenv('TDD_LATO_FONT_DIR','assets/fonts/lato')
font_files <- file.path(font_dir,paste0('Lato-',c('Regular','Bold','Black'),'.ttf'))
stopifnot(all(file.exists(font_files)))
infos <- lapply(font_files,function(p)systemfonts::font_info(path=p))
stopifnot(identical(vapply(infos,function(i)i$style[[1]],character(1)),c('Regular','Bold','Black')))
regular_alias <- 'TDD Lato'; bold_alias <- 'TDD Lato Bold'; title_alias <- 'TDD Lato Black'
systemfonts::register_font(regular_alias,plain=font_files[1],bold=font_files[2])
systemfonts::register_font(bold_alias,plain=font_files[2])
systemfonts::register_font(title_alias,plain=font_files[3],bold=font_files[3])
resolved <- c(systemfonts::match_fonts(regular_alias)$path[1],
  systemfonts::match_fonts(bold_alias)$path[1],systemfonts::match_fonts(title_alias,weight='bold')$path[1])
stopifnot(identical(normalizePath(resolved),normalizePath(font_files)))
readr::write_csv(data.frame(role=c('support','direct labels','title'),weight=c(400,700,900),
  file=font_files,resolved=resolved),file.path(data_dir,'font_validation.csv'))

# Explicit segment groups prevent lines crossing missing monthly observations.
plot_data <- tidy %>% arrange(geo,month) %>% group_by(geo) %>%
  mutate(segment=cumsum(is.na(rate)),line_group=paste(geo,segment,sep='_')) %>% ungroup()
ymax <- ceiling(max(tidy$rate,na.rm=TRUE)/10)*10
x_start <- as.Date('2000-01-01'); x_display_end <- latest+1900
breaks <- c(x_start,as.Date(paste0(seq(2005,as.integer(format(latest,'%Y')),5),'-01-01')),latest)
breaks <- sort(unique(breaks[breaks<=latest]))
if(length(breaks)>2 && as.numeric(latest-breaks[length(breaks)-1])<800) breaks <- breaks[-(length(breaks)-1)]
date_labels <- vapply(breaks,function(d) if(d==x_start) 'Jan\n2000' else if(d==latest)
  paste(format(d,'%b'),format(d,'%Y'),sep='\n') else format(d,'%Y'),character(1))

# All variants share the approved dimensions, header slots, axes and footer.
logo_source <- paste(readLines('assets/brand/pterosaur-simplified.svg',warn=FALSE),collapse='\n')
viewbox <- regmatches(logo_source,regexec('viewBox="[0-9.]+ [0-9.]+ ([0-9.]+) ([0-9.]+)"',logo_source))[[1]]
logo_ratio <- as.numeric(viewbox[2])/as.numeric(viewbox[3])
logo_raster <- png::readPNG(rsvg::rsvg_png(charToRaw(logo_source),width=488,height=round(488/logo_ratio)),native=TRUE)
width <- 12; height <- 9; dpi <- 300
left <- .43; content <- width-2*left
subtitle <- paste0('Monthly, seasonally-adjusted youth unemployment rate, ages 15\u201324 (%) \u00b7 Jan 2000\u2013',
  format(latest,'%b %Y'))
source_text <- 'Eurostat (une_rt_m)'
notes_text <- paste0('Rates show the share of 15\u201324-year-olds who are unemployed among those working or actively seeking and available for work\u2014not among all young people. ',
  'Monthly figures are adjusted to account for regular seasonal patterns. Open circles denote series breaks.')
wrap_lines <- function(text,width,fontsize,family=regular_alias) {
  pushViewport(viewport(gp=gpar(fontfamily=family,fontsize=fontsize))); on.exit(popViewport())
  out <- character(); current <- ''
  for(word in strsplit(text,' +')[[1]]) {
    candidate <- if(nzchar(current))paste(current,word) else word
    if(convertWidth(stringWidth(candidate),'in',valueOnly=TRUE)>width && nzchar(current)) {
      out <- c(out,current); current <- word
    } else current <- candidate
  }
  c(out,current)
}
text_width <- function(text,size,family) convertWidth(
  grobWidth(textGrob(text,gp=gpar(fontfamily=family,fontsize=size))),'in',valueOnly=TRUE)

# One reusable plotting function: NULL preserves the original four highlights;
# a current member's Eurostat code creates the requested country/EU comparison.
plot_youth_unemployment <- function(country=NULL) {
  is_country <- !is.null(country)
  if(is_country) stopifnot(length(country)==1,country %in% setdiff(geos,'EU27_2020'))
  palette <- if(is_country) setNames(c('#2455FF',ink),c(country,'EU27_2020')) else colours
  draw_order <- if(is_country) c(country,'EU27_2020') else c('DE','ES','EU27_2020','EL')
  background <- filter(plot_data,!geo %in% names(palette))
  stopifnot(n_distinct(background$geo)==if(is_country)26 else 24)
  ends <- coverage %>% filter(geo %in% names(palette)) %>%
    mutate(colour=unname(palette[geo]),label_name=if_else(geo=='EU27_2020','EU-27',country)) %>% arrange(final_rate)
  ends$label_y <- ends$final_rate
  for(i in 2:nrow(ends)) ends$label_y[i] <- max(ends$label_y[i],ends$label_y[i-1]+5.5)
  ends$label_y <- ends$label_y-mean(ends$label_y-ends$final_rate)
  if(min(ends$label_y)<2.8) ends$label_y <- ends$label_y+(2.8-min(ends$label_y))
  ends <- mutate(ends,label_x=latest+310,
    label=paste0(label_name,'  ',sprintf('%.1f',final_rate),'%'),endpoint_date=format(latest_month,'%b %Y'))
  p <- ggplot() +
    geom_segment(data=data.frame(y=seq(0,ymax,10)),aes(x=x_start,xend=latest,y=y,yend=y),
      colour='#E6E8EB',linewidth=.35) +
    geom_line(data=background,aes(month,rate,group=line_group),colour='#A6B0BD',alpha=.62,linewidth=.32,na.rm=TRUE)
  for(g in draw_order) p <- p +
    geom_line(data=filter(plot_data,geo==g),aes(month,rate,group=line_group),colour=palette[g],
      linewidth=if(g=='EU27_2020')1.00 else if(is_country || g=='EL')1.18 else .80,
      linetype=if(g=='EU27_2020') '42' else 'solid',na.rm=TRUE)
  p <- p + scale_colour_manual(values=palette,guide='none') +
    scale_x_date(breaks=breaks,labels=date_labels,expand=c(0,0)) +
    scale_y_continuous(breaks=seq(0,ymax,10),labels=function(x)paste0(x,'%'),expand=c(0,0)) +
    coord_cartesian(xlim=c(x_start,x_display_end),ylim=c(0,ymax),clip='on',expand=FALSE) +
    theme_data_decoded() + theme(
      text=element_text(family=regular_alias,colour=support,size=14),
      panel.background=element_rect(fill=paper,colour=NA),plot.background=element_rect(fill=paper,colour=NA),
      panel.grid.major.x=element_blank(),panel.grid.minor=element_blank(),panel.grid.major.y=element_blank(),
      axis.title=element_blank(),axis.text=element_text(size=13.5,colour=support),
      axis.text.x=element_text(margin=margin(t=9)),axis.text.x.bottom=element_text(margin=margin(t=12.4)),
      axis.ticks=element_blank(),plot.margin=margin(7,0,-2,0),legend.position='none')
  # Keep the template's axes and right-side allocation. Fit long labels by moving
  # their common anchor within that space; never shrink or abbreviate their text.
  if(is_country) {
    gt <- ggplotGrob(p)
    panel_width <- content-convertWidth(sum(gt$widths),'in',valueOnly=TRUE)
    label_width <- vapply(ends$label,text_width,numeric(1),size=4.8*72.27/25.4,family=bold_alias)
    max_anchor <- as.numeric(x_display_end)-
      (max(label_width)+.04)/panel_width*as.numeric(x_display_end-x_start)
    anchor <- min(as.numeric(latest+310),floor(max_anchor))
    stopifnot(anchor>as.numeric(latest+20))
    ends$label_x <- as.Date(anchor,origin='1970-01-01')
    ends$connector_x <- ends$label_x-min(55,(anchor-as.numeric(latest))/2)
  } else ends$connector_x <- ends$label_x-55
  p <- p +
    geom_point(data=filter(plot_data,geo %in% names(palette),grepl('b',flag,fixed=TRUE)),
      aes(month,rate,colour=geo),shape=21,fill=paper,size=2.2,stroke=.7) +
    geom_point(data=ends,aes(latest_month,final_rate,colour=geo),size=1.9) +
    geom_segment(data=ends,aes(x=latest_month,xend=connector_x,y=final_rate,yend=label_y,colour=geo),linewidth=.45) +
    geom_text(data=ends,aes(label_x,label_y,label=label,colour=geo),hjust=0,family=bold_alias,size=4.8) +
    geom_text(data=ends,aes(label_x,label_y-2.4,label=endpoint_date,colour=geo),hjust=0,family=regular_alias,size=3.7)
  # Independently compare transformed line coordinates and segment IDs to input.
  built <- ggplot_build(p)
  line_audit <- bind_rows(lapply(seq_len(length(draw_order)+1)+1,function(i) {
    supplied <- p$layers[[i]]$data; rendered <- built$data[[i]]
    a <- data.frame(x=as.numeric(supplied$month),y=supplied$rate)
    b <- rendered[c('x','y')]
    a <- a[!is.na(a$y),]; b <- b[!is.na(b$y),]
    a <- a[order(a$x,a$y),]; b <- b[order(b$x,b$y),]
    stopifnot(nrow(a)==nrow(b),isTRUE(all.equal(unname(as.matrix(a)),unname(as.matrix(b)),check.attributes=FALSE)))
    stopifnot(n_distinct(rendered$group)==n_distinct(supplied$line_group))
    data.frame(layer=i,series=if(i==2)'Other EU countries' else draw_order[i-2],
      verified_points=nrow(a),exact_match=TRUE,segment_groups=n_distinct(rendered$group),
      linewidth=unique(rendered$linewidth)[1],linetype=as.character(unique(rendered$linetype)[1]))
  }))
  list(p=p,ends=ends,audit=line_audit,country=country,
    title=if(is_country)paste0('Youth unemployment in ',geo_labels[country],' and the EU') else
      'Youth unemployment in Greece and the EU')
}

# A continuous, metric-spaced title: runs share one baseline and exact Lato face.
# For a wrapped title, use the same fixed font-metric line slots as the template.
draw_title <- function(title,country_name,lines,top,size,step) {
  country_start <- if(is.null(country_name)) Inf else nchar('Youth unemployment in ')+1
  country_end <- if(is.null(country_name)) Inf else country_start+nchar(country_name)-1
  offset <- 0
  for(i in seq_along(lines)) {
    line <- lines[i]; indices <- seq_len(nchar(line))+offset
    masks <- indices>=country_start & indices<=country_end
    runs <- split(seq_along(indices),cumsum(c(TRUE,diff(masks)!=0)))
    for(run in runs) {
      first <- min(run); last <- max(run)
      prefix <- if(first==1)'' else substring(line,1,first-1)
      dx <- if(nzchar(prefix))text_width(prefix,size,title_alias) else 0
      grid.text(substring(line,first,last),x=unit(left+dx,'in'),y=unit(top-(i-1)*step,'in'),
        just=c('left','top'),gp=gpar(fontfamily=title_alias,fontsize=size,col=if(masks[first])'#2455FF' else ink))
    }
    offset <- offset+nchar(line)+1
  }
}
draw_chart <- function(chart) {
  grid.newpage(); grid.rect(gp=gpar(fill=paper,col=NA))
  title_size <- 25; sub_size <- 14.5; top <- height-.35
  title_lines <- wrap_lines(chart$title,content,title_size,title_alias)
  sub_lines <- wrap_lines(subtitle,content,sub_size)
  title_step <- .38; sub_top <- top-length(title_lines)*title_step
  draw_title(chart$title,if(is.null(chart$country))NULL else geo_labels[chart$country],title_lines,top,title_size,title_step)
  for(i in seq_along(sub_lines)) grid.text(sub_lines[i],x=unit(left,'in'),y=unit(sub_top-(i-1)*.24,'in'),
    just=c('left','top'),gp=gpar(fontfamily=regular_alias,fontsize=sub_size,col=support))
  key_y <- sub_top-length(sub_lines)*.24-.15
  grid.lines(x=unit(c(left,left+.38),'in'),y=unit(key_y,'in'),gp=gpar(col='#A6B0BD',lwd=1.0))
  grid.text('Other EU countries',x=unit(left+.49,'in'),y=unit(key_y,'in'),just='left',
    gp=gpar(fontfamily=regular_alias,fontsize=13,col=support))
  plot_top <- key_y-.22; plot_bottom <- 1.865; metadata_top <- 1.645
  meta_size <- 12.3; leading <- .20; field_gap <- .035
  source_lines <- wrap_lines(paste('Source:',source_text),content,meta_size)
  note_lines <- wrap_lines(paste('Notes:',notes_text),content,meta_size)
  print(chart$p,vp=viewport(x=unit(left,'in'),y=unit(plot_bottom,'in'),width=unit(content,'in'),
    height=unit(plot_top-plot_bottom,'in'),just=c('left','bottom')),newpage=FALSE)
  field <- function(label,lines,y) {
    for(i in seq_along(lines)) {
      yy <- y-(i-1)*leading
      if(i==1) {
        offset <- text_width(label,meta_size,bold_alias)+text_width(' ',meta_size,regular_alias)
        grid.text(label,x=unit(left,'in'),y=unit(yy,'in'),just=c('left','top'),
          gp=gpar(fontfamily=bold_alias,fontsize=meta_size,col=support))
        grid.text(substring(lines[i],nchar(label)+2),x=unit(left+offset,'in'),y=unit(yy,'in'),just=c('left','top'),
          gp=gpar(fontfamily=regular_alias,fontsize=meta_size,col=support))
      } else grid.text(lines[i],x=unit(left,'in'),y=unit(yy,'in'),just=c('left','top'),
        gp=gpar(fontfamily=regular_alias,fontsize=meta_size,col=support))
    }
  }
  field('Source:',source_lines,metadata_top)
  field('Notes:',note_lines,metadata_top-length(source_lines)*leading-field_gap)
  grid.lines(x=unit(c(left,width-left),'in'),y=unit(.85,'in'),gp=gpar(col='#DEE1E5',lwd=.7))
  logo_w <- .6
  grid.raster(logo_raster,x=unit(left+logo_w/2,'in'),y=unit(.43,'in'),width=unit(logo_w,'in'),height=unit(logo_w/logo_ratio,'in'))
  grid.text('THE DATA DECODED',x=unit(left+logo_w+.14,'in'),y=unit(.43,'in'),just='left',
    gp=gpar(fontfamily=regular_alias,fontsize=14,col=ink))
  list(header=data.frame(title_top_inches=top,subtitle_top_inches=sub_top,title_lines=length(title_lines),
      subtitle_lines=length(sub_lines),title_fontsize=title_size,subtitle_fontsize=sub_size),
    layout=data.frame(width=width,height=height,dpi=dpi,plot_top=plot_top,plot_bottom=plot_bottom,
      metadata_top=metadata_top,source_lines=length(source_lines),note_lines=length(note_lines)))
}
notices <- paste(readLines(file.path(font_dir,'Lato-OFL.txt'),warn=FALSE),collapse='\n')
notices <- gsub('&','&amp;',notices,fixed=TRUE); notices <- gsub('<','&lt;',notices,fixed=TRUE)
# Keep licence metadata; Python fills this slot with only the used font subsets.
css <- paste0('<metadata>',notices,'</metadata><style type="text/css"><![CDATA[]]></style>')
# Rename replacement avoids Windows pinned-file overwrite failures. Preserve the
# previous export until the fully rendered replacement has been moved into place.
replace_export <- function(temp,target) {
  backup <- tempfile(tmpdir=dirname(target))
  exists <- file.exists(target)
  if(exists) stopifnot(file.rename(target,backup))
  if(!file.rename(temp,target)) {
    if(exists) file.rename(backup,target)
    stop('Could not replace export: ',target)
  }
  if(exists) unlink(backup)
}
# SVG viewers may collapse spaces at separate coloured text-run boundaries.
# Merge the three title runs into one text element with one inline country span.
embed_coloured_title <- function(svg,chart,title_width_points) {
  if(is.null(chart$country)) return(svg)
  nodes <- regmatches(svg,gregexpr('<text\\b[^>]*font-size: 25\\.00px;[^>]*>.*?</text>',svg,perl=TRUE))[[1]]
  stopifnot(length(nodes)==3)
  opening <- sub('>.*$','>',nodes[1])
  opening <- sub("textLength='[^']+'",paste0("textLength='",sprintf('%.2f',title_width_points),"px'"),opening)
  opening <- sub('<text ','<text xml:space="preserve" ',opening,fixed=TRUE)
  merged <- paste0(opening,'Youth unemployment in <tspan style="fill: #2455FF;">',
    geo_labels[chart$country],'</tspan> and the EU</text>')
  svg <- sub(nodes[1],merged,svg,fixed=TRUE)
  for(node in nodes[-1]) svg <- sub(node,'',svg,fixed=TRUE)
  svg
}
export_chart <- function(country=NULL,output_dir=plot_dir) {
  dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
  name <- if(is.null(country))'greece' else tolower(unname(geo_labels[country]))
  slug <- gsub('[^a-z0-9]+','-',name)
  key <- paste0('youth-unemployment-',slug,'-eu')
  png_file <- file.path(output_dir,paste0(key,'.png')); svg_file <- file.path(output_dir,paste0(key,'.svg'))
  png_temp <- tempfile(tmpdir=output_dir,fileext='.png')
  ragg::agg_png(png_temp,width=width,height=height,units='in',res=dpi,background=paper)
  chart <- plot_youth_unemployment(country)
  audit <- draw_chart(chart); invisible(dev.off()); replace_export(png_temp,png_file)
  svg_temp <- tempfile(tmpdir=output_dir,fileext='.svg')
  svglite::svglite(svg_temp,width=width,height=height,bg=paper)
  svg_audit <- draw_chart(chart)
  svg_title_width <- text_width(chart$title,25,title_alias)*72
  invisible(dev.off())
  svg <- paste(readLines(svg_temp,warn=FALSE),collapse='\n')
  svg <- embed_coloured_title(svg,chart,svg_title_width)
  if(!is.null(country)) svg <- gsub('<text\\b(?![^>]*xml:space=)',
    '<text xml:space="preserve"',svg,perl=TRUE)
  svg <- sub('(<svg\\b[^>]*>)',paste0('\\1\n',css),svg,perl=TRUE)
  writeLines(svg,svg_temp,useBytes=TRUE)
  # Only actual characters/weights are embedded. The optimiser verifies every
  # glyph outline, advance and shaped text run and unchanged non-font SVG markup.
  optimized_temp <- tempfile(tmpdir=output_dir,fileext='.svg')
  font_report <- file.path(font_audit_dir,paste0(if(is.null(country))'multi-' else '',key,'.json'))
  optimized <- system2(svg_python,c(shQuote(svg_optimizer),shQuote(svg_temp),shQuote(optimized_temp),
    '--format',svg_font_format,'--report',shQuote(font_report)),stdout=TRUE,stderr=TRUE)
  if((!is.null(attr(optimized,'status')) && attr(optimized,'status')!=0) || !file.exists(optimized_temp))
    stop('SVG font optimisation failed: ',paste(optimized,collapse='\n'))
  unlink(svg_temp); replace_export(optimized_temp,svg_file)
  stopifnot(identical(audit,svg_audit))
  list(chart=chart,header=audit$header,layout=audit$layout,
    export=data.frame(geo=if(is.null(country))'multi' else country,country=name,slug=slug,
      png=png_file,svg=svg_file,width_pixels=width*dpi,height_pixels=height*dpi,dpi=dpi))
}
# The original output remains separate from all 27 single-country variants.
# TDD_COUNTRIES_ONLY=1 preserves its exact approved file bytes during a batch run.
if(!identical(Sys.getenv('TDD_COUNTRIES_ONLY'),'1')) {
  original <- export_chart()
  readr::write_csv(original$chart$ends,file.path(data_dir,'endpoint_labels.csv'))
  readr::write_csv(original$chart$audit,file.path(data_dir,'plotted_values_validation.csv'))
  readr::write_csv(original$header,file.path(data_dir,'header_slots.csv'))
  readr::write_csv(original$layout,file.path(data_dir,'layout_validation.csv'))
}
if(!identical(Sys.getenv('TDD_COUNTRY_EXPORTS'),'0')) {
  countries <- coverage %>% filter(geo!='EU27_2020') %>% arrange(country)
  exports <- endpoints <- audits <- layouts <- list()
  for(g in countries$geo) {
    result <- export_chart(g,file.path(plot_dir,'countries'))
    exports[[g]] <- mutate(result$export,country=unname(geo_labels[g]))
    endpoints[[g]] <- mutate(result$chart$ends,featured_geo=g)
    audits[[g]] <- mutate(result$chart$audit,featured_geo=g)
    layouts[[g]] <- cbind(data.frame(featured_geo=g,country=unname(geo_labels[g])),result$header,result$layout)
    cat('Exported',geo_labels[g],'\n')
  }
  stopifnot(length(exports)==27)
  readr::write_csv(bind_rows(exports),file.path(data_dir,'country_exports.csv'))
  readr::write_csv(bind_rows(endpoints),file.path(data_dir,'country_endpoint_labels.csv'))
  readr::write_csv(bind_rows(audits),file.path(data_dir,'country_plotted_values_validation.csv'))
  readr::write_csv(bind_rows(layouts),file.path(data_dir,'country_layout_validation.csv'))
  jsonlite::write_json(list(x_start=format(x_start,'%Y-%m-%d'),latest=format(latest,'%Y-%m-%d'),
    x_display_end=format(x_display_end,'%Y-%m-%d'),x_ticks=format(breaks,'%Y-%m-%d'),x_tick_labels=date_labels,
    y_limits=c(0,ymax),y_ticks=seq(0,ymax,10),featured_colour='#2455FF',eu_colour=ink,
    featured_linewidth=1.18,eu_linewidth=1,eu_linetype='42',background_countries=26,
    layer_order=c('other EU countries','featured country','EU27_2020'),notes=notes_text,subtitle=subtitle),
    file.path(data_dir,'country_chart_settings.json'),pretty=TRUE,auto_unbox=TRUE)
}
writeLines(capture.output(sessionInfo()),file.path(data_dir,'sessionInfo.txt'))
cat('Latest selected observation:',format(latest,'%B %Y'),'\n')
