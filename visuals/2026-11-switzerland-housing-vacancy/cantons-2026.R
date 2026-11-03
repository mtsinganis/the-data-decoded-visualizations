# 2026 canton ranking. Run from repository root with archived local inputs.
required <- c('readr','ggplot2','grid','ragg','svglite','systemfonts','rsvg','png')
missing <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop('Missing packages: ',paste(missing,collapse=', '))
if(.Platform$OS.type=='windows' && Sys.getlocale('LC_CTYPE')=='C') stopifnot(nzchar(Sys.setlocale('LC_CTYPE','English_United States.utf8')))
suppressPackageStartupMessages({library(ggplot2);library(grid)})
project <- 'visuals/2026-11-switzerland-housing-vacancy'; path <- function(...) file.path(project,...)
raw <- readr::read_csv(path('data/canton-vacancy-rate.csv'),show_col_types=FALSE)
national <- readr::read_csv(path('data/annual-vacancy-rate.csv'),show_col_types=FALSE)
d <- raw[raw$year==2026,c('canton_abbreviation','canton','vacancy_rate_pct')]
ch <- national$vacancy_rate_pct[national$year==2026]
stopifnot(nrow(d)==26,!anyNA(d),!anyDuplicated(d$canton_abbreviation),all(is.finite(d$vacancy_rate_pct)),all(d$vacancy_rate_pct>0),length(ch)==1,ch==.93)
d <- d[order(d$vacancy_rate_pct,d$canton_abbreviation),];row.names(d)<-NULL
stopifnot(d$canton_abbreviation[1]=='ZG',d$vacancy_rate_pct[1]==.20,tail(d$canton_abbreviation,1)=='JU',tail(d$vacancy_rate_pct,1)==3.35,abs(max(d$vacancy_rate_pct)/min(d$vacancy_rate_pct)-16.75)<1e-9)
readr::write_csv(d,path('data/canton-vacancy-rate-2026.csv'))
# Keep labels near the national reference line clear of the red stroke.
d$label_x <- ifelse(d$vacancy_rate_pct>=.70 & d$vacancy_rate_pct<ch,ch+.035,d$vacancy_rate_pct+.055)
display_name <- d$canton
display_name[d$canton_abbreviation=='AI'] <- 'Appenzell I.Rh.'
display_name[d$canton_abbreviation=='AR'] <- 'Appenzell A.Rh.'
d$label <- paste0(display_name,' (',d$canton_abbreviation,')')
d$label <- factor(d$label,levels=rev(d$label))
flag_files <- path('data/canton-flags',paste0(tolower(d$canton_abbreviation),'.svg'))
stopifnot(length(flag_files)==26,all(file.exists(flag_files)),!anyDuplicated(basename(flag_files)))
flag_images <- lapply(flag_files,function(f) png::readPNG(rsvg::rsvg_png(f,width=128,height=128),native=TRUE))
source('R/theme_data_decoded.R')
font_dir <- 'assets/fonts/lato';fonts <- file.path(font_dir,paste0('Lato-',c('Regular','Bold','Black'),'.ttf'))
systemfonts::register_font('TDD Regular',plain=fonts[1]);systemfonts::register_font('TDD Bold',plain=fonts[2]);systemfonts::register_font('TDD Black',plain=fonts[3])
blue <- '#2455FF';red <- '#DA291C';ink <- '#172033';support <- '#666666'
# All values come from the published FSO series. The red line is national,
# not an unweighted mean of the canton rates.
p <- ggplot(d,aes(x=vacancy_rate_pct,y=label)) +
  geom_vline(xintercept=seq(.5,3.5,.5),colour='#E6E8EB',linewidth=.35) +
  geom_col(fill=blue,width=.70) +
  geom_text(aes(x=-.18,label=label),hjust=1,family='TDD Bold',size=5.45,colour=ink) +
  annotate('segment',x=ch,xend=ch,y=.5,yend=26.5,colour=red,linewidth=.90) +
  geom_text(aes(x=label_x,label=sprintf('%.2f%%',vacancy_rate_pct)),hjust=0,
    family='TDD Bold',size=5.0,colour=ink) +
  annotate('text',x=0.23,y=28.6,label='Tighter housing market',hjust=0,family='TDD Bold',size=5.6,colour='#505050') +
  annotate('text',x=3.27,y=28.6,label='More vacant homes',hjust=1,family='TDD Bold',size=5.6,colour='#505050') +
  annotate('segment',x=.19,xend=0,y=28.6,yend=28.6,colour='#505050',linewidth=.4,arrow=arrow(length=unit(.108,'in'),type='closed')) +
  annotate('segment',x=3.31,xend=3.5,y=28.6,yend=28.6,colour='#505050',linewidth=.4,arrow=arrow(length=unit(.108,'in'),type='closed')) +
  annotate('text',x=ch,y=27.55,label='Swiss national rate:',family='TDD Regular',size=4.8,colour=ink) +
  annotate('text',x=ch,y=26.95,label=sprintf('%.2f%%',ch),family='TDD Bold',size=4.8,colour=red) +
  scale_x_continuous(breaks=0:3,labels=function(x) paste0(x,'%'),expand=c(0,0)) +
  scale_y_discrete(expand=expansion(add=c(.5,.5))) +
  coord_cartesian(xlim=c(0,3.8),ylim=c(.5,26.5),clip='off') +
  theme_data_decoded() + theme(text=element_text(family='TDD Regular',colour=support),panel.grid=element_blank(),
    axis.title=element_blank(),axis.text.x=element_text(size=14,colour=support),axis.text.y=element_blank(),
    axis.ticks=element_blank(),plot.margin=margin(0,8,0,235),legend.position='none')
# Locally cached square flags have equal physical dimensions and no stretching.
# They sit in one column just outside the zero-based plotting panel.
for(i in seq_len(nrow(d))) p <- p + annotation_custom(
  rasterGrob(flag_images[[i]],width=unit(.25,'in'),height=unit(.25,'in'),interpolate=TRUE),
  xmin=-.105,xmax=-.105,ymin=as.integer(d$label[i]),ymax=as.integer(d$label[i]))
logo<-paste(readLines('assets/brand/pterosaur-simplified.svg',warn=FALSE),collapse='\n');vb<-regmatches(logo,regexec('viewBox="[0-9.]+ [0-9.]+ ([0-9.]+) ([0-9.]+)"',logo))[[1]];ratio<-as.numeric(vb[2])/as.numeric(vb[3]);logo_img<-png::readPNG(rsvg::rsvg_png(charToRaw(logo),width=488,height=round(488/ratio)),native=TRUE)
draw <- function() {
 width<-15;height<-15;left<-.55;content<-width-2*left;top<-height-.42
 grid.newpage();grid.rect(gp=gpar(fill='white',col=NA))
 grid.text('Housing Vacancy Rates Vary Nearly 17-Fold Across Swiss Cantons',x=unit(left,'in'),y=unit(top,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Black',fontsize=30,col=ink))
 grid.text("Vacant dwellings as a share of each canton’s housing stock, June 2026",x=unit(left,'in'),y=unit(top-.49,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Regular',fontsize=18,col=support))
 # The national line is identified directly above the plotting region.
 plot_bottom<-1.95;plot_top<-top-1.90
 pushViewport(viewport(x=unit(left,'in'),y=unit(plot_bottom,'in'),width=unit(content,'in'),height=unit(plot_top-plot_bottom,'in'),just=c('left','bottom')));grid.draw(ggplotGrob(p));popViewport()
 field <- function(label,value,y) {gp1<-gpar(fontfamily='TDD Bold',fontsize=14,col=support);gp2<-gpar(fontfamily='TDD Regular',fontsize=14,col=support);off<-convertWidth(grobWidth(textGrob(label,gp=gp1))+grobWidth(textGrob(' ',gp=gp2)),'in',valueOnly=TRUE);grid.text(label,x=unit(left,'in'),y=unit(y,'in'),just=c('left','top'),gp=gp1);grid.text(value,x=unit(left+off,'in'),y=unit(y,'in'),just=c('left','top'),gp=gp2)}
 field('Source:','Swiss Federal Statistical Office (FSO), Empty Dwellings Census.',1.51)
 field('Notes:','Vacancy rate measured as of June 1, 2026.',1.24)
 grid.lines(x=unit(c(left,width-left),'in'),y=unit(.95,'in'),gp=gpar(col='#DEE1E5',lwd=.7))
 lw<-.75;grid.raster(logo_img,x=unit(left+lw/2,'in'),y=unit(.46,'in'),width=unit(lw,'in'),height=unit(lw/ratio,'in'))
 grid.text('THE DATA DECODED',x=unit(left+lw+.16,'in'),y=unit(.46,'in'),just='left',gp=gpar(fontfamily='TDD Regular',fontsize=17,col=ink))
}
base<-path('plots/switzerland-housing-vacancy-cantons-2026')
tmp<-tempfile(fileext='.png');ragg::agg_png(tmp,width=15,height=15,units='in',res=300,background='white');draw();dev.off();stopifnot(file.copy(tmp,paste0(base,'.png'),overwrite=TRUE));unlink(tmp)
svg_path<-paste0(base,'.svg');svglite::svglite(svg_path,width=15,height=15,bg='white');draw();dev.off()
svg<-paste(readLines(svg_path,warn=FALSE,encoding='UTF-8'),collapse='\n');license<-paste(readLines(file.path(font_dir,'Lato-OFL.txt'),warn=FALSE),collapse='\n');license<-gsub('&','&amp;',license,fixed=TRUE);license<-gsub('<','&lt;',license,fixed=TRUE);svg<-sub('(<svg\\b[^>]*>)',paste0('\\1\n<metadata>',license,'</metadata><style></style>'),svg,perl=TRUE);writeLines(svg,svg_path,useBytes=TRUE)
python<-Sys.getenv('TDD_PYTHON',unset='python');optimizer<-'visuals/2026-10-eu-youth-unemployment/optimize-svg-fonts.py';result<-system2(python,c(shQuote(optimizer),shQuote(svg_path),shQuote(svg_path)),stdout=TRUE,stderr=TRUE);if(!is.null(attr(result,'status'))&&attr(result,'status')!=0)stop(paste(result,collapse='\n'));cat(paste(result,collapse='\n'),'\n')
