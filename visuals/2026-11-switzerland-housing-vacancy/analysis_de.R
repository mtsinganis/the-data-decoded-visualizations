# Run from the repository root. The archived FSO workbook is the sole data input.
required <- c('readxl','readr','ggplot2','grid','ragg','svglite','systemfonts','rsvg','png')
missing <- required[!vapply(required, requireNamespace, logical(1), quietly=TRUE)]
if(length(missing)) stop('Missing packages: ', paste(missing, collapse=', '))
if(.Platform$OS.type=='windows' && Sys.getlocale('LC_CTYPE')=='C') Sys.setlocale('LC_CTYPE','English_United States.utf8')
suppressPackageStartupMessages({library(ggplot2); library(grid)})
project <- 'visuals/2026-11-switzerland-housing-vacancy'
raw <- readxl::read_excel(file.path(project,'data/fso-36841126.xlsx'), col_names=FALSE, col_types='text', .name_repair='minimal')
stopifnot(grepl('Leerwohnungs', raw[[13]][4]), grepl('ziffer', raw[[13]][5]))
years <- suppressWarnings(as.integer(sub('^([0-9]{4}).*', '\\1', raw[[1]])))
rows <- which(!is.na(years) & years >= 1984 & years <= 2026)
dat <- data.frame(year=years[rows], vacancy_rate_pct=as.numeric(raw[[13]][rows]))
stopifnot(identical(dat$year, 1984:2026), !anyNA(dat), all(is.finite(dat$vacancy_rate_pct)),
  all(dat$vacancy_rate_pct > 0 & dat$vacancy_rate_pct < 100),
  round(dat$vacancy_rate_pct[dat$year==1998],2)==1.85,
  dat$vacancy_rate_pct[dat$year==2020]==1.72,
  dat$vacancy_rate_pct[dat$year==2025]==1, dat$vacancy_rate_pct[dat$year==2026]==.93,
  dat$year[which.max(dat$vacancy_rate_pct)]==1998,
  dat$year[which.min(dat$vacancy_rate_pct)]==1989,
  all(diff(dat$vacancy_rate_pct[dat$year>=2020])<0))
change <- (dat$vacancy_rate_pct[dat$year==2026]/dat$vacancy_rate_pct[dat$year==2020]-1)*100
stopifnot(round(abs(change))==46)
# German export reads the archived workbook without rewriting project data.
source('R/theme_data_decoded.R')
font_dir <- 'assets/fonts/lato'
fonts <- file.path(font_dir,paste0('Lato-',c('Regular','Bold','Black'),'.ttf'))
systemfonts::register_font('TDD Regular',plain=fonts[1]); systemfonts::register_font('TDD Bold',plain=fonts[2]); systemfonts::register_font('TDD Black',plain=fonts[3])
series_col <- '#DA291C'; ink <- '#172033'; support <- '#666666'
# Annotation positions derive from the actual annual observations.
peaks <- dat[dat$year %in% c(1998,2020), ]
low <- dat[which.min(dat$vacancy_rate_pct), ]
stopifnot(low$year == 1989, low$vacancy_rate_pct == .43)
p <- ggplot(dat,aes(year,vacancy_rate_pct)) +
  annotate('segment',x=1984,xend=2026,y=seq(.25,2,.25),yend=seq(.25,2,.25),colour='#ECE9E6',linewidth=.35) +
  annotate('segment',x=1984,xend=2026,y=0,yend=0,colour='#939BA5',linewidth=.5) +
  geom_line(colour=series_col,linewidth=1.0,lineend='round') +
  geom_segment(data=peaks,aes(x=year,xend=year,y=vacancy_rate_pct,yend=2.035),colour='#AAA39C',linewidth=.35) +
  geom_text(data=peaks,aes(x=year,y=2.165,label=paste(year,'Höchststand')),family='TDD Bold',size=4.2,colour=support) +
  geom_text(data=peaks,aes(x=year,y=2.095,label=gsub('[.]',',',sprintf('%.2f%%',vacancy_rate_pct))),family='TDD Regular',size=4.0,colour=support) +
  geom_segment(data=low,aes(x=year,xend=year,y=vacancy_rate_pct,yend=.235),colour='#AAA39C',linewidth=.35) +
  geom_text(data=low,aes(x=year,y=.18,label=paste(year,'Tief')),family='TDD Bold',size=4.2,colour=support) +
  geom_text(data=low,aes(x=year,y=.105,label=gsub('[.]',',',sprintf('%.2f%%',vacancy_rate_pct))),family='TDD Regular',size=4.0,colour=support) +
  annotate('segment',x=2026,y=dat$vacancy_rate_pct[dat$year==2026],xend=2026.85,yend=.98,colour=series_col,linewidth=.4) +
  annotate('text',x=2027.05,y=1.085,label='2026',hjust=0,family='TDD Bold',size=4.4,colour=series_col) +
  annotate('text',x=2027.05,y=1.015,label=gsub('[.]',',',sprintf('%.2f%%',dat$vacancy_rate_pct[dat$year==2026])),hjust=0,family='TDD Regular',size=4.2,colour=series_col) +
  geom_point(data=dat[dat$year %in% c(1989,1998,2020,2026),],shape=21,fill=series_col,colour='#FFFFFF',size=3.1,stroke=.53) +
  scale_x_continuous(limits=c(1983.7,2031.5),breaks=seq(1985,2025,5),expand=c(0,0)) +
  scale_y_continuous(limits=c(0,2.24),breaks=seq(0,2,.25),labels=function(x) gsub('[.]',',',sprintf('%.2f%%',x)),expand=c(0,0)) +
  theme_data_decoded() + theme(text=element_text(family='TDD Regular',colour=support), panel.grid=element_blank(),
    axis.title=element_blank(),axis.text=element_text(size=12,colour=support),
    axis.text.x.bottom=element_text(margin=margin(t=14.85)),axis.text.y=element_text(margin=margin(r=10)),
    plot.margin=margin(5,4,0,0),legend.position='none')
logo <- paste(readLines('assets/brand/pterosaur-simplified.svg',warn=FALSE),collapse='\n')
vb <- regmatches(logo,regexec('viewBox="[0-9.]+ [0-9.]+ ([0-9.]+) ([0-9.]+)"',logo))[[1]]
ratio <- as.numeric(vb[2])/as.numeric(vb[3])
logo_img <- png::readPNG(rsvg::rsvg_png(charToRaw(logo),width=488,height=round(488/ratio)),native=TRUE)
wrap <- function(text,width,size,family='TDD Regular') {
  pushViewport(viewport(gp=gpar(fontfamily=family,fontsize=size))); on.exit(popViewport())
  out <- character(); line <- ''
  for(w in strsplit(text,' +')[[1]]) { candidate <- if(nzchar(line)) paste(line,w) else w
    if(nzchar(line) && convertWidth(stringWidth(candidate),'in',valueOnly=TRUE)>width) {out <- c(out,line); line <- w} else line <- candidate }
  c(out,line)
}
draw <- function() {
  width <- 12; height <- 9; left <- .48; content <- width-2*left
  grid.newpage(); grid.rect(gp=gpar(fill='white',col=NA))
  title <- 'Die Schweizer Leerwohnungsziffer hat sich seit 2020 fast halbiert, lag in den 1980er-Jahren aber noch tiefer'
  subtitle <- 'Leerstehende Wohnungen als Anteil am gesamten Wohnungsbestand, 1984\u20132026'
  tl <- wrap(title,content,25,'TDD Black'); sl <- wrap(subtitle,content,15)
  top <- height-.42; title_step <- .41; sub_top <- top-length(tl)*title_step
  for(i in seq_along(tl)) grid.text(tl[i],x=unit(left,'in'),y=unit(top-(i-1)*title_step,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Black',fontsize=25,col=ink))
  for(i in seq_along(sl)) grid.text(sl[i],x=unit(left,'in'),y=unit(sub_top-(i-1)*.25,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Regular',fontsize=15,col=support))
  plot_top <- sub_top-length(sl)*.25-.10
  source_text <- 'Bundesamt für Statistik (BFS), Leerwohnungszählung.'
  note_text <- 'Leerwohnungsziffer jeweils per 1. Juni. Methodische Änderungen schränken die historische Vergleichbarkeit ein.'
  size <- 12.4; leading <- .205; gap <- .04
  source_lines <- wrap(paste('Quelle:',source_text),content,size); note_lines <- wrap(paste('Hinweis:',note_text),content,size)
  meta_top <- 1.06+(length(source_lines)+length(note_lines))*leading+gap
  field <- function(label,lines,y) for(i in seq_along(lines)) {
    yy <- y-(i-1)*leading
    if(i==1) {
      off <- convertWidth(grobWidth(textGrob(label,gp=gpar(fontfamily='TDD Bold',fontsize=size)))+grobWidth(textGrob(' ',gp=gpar(fontfamily='TDD Regular',fontsize=size))),'in',valueOnly=TRUE)
      grid.text(label,x=unit(left,'in'),y=unit(yy,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Bold',fontsize=size,col=support))
      grid.text(substring(lines[i],nchar(label)+2),x=unit(left+off,'in'),y=unit(yy,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Regular',fontsize=size,col=support))
    } else grid.text(lines[i],x=unit(left,'in'),y=unit(yy,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Regular',fontsize=size,col=support))
  }
  field('Quelle:',source_lines,meta_top); field('Hinweis:',note_lines,meta_top-length(source_lines)*leading-gap)
  plot_bottom <- meta_top+.35
  pushViewport(viewport(x=unit(left,'in'),y=unit(plot_bottom,'in'),width=unit(content,'in'),height=unit(plot_top-plot_bottom,'in'),just=c('left','bottom')))
  grid.draw(ggplotGrob(p)); popViewport()
  grid.lines(x=unit(c(left,width-left),'in'),y=unit(.85,'in'),gp=gpar(col='#DEE1E5',lwd=.7))
  logo_w <- .6; grid.raster(logo_img,x=unit(left+logo_w/2,'in'),y=unit(.43,'in'),width=unit(logo_w,'in'),height=unit(logo_w/ratio,'in'))
  grid.text('THE DATA DECODED',x=unit(left+logo_w+.14,'in'),y=unit(.43,'in'),just='left',gp=gpar(fontfamily='TDD Regular',fontsize=14,col=ink))
}
png_temp <- tempfile(fileext='.png')
ragg::agg_png(png_temp,width=12,height=9,units='in',res=300,background='white'); draw(); dev.off()
stopifnot(file.copy(png_temp,file.path(project,'plots/switzerland-housing-vacancy_de.png'),overwrite=TRUE)); unlink(png_temp)
svglite::svglite(file.path(project,'plots/switzerland-housing-vacancy_de.svg'),width=12,height=9,bg='white'); draw(); dev.off()
# Reuse the existing optimizer: embed only glyphs used in this SVG. Set
# TDD_PYTHON to a Python with fonttools[woff] and uharfbuzz installed.
svg_path <- file.path(project,'plots/switzerland-housing-vacancy_de.svg')
svg <- paste(readLines(svg_path,warn=FALSE,encoding='UTF-8'),collapse='\n')
license <- paste(readLines(file.path(font_dir,'Lato-OFL.txt'),warn=FALSE),collapse='\n')
license <- gsub('&','&amp;',license,fixed=TRUE); license <- gsub('<','&lt;',license,fixed=TRUE)
svg <- sub('(<svg\\b[^>]*>)',paste0('\\1\n<metadata>',license,'</metadata><style></style>'),svg,perl=TRUE)
writeLines(svg,svg_path,useBytes=TRUE)
python <- Sys.getenv('TDD_PYTHON',unset='python')
optimizer <- 'visuals/2026-10-eu-youth-unemployment/optimize-svg-fonts.py'
result <- system2(python,c(shQuote(optimizer),shQuote(svg_path),shQuote(svg_path)),stdout=TRUE,stderr=TRUE)
if(!is.null(attr(result,'status')) && attr(result,'status') != 0) stop(paste(result,collapse='\n'))
cat(paste(result,collapse='\n'),'\n')
cat(sprintf('Years: %d; min: %d %.4f%%; max: %d %.4f%%; relative change: %.2f%%; percentage points: %.2f\n',nrow(dat),dat$year[which.min(dat$vacancy_rate_pct)],min(dat$vacancy_rate_pct),dat$year[which.max(dat$vacancy_rate_pct)],max(dat$vacancy_rate_pct),change,dat$vacancy_rate_pct[dat$year==2026]-dat$vacancy_rate_pct[dat$year==2020]))
