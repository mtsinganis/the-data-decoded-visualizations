# Run from the repository root. Uses only archived project data and local flags.
required <- c('readr','ggplot2','grid','ragg','svglite','systemfonts','rsvg','png')
missing <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop('Missing packages: ',paste(missing,collapse=', '))
if(.Platform$OS.type=='windows' && Sys.getlocale('LC_CTYPE')=='C') stopifnot(nzchar(Sys.setlocale('LC_CTYPE','English_United States.utf8')))
suppressPackageStartupMessages({library(ggplot2);library(grid)})
project <- 'visuals/2026-11-switzerland-housing-vacancy'; path <- function(...) file.path(project,...)
raw <- readr::read_csv(path('data/canton-vacancy-rate.csv'),show_col_types=FALSE)
national <- readr::read_csv(path('data/annual-vacancy-rate.csv'),show_col_types=FALSE)
old <- raw[raw$year==2020,c('canton','canton_abbreviation','vacancy_rate_pct')]
new <- raw[raw$year==2026,c('canton_abbreviation','vacancy_rate_pct')]
stopifnot(nrow(old)==26,nrow(new)==26,!anyDuplicated(old$canton_abbreviation),!anyDuplicated(new$canton_abbreviation),setequal(old$canton_abbreviation,new$canton_abbreviation))
d <- data.frame(canton=old$canton,canton_abbreviation=old$canton_abbreviation,
 rate_2020=old$vacancy_rate_pct,rate_2026=new$vacancy_rate_pct[match(old$canton_abbreviation,new$canton_abbreviation)])
stopifnot(all(is.finite(d$rate_2020)),all(is.finite(d$rate_2026)),all(d$rate_2020>0),all(d$rate_2026>=0))
ch <- national$vacancy_rate_pct[match(c(2020,2026),national$year)]
stopifnot(length(ch)==2,!anyNA(ch),identical(as.numeric(ch),c(1.72,.93)))
d <- rbind(d,data.frame(canton='Switzerland',canton_abbreviation='CH',rate_2020=ch[1],rate_2026=ch[2]))
d$change_pp <- d$rate_2026-d$rate_2020;d$relative_change_pct <- (d$rate_2026/d$rate_2020-1)*100
d <- d[order(round(d$change_pp,10),d$canton_abbreviation),];row.names(d)<-NULL;d$rank<-seq_len(nrow(d))
stopifnot(nrow(d)==27,abs(d$change_pp[d$canton_abbreviation=='CH']+.79)<1e-10,
 all(diff(d$change_pp)>=-1e-10),sum(d$change_pp>0)==1,all(is.finite(d$relative_change_pct)))
# Do not rewrite the shared data when exporting the translation.
flag_files <- path('data/canton-flags',paste0(tolower(d$canton_abbreviation),'.svg'))
stopifnot(all(file.exists(flag_files)),length(unique(basename(flag_files)))==27)
flag_images <- lapply(flag_files,function(f) png::readPNG(rsvg::rsvg_png(f,width=128,height=128),native=TRUE))
source('R/theme_data_decoded.R')
font_dir <- 'assets/fonts/lato';fonts <- file.path(font_dir,paste0('Lato-',c('Regular','Bold','Black'),'.ttf'))
systemfonts::register_font('TDD Regular',plain=fonts[1]);systemfonts::register_font('TDD Bold',plain=fonts[2]);systemfonts::register_font('TDD Black',plain=fonts[3])
blue <- '#2455FF'; red <- '#DA291C'; ink <- '#172033'; support <- '#666666'
d$bar_color <- ifelse(d$canton_abbreviation=='CH',red,blue)
d$label_color <- ifelse(d$canton_abbreviation=='CH',red,ink)
d$label <- gsub('[.]',',',sprintf('%+.2f',d$change_pp))
# Explicit guides stop at the plotting area; labels and flags occupy a reserved
# band underneath, with no fabricated numerical data in the source CSV.
p <- ggplot(d,aes(x=rank)) +
 annotate('segment',x=.45,xend=27.55,y=seq(-1.5,1,.5),yend=seq(-1.5,1,.5),colour='#E6E8EB',linewidth=.35) +
 annotate('segment',x=.45,xend=27.55,y=0,yend=0,colour='#737D87',linewidth=.80) +
 geom_col(aes(y=change_pp,fill=bar_color),width=.70) + scale_fill_identity() +
 geom_text(aes(y=ifelse(change_pp<0,change_pp-.085,change_pp+.085),label=label,colour=label_color),
   family='TDD Regular',size=4.6,vjust=ifelse(d$change_pp<0,1,0)) + scale_colour_identity() +
 geom_text(aes(y=-1.87,label=canton_abbreviation),family='TDD Bold',size=5.5,colour=ink) +
 scale_x_continuous(limits=c(.45,27.55),breaks=NULL,expand=c(0,0)) +
 scale_y_continuous(limits=c(-2.32,1.15),breaks=seq(-1.5,1,.5),labels=function(x) ifelse(x==0,'0',ifelse(x>0,gsub('[.]',',',sprintf('+%.1f',x)),gsub('[.]',',',sprintf('%.1f',x)))),expand=c(0,0)) +
 theme_data_decoded() + theme(text=element_text(family='TDD Regular',colour=support),panel.grid=element_blank(),
  axis.title=element_blank(),axis.text.y=element_text(size=16,colour=support),axis.text.x=element_blank(),
  plot.margin=margin(2,2,0,0),legend.position='none')
# A fixed physical square displays every locally cached flag without distortion.
for(i in seq_len(nrow(d))) p <- p + annotation_custom(rasterGrob(flag_images[[i]],width=unit(.42,'in'),height=unit(.42,'in'),interpolate=TRUE),
 xmin=d$rank[i],xmax=d$rank[i],ymin=-2.015,ymax=-2.015)
logo <- paste(readLines('assets/brand/pterosaur-simplified.svg',warn=FALSE),collapse='\n')
vb<-regmatches(logo,regexec('viewBox="[0-9.]+ [0-9.]+ ([0-9.]+) ([0-9.]+)"',logo))[[1]];ratio<-as.numeric(vb[2])/as.numeric(vb[3]);logo_img<-png::readPNG(rsvg::rsvg_png(charToRaw(logo),width=488,height=round(488/ratio)),native=TRUE)
draw <- function() {
 width<-21.6;height<-14.4;left<-.60;content<-width-2*left;top<-height-.45
 grid.newpage();grid.rect(gp=gpar(fill='white',col=NA))
 grid.text("In 25 der 26 Schweizer Kantone ist die Leerwohnungsziffer seit 2020 gesunken",x=unit(left,'in'),y=unit(top,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Black',fontsize=38,col=ink))
 grid.text('Veränderung der kantonalen Leerwohnungsziffer zwischen 2020 und 2026, in Prozentpunkten',x=unit(left,'in'),y=unit(top-.61,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Regular',fontsize=22,col=support))
 bottom<-1.35;plot_top<-top-.93
 pushViewport(viewport(x=unit(left,'in'),y=unit(bottom,'in'),width=unit(content,'in'),height=unit(plot_top-bottom,'in'),just=c('left','bottom')));grid.draw(ggplotGrob(p));popViewport()
 field <- function(label,value,y) {gp1<-gpar(fontfamily='TDD Bold',fontsize=18,col=support);gp2<-gpar(fontfamily='TDD Regular',fontsize=18,col=support);offset<-convertWidth(grobWidth(textGrob(label,gp=gp1))+grobWidth(textGrob(' ',gp=gp2)),'in',valueOnly=TRUE);grid.text(label,x=unit(left,'in'),y=unit(y,'in'),just=c('left','top'),gp=gp1);grid.text(value,x=unit(left+offset,'in'),y=unit(y,'in'),just=c('left','top'),gp=gp2)}
 field('Quelle:','Bundesamt für Statistik (BFS), Leerwohnungszählung.',1.63)
 field('Hinweis:','Leerwohnungsziffer jeweils per 1. Juni.',1.30)
 grid.lines(x=unit(c(left,width-left),'in'),y=unit(.95,'in'),gp=gpar(col='#DEE1E5',lwd=.7))
 lw<-.9;grid.raster(logo_img,x=unit(left+lw/2,'in'),y=unit(.46,'in'),width=unit(lw,'in'),height=unit(lw/ratio,'in'))
 grid.text('THE DATA DECODED',x=unit(left+lw+.16,'in'),y=unit(.46,'in'),just='left',gp=gpar(fontfamily='TDD Regular',fontsize=20,col=ink))
}
base <- path('plots/switzerland-housing-vacancy-change-2020-2026_de')
tmp<-tempfile(fileext='.png');ragg::agg_png(tmp,width=21.6,height=14.4,units='in',res=300,background='white');draw();dev.off();stopifnot(file.copy(tmp,paste0(base,'.png'),overwrite=TRUE));unlink(tmp)
svg_path<-paste0(base,'.svg');svglite::svglite(svg_path,width=21.6,height=14.4,bg='white');draw();dev.off()
svg<-paste(readLines(svg_path,warn=FALSE,encoding='UTF-8'),collapse='\n');license<-paste(readLines(file.path(font_dir,'Lato-OFL.txt'),warn=FALSE),collapse='\n');license<-gsub('&','&amp;',license,fixed=TRUE);license<-gsub('<','&lt;',license,fixed=TRUE);svg<-sub('(<svg\\b[^>]*>)',paste0('\\1\n<metadata>',license,'</metadata><style></style>'),svg,perl=TRUE);writeLines(svg,svg_path,useBytes=TRUE)
python<-Sys.getenv('TDD_PYTHON',unset='python');optimizer<-'visuals/2026-10-eu-youth-unemployment/optimize-svg-fonts.py';result<-system2(python,c(shQuote(optimizer),shQuote(svg_path),shQuote(svg_path)),stdout=TRUE,stderr=TRUE);if(!is.null(attr(result,'status'))&&attr(result,'status')!=0) stop(paste(result,collapse='\n'));cat(paste(result,collapse='\n'),'\n')
print(d[,c('canton_abbreviation','rate_2020','rate_2026','change_pp','relative_change_pct')],row.names=FALSE)
