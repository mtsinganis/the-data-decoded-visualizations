# Canton exploratory variant. Run from the repository root with the same R and
# SVG optimizer dependencies as analysis.R; all inputs are archived locally.
required <- c('readxl','readr','ggplot2','grid','ragg','svglite','systemfonts','rsvg','png')
missing <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop('Missing packages: ',paste(missing,collapse=', '))
# Ensure SVG text retains accented canton names on Windows hosts started in the C locale.
if(.Platform$OS.type=='windows' && Sys.getlocale('LC_CTYPE')=='C')
  stopifnot(nzchar(Sys.setlocale('LC_CTYPE','English_United States.utf8')))
suppressPackageStartupMessages({library(ggplot2);library(grid)})
project <- 'visuals/2026-11-switzerland-housing-vacancy'
path <- function(...) file.path(project,...)
annual_file <- path('data/fso-cantons-36841127.xlsx')
rolling_file <- path('data/fso-cantons-36841131.xlsx')
# FSO row labels, normalised to ASCII only for matching; English labels for display.
keys <- c('zurich','bern','luzern','uri','schwyz','obwalden','nidwalden','glarus','zug','freiburg','solothurn','baselstadt','basellandschaft','schaffhausen','appenzellarh','appenzellirh','stgallen','graubunden','aargau','thurgau','tessin','waadt','wallis','neuenburg','genf','jura')
abbr <- c('ZH','BE','LU','UR','SZ','OW','NW','GL','ZG','FR','SO','BS','BL','SH','AR','AI','SG','GR','AG','TG','TI','VD','VS','NE','GE','JU')
names_en <- c('Zurich','Bern','Lucerne','Uri','Schwyz','Obwalden','Nidwalden','Glarus','Zug','Fribourg','Solothurn','Basel-Stadt','Basel-Landschaft','Schaffhausen','Appenzell Ausserrhoden','Appenzell Innerrhoden','St. Gallen','Graub\u00fcnden','Aargau','Thurgau','Ticino','Vaud','Valais','Neuch\u00e2tel','Geneva','Jura')
normalize <- function(x) {x <- iconv(x,from='UTF-8',to='ASCII//TRANSLIT'); gsub('[^a-z]','',tolower(x))}
extract <- function(x,col,year) {
  key <- normalize(x[[1]])
  pos <- match(keys,key)
  if(anyNA(pos) || anyDuplicated(key[pos])) stop('Canton match failed for ',year,': ',paste(keys[is.na(pos)],collapse=', '))
  data.frame(year=year,canton=names_en,canton_abbreviation=abbr,
    vacancy_rate_pct=as.numeric(x[[col]][pos]))
}
# Published annual tables cover 1999–2026. Prefer the most recently published
# overlapping five-year table for 2003–2026, which incorporates later revisions.
# The 2010 rolling table uses the new GWS stock basis, as does the national series.
roll_sheets <- readxl::excel_sheets(rolling_file)
annual_sheets <- readxl::excel_sheets(annual_file)
dat <- do.call(rbind,lapply(1999:2026,function(year) {
  matches <- roll_sheets[vapply(strsplit(roll_sheets,'-',fixed=TRUE),function(z) year>=as.integer(z[1]) && year<=as.integer(z[2]),logical(1))]
  if(length(matches)) {
    sheet <- matches[1] # sheets are newest end-year first
    x <- readxl::read_excel(rolling_file,sheet=sheet,col_names=FALSE,col_types='text',.name_repair='minimal')
    header <- if(any(grepl('^[0-9]{4}',unlist(x[3,])) ,na.rm=TRUE)) 3 else 7
    year_cols <- which(grepl(paste0('^',year),as.character(unlist(x[header,]))))
    stopifnot(length(year_cols)>=2); extract(x,tail(year_cols,1),year)
  } else {
    sheet <- annual_sheets[substr(annual_sheets,1,4)==as.character(year)][1]
    x <- readxl::read_excel(annual_file,sheet=sheet,col_names=FALSE,col_types='text',.name_repair='minimal')
    extract(x,ncol(x),year)
  }
}))
stopifnot(nrow(dat)==28*26,!anyNA(dat),all(is.finite(dat$vacancy_rate_pct)),
  !anyDuplicated(dat[c('year','canton_abbreviation')]), all(table(dat$year)==26),all(table(dat$canton_abbreviation)==28),
  dat$vacancy_rate_pct[dat$year==2026 & dat$canton_abbreviation=='ZG']==.20,
  dat$vacancy_rate_pct[dat$year==2026 & dat$canton_abbreviation=='JU']==3.35)
# Independently reconcile every latest canton rate with the FSO annual sheet.
check_sheet <- annual_sheets[substr(annual_sheets,1,4)=='2026'][1]
check_raw <- readxl::read_excel(annual_file,sheet=check_sheet,col_names=FALSE,col_types='text',.name_repair='minimal')
check_2026 <- extract(check_raw,ncol(check_raw),2026)
selected_2026 <- dat[dat$year==2026,]
stopifnot(all(abs(selected_2026$vacancy_rate_pct[match(check_2026$canton_abbreviation,selected_2026$canton_abbreviation)]-check_2026$vacancy_rate_pct)<1e-10))
# Do not rewrite the shared data when exporting the translation.
national <- readr::read_csv(path('data/annual-vacancy-rate.csv'),show_col_types=FALSE)
national <- national[national$year %in% 1999:2026,]
stopifnot(identical(as.integer(national$year),1999:2026), !anyNA(national), national$vacancy_rate_pct[national$year==2026]==.93, as.numeric(check_raw[[ncol(check_raw)]][match('total',normalize(check_raw[[1]]))])==.93)
latest <- dat[dat$year==2026,]; latest <- latest[order(latest$vacancy_rate_pct,latest$canton_abbreviation),]
order_levels <- latest$canton_abbreviation
labels <- setNames(paste(latest$canton_abbreviation,latest$canton,sep='  |  '),latest$canton_abbreviation)
# Conventional abbreviations keep the two long canton names on one line.
labels['GE'] <- 'GE  |  Genf'
labels['LU'] <- 'LU  |  Luzern'
labels['FR'] <- 'FR  |  Freiburg'
labels['VS'] <- 'VS  |  Wallis'
labels['VD'] <- 'VD  |  Waadt'
labels['TI'] <- 'TI  |  Tessin'
labels['NE'] <- 'NE  |  Neuenburg'
labels['ZH'] <- 'ZH  |  Zürich'
labels['AR'] <- 'AR  |  Appenzell A.Rh.'
labels['AI'] <- 'AI  |  Appenzell I.Rh.'
heading_values <- setNames(gsub('[.]',',',sprintf('%.2f%%',latest$vacancy_rate_pct)),latest$canton_abbreviation)
# Add exact crossings of the piecewise-linear lines before constructing the
# ribbon, so its bounds meet when the canton and national series cross.
focal <- dat; focal$facet <- factor(focal$canton_abbreviation,levels=order_levels)
swiss <- do.call(rbind,lapply(order_levels,function(f) {d<-national;d$facet<-f;d}))
swiss$facet <- factor(swiss$facet,levels=order_levels)
gap <- do.call(rbind,lapply(order_levels,function(f) {
  d <- focal[as.character(focal$facet)==f,]; d <- d[order(d$year),]
  d$national <- national$vacancy_rate_pct[match(d$year,national$year)]
  diff <- d$vacancy_rate_pct-d$national
  crossings <- which(diff[-length(diff)]*diff[-1] < 0)
  interpolated <- lapply(crossings,function(i) {
    t <- -diff[i]/(diff[i+1]-diff[i])
    v <- d$national[i]+t*(d$national[i+1]-d$national[i])
    data.frame(year=d$year[i]+t*(d$year[i+1]-d$year[i]),canton_rate=v,national=v)
  })
  g <- data.frame(year=d$year,canton_rate=d$vacancy_rate_pct,national=d$national)
  if(length(interpolated)) g <- rbind(g,do.call(rbind,interpolated))
  g <- g[order(g$year),]; g$facet <- f
  g$lower <- pmin(g$canton_rate,g$national); g$upper <- pmax(g$canton_rate,g$national); g
}))
gap$facet <- factor(gap$facet,levels=order_levels)
stopifnot(nrow(focal)==26*28,nrow(swiss)==26*28,!anyNA(gap),
  all(gap$lower<=gap$upper),max(dat$vacancy_rate_pct,national$vacancy_rate_pct)<=4)
source('R/theme_data_decoded.R')
font_dir <- 'assets/fonts/lato'; fonts <- file.path(font_dir,paste0('Lato-',c('Regular','Bold','Black'),'.ttf'))
semi_font <- 'visuals/2026-10-switzerland-net-migration/data/Lato-SemiBold.ttf'
systemfonts::register_font('TDD Semibold',plain=semi_font)
systemfonts::register_font('TDD Regular',plain=fonts[1]);systemfonts::register_font('TDD Bold',plain=fonts[2]);systemfonts::register_font('TDD Black',plain=fonts[3])
blue <- '#2455FF'; red <- '#DA291C'; support <- '#666666'; ink <- '#172033'; gap_fill <- '#DCDCDC'
p <- ggplot() +
  geom_hline(yintercept=seq(1,4,1),colour='#D8D5D1',linewidth=.32) +
  geom_hline(yintercept=0,colour='#939BA5',linewidth=.52) +
  geom_ribbon(data=gap,aes(x=year,ymin=lower,ymax=upper),fill=gap_fill,colour=NA) +
  geom_line(data=swiss,aes(year,vacancy_rate_pct),colour=red,linewidth=.8928) +
  geom_line(data=focal,aes(year,vacancy_rate_pct),colour=blue,linewidth=1.2672) +
  geom_point(data=swiss[swiss$year==2026,],aes(year,vacancy_rate_pct),colour=red,size=2.6) +
  geom_point(data=focal[focal$year==2026,],aes(year,vacancy_rate_pct),colour=blue,size=2.232) +
  facet_wrap(~facet,ncol=5,scales='fixed',labeller=as_labeller(labels)) +
  scale_x_continuous(limits=c(1999,2027),breaks=c(2000,2010,2020),expand=c(0,0)) +
  scale_y_continuous(limits=c(0,4),breaks=seq(0,4,1),labels=function(x) gsub('[.]',',',sprintf('%.1f%%',x)),expand=c(0,0)) +
  theme_data_decoded() + theme(text=element_text(family='TDD Regular',colour=support),panel.grid=element_blank(),
   axis.title=element_blank(),axis.text=element_text(size=18.4,colour=support),
   axis.text.x.bottom=element_text(margin=margin(t=4)),axis.text.y.left=element_text(margin=margin(r=14)),
   strip.background=element_blank(),strip.text=element_text(family='TDD Bold',size=19,colour=ink,hjust=0,margin=margin(b=14)),
   panel.spacing.x=unit(.27,'in'),panel.spacing.y=unit(.30,'in'),plot.margin=margin(0,2,0,0))
# facet_wrap fills rows from the left. Move the final populated panel, strip,
# and x-axis into the middle column; restore the newly exposed fifth-row axis.
center_last_panel <- function(plot) {
  g <- ggplotGrob(plot)
  idx <- function(name) {i <- which(g$layout$name==name); stopifnot(length(i)==1); i}
  swap <- function(a,b) {i<-idx(a);j<-idx(b);tmp<-g$grobs[[i]];g$grobs[[i]]<<-g$grobs[[j]];g$grobs[[j]]<<-tmp}
  layout <- ggplot_build(plot)$layout$layout
  stopifnot(nrow(layout)==26)
  # Replace each strip with independent, edge-aligned text grobs. Values come
  # from the same 2026 observations used for ordering the facets.
  for(i in seq_len(nrow(layout))) {
    code <- as.character(layout$facet[i])
    name <- paste0('strip-t-',layout$COL[i],'-',layout$ROW[i])
    g$grobs[[idx(name)]] <- grobTree(
      textGrob(labels[[code]],x=unit(0,'npc'),y=unit(.5,'npc'),just='left',
        gp=gpar(fontfamily='TDD Bold',fontsize=19,col=ink,lineheight=.95)),
      textGrob(heading_values[[code]],x=unit(1,'npc'),y=unit(.5,'npc'),just='right',
        gp=gpar(fontfamily='TDD Bold',fontsize=19,col=blue)))
  }
  swap('panel-1-6','panel-3-6')
  swap('strip-t-1-6','strip-t-3-6')
  swap('axis-b-1-6','axis-b-3-6')
  g$grobs[[idx('axis-l-6-1')]] <- zeroGrob()
  g$grobs[[idx('axis-b-1-5')]] <- g$grobs[[idx('axis-b-2-5')]]
  g$grobs[[idx('axis-b-3-5')]] <- zeroGrob()
  g
}
logo <- paste(readLines('assets/brand/pterosaur-simplified.svg',warn=FALSE),collapse='\n')
vb <- regmatches(logo,regexec('viewBox="[0-9.]+ [0-9.]+ ([0-9.]+) ([0-9.]+)"',logo))[[1]]
ratio <- as.numeric(vb[2])/as.numeric(vb[3]); logo_img <- png::readPNG(rsvg::rsvg_png(charToRaw(logo),width=488,height=round(488/ratio)),native=TRUE)
# Frame follows the current national chart's physical-unit header and footer.
draw <- function() {
 width<-21.5; height<-21; left<-.55; content<-width-2*left; top<-height-.45
 grid.newpage();grid.rect(gp=gpar(fill='white',col=NA))
 grid.text('Die Leerwohnungsziffer variiert in der Schweiz stark nach Kanton',x=unit(left,'in'),y=unit(top,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Black',fontsize=48.3,col=ink))
 grid.text("Leerstehende Wohnungen als Anteil am Wohnungsbestand des jeweiligen Kantons, 1999\u20132026.",x=unit(left,'in'),y=unit(top-.78,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Regular',fontsize=27.6,col=support))
 grid.text('Kantone nach Leerwohnungsziffer 2026 geordnet, von tief nach hoch.',x=unit(left,'in'),y=unit(top-1.20,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Regular',fontsize=27.6,col=support))
 # Four distinct legend keys: series lines and the 2026 heading markers.
 key_y<-top-1.98; key_x<-left; key_size<-20.7
 key_gp<-gpar(fontfamily='TDD Regular',fontsize=key_size,col=support)
 value_gp<-gpar(fontfamily='TDD Semibold',fontsize=key_size,col=red)
 key_labels<-c('Kanton','2026 Kantonswert','Schweizer Durchschnitt','2026 Schweizer Wert:')
 key_value<-gsub('[.]',',',sprintf('%.2f%%',national$vacancy_rate_pct[national$year==2026]))
 text_width<-function(txt,gp) convertWidth(grobWidth(textGrob(txt,gp=gp)),'in',valueOnly=TRUE)
 for(i in seq_along(key_labels)) {
   col<-if(i<=2) blue else red
   if(i %% 2 == 1) grid.lines(x=unit(c(key_x,key_x+.34),'in'),y=unit(c(key_y,key_y),'in'),
     gp=gpar(col=col,lwd=if(i==1) 1.2672*72.27/25.4 else .8928*72.27/25.4))
   else grid.circle(x=unit(key_x+.17,'in'),y=unit(key_y,'in'),r=unit(.065,'in'),gp=gpar(fill=col,col=NA))
   text_x<-key_x+.43
   grid.text(key_labels[i],x=unit(text_x,'in'),y=unit(key_y,'in'),just='left',gp=key_gp)
   key_x<-text_x+text_width(key_labels[i],key_gp)
   if(i==4) {
     key_x<-key_x+text_width(' ',key_gp)
     grid.text(key_value,x=unit(key_x,'in'),y=unit(key_y,'in'),just='left',gp=value_gp)
     key_x<-key_x+text_width(key_value,value_gp)
   }
   key_x<-key_x+.42
 }
 stopifnot(key_x-.42<=left+content)
 plot_bottom<-2.40; plot_top<-key_y-.48
 pushViewport(viewport(x=unit(left,'in'),y=unit(plot_bottom,'in'),width=unit(content,'in'),height=unit(plot_top-plot_bottom,'in'),just=c('left','bottom')));grid.draw(center_last_panel(p));popViewport()
 field<-function(label,value,y) {
   gp1<-gpar(fontfamily='TDD Bold',fontsize=20.7,col=support);gp2<-gpar(fontfamily='TDD Regular',fontsize=20.7,col=support)
   offset<-convertWidth(grobWidth(textGrob(label,gp=gp1))+grobWidth(textGrob(' ',gp=gp2)),'in',valueOnly=TRUE)
   grid.text(label,x=unit(left,'in'),y=unit(y,'in'),just=c('left','top'),gp=gp1)
   grid.text(value,x=unit(left+offset,'in'),y=unit(y,'in'),just=c('left','top'),gp=gp2)
 }
 field('Quelle:','Bundesamt für Statistik (BFS), Leerwohnungszählung.',1.85)
 field('Hinweis:','Leerwohnungsziffer jeweils per 1. Juni.',1.48)
 grid.lines(x=unit(c(left,width-left),'in'),y=unit(1.08,'in'),gp=gpar(col='#DEE1E5',lwd=.7))
 lw<-1.0;grid.raster(logo_img,x=unit(left+lw/2,'in'),y=unit(.51,'in'),width=unit(lw,'in'),height=unit(lw/ratio,'in'))
 grid.text('THE DATA DECODED',x=unit(left+lw+.20,'in'),y=unit(.51,'in'),just='left',gp=gpar(fontfamily='TDD Regular',fontsize=25.3,col=ink))
}
base <- path('plots/switzerland-housing-vacancy-cantons_de')
png_temp <- tempfile(fileext='.png')
ragg::agg_png(png_temp,width=21.5,height=21,units='in',res=300,background='white');draw();dev.off()
stopifnot(file.copy(png_temp,paste0(base,'.png'),overwrite=TRUE));unlink(png_temp)
svglite::svglite(paste0(base,'.svg'),width=21.5,height=21,bg='white');draw();dev.off()
svg_path<-paste0(base,'.svg'); svg<-paste(readLines(svg_path,warn=FALSE,encoding='UTF-8'),collapse='\n')
license<-paste(readLines(file.path(font_dir,'Lato-OFL.txt'),warn=FALSE),collapse='\n');license<-gsub('&','&amp;',license,fixed=TRUE);license<-gsub('<','&lt;',license,fixed=TRUE)
svg<-sub('(<svg\\b[^>]*>)',paste0('\\1\n<metadata>',license,'</metadata><style></style>'),svg,perl=TRUE);writeLines(svg,svg_path,useBytes=TRUE)
python<-Sys.getenv('TDD_PYTHON',unset='python');optimizer<-path('optimize-canton-svg.py')
result<-system2(python,c(shQuote(optimizer),shQuote(svg_path),shQuote(svg_path)),stdout=TRUE,stderr=TRUE)
if(!is.null(attr(result,'status'))&&attr(result,'status')!=0) stop(paste(result,collapse='\n'));cat(paste(result,collapse='\n'),'\n')
cat('Canton data:',nrow(dat),'observations; period 1999–2026; range',range(dat$vacancy_rate_pct),'\n')
