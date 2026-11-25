# District vacancy map. Run from the repository root using the archived inputs.
if (.Platform$OS.type=='windows') Sys.setlocale('LC_CTYPE','English_United States.utf8')
required <- c('sf','readr','ggplot2','grid','ragg','svglite','systemfonts','rsvg','png')
missing <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop('Missing packages: ',paste(missing,collapse=', '))
suppressPackageStartupMessages({library(sf);library(ggplot2);library(grid)})
p <- 'visuals/2026-11-switzerland-housing-vacancy'; path <- function(...) file.path(p,...)
d <- readr::read_csv(path('data/district-vacancy-rate-2026.csv'),show_col_types=FALSE)
g <- st_read(path('data/swisstopo-districts-2026.gpkg'),'districts',quiet=TRUE)
national <- readr::read_csv(path('data/annual-vacancy-rate.csv'),show_col_types=FALSE)
ch <- national$vacancy_rate_pct[national$year==2026]
stopifnot(length(ch)==1,ch==.93,nrow(d)==144,nrow(g)==144,!anyDuplicated(d$district_id),!anyDuplicated(g$id),setequal(d$district_id,g$id),all(is.finite(d$vacancy_rate_pct)),all(d$status=='A'))
g$rate <- d$vacancy_rate_pct[match(g$id,d$district_id)]
low<-min(g$rate); high<-max(g$rate)
# Six mutually exclusive intervals; a value exactly equal to 0.93% is in the pale reference-adjacent bin.
breaks <- c(-Inf,.30,.60,.93,1.50,2.50,5.00,Inf)
g$category <- cut(g$rate,breaks=breaks,labels=FALSE,right=TRUE)
stopifnot(low==.11,high==7.27,all(!is.na(g$category)))
transform_rate <- function(x) ifelse(x<=ch,.5-.5*sqrt(pmax(0,(ch-x)/(ch-low))),.5+.5*sqrt(pmax(0,(x-ch)/(high-ch))))
g$shade <- transform_rate(g$rate)
stopifnot(all(diff(transform_rate(sort(g$rate)))>=0),transform_rate(ch)==.5)
font_dir <- 'assets/fonts/lato'; fonts <- file.path(font_dir,paste0('Lato-',c('Regular','Bold','Black'),'.ttf'))
systemfonts::register_font('TDD Regular',plain=fonts[1]);systemfonts::register_font('TDD Bold',plain=fonts[2]);systemfonts::register_font('TDD Black',plain=fonts[3])
blue <- '#2455FF'; red <- '#DA291C'; ink <- '#172033'; support <- '#666666'
original_palette <- c('#C75B50','#E9A69B','#F8E9E5','#E7ECF8','#AEBFEA','#567AC8')
palette <- c('#C75B50','#E9A69B','#F4D9D3','#D6E1F4','#AEBFEA','#567AC8','#173995')
outer <- st_sf(geometry=st_union(st_geometry(g)))
# Districts with verified extrema; Geneva is the FSO canton-equivalent area.
labels <- data.frame(name=c('Zürich · 0.11%','Moutier · 7.27%'), caption=c('Lowest vacancy rate','Highest vacancy rate'),
 x=c(2682130,2594857),y=c(1262500,1280000))
anchors <- st_coordinates(st_point_on_surface(g[match(c(112,2604),g$id),]))
labels$ax <- anchors[,1]; labels$ay <- anchors[,2]
map_for <- function(mode) {
 fill <- if(mode=='stepped') scale_fill_manual(values=setNames(palette,1:7),drop=FALSE,guide='none') else scale_fill_gradientn(colours=c(palette[1],'#F7F7F7',palette[6]),limits=c(0,1),guide='none')
 ggplot(g)+geom_sf(aes(fill=if(mode=='stepped') factor(category,levels=1:7) else shade),colour=if(mode=='stepped') '#FFFFFF' else '#AEB4BA',linewidth=if(mode=='stepped') .26 else .13)+fill+
 {if(mode!='stepped') geom_sf(data=outer,fill=NA,colour='#626D76',linewidth=.28,inherit.aes=FALSE)}+
 geom_segment(data=labels,aes(x=x,y=y,xend=ax,yend=ay),inherit.aes=FALSE,colour=if(mode=='stepped') ink else '#606A74',linewidth=if(mode=='stepped') .48 else .25)+
 geom_label(data=labels,aes(x=x,y=y,label=name),inherit.aes=FALSE,family='TDD Bold',size=if(mode=='stepped') 5.08 else 3.4,colour=ink,fill='white',linewidth=0,label.padding=unit(.08,'lines'))+
 geom_label(data=labels,aes(x=x,y=y+7500,label=caption),inherit.aes=FALSE,family='TDD Regular',size=4.1,colour=support,fill='white',linewidth=0,label.padding=unit(.08,'lines'))+
 coord_sf(xlim=as.numeric(st_bbox(g)[c('xmin','xmax')]),ylim=as.numeric(st_bbox(g)[c('ymin','ymax')]),datum=NA,expand=FALSE,clip='off')+theme_void()+theme(plot.margin=margin(0,0,0,0),panel.background=element_rect(fill='white',colour=NA),plot.background=element_rect(fill='white',colour=NA))
}
logo<-paste(readLines('assets/brand/pterosaur-simplified.svg',warn=FALSE),collapse='\n'); vb<-regmatches(logo,regexec('viewBox="[0-9.]+ [0-9.]+ ([0-9.]+) ([0-9.]+)"',logo))[[1]]; ratio<-as.numeric(vb[2])/as.numeric(vb[3]); logo_img<-png::readPNG(rsvg::rsvg_png(charToRaw(logo),width=488,height=round(488/ratio)),native=TRUE)
draw <- function(mode) {
 width<-14.4; height<-12; left<-.6; right<-width-left
 grid.newpage(); grid.rect(gp=gpar(fill='white',col=NA))
 grid.text('Swiss District Vacancy Rates Range from 0.11% to 7.27%',x=unit(left,'in'),y=unit(11.57,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Black',fontsize=32,col=ink))
 grid.text('Vacant dwellings as a share of the housing stock, 1 June 2026',x=unit(left,'in'),y=unit(11.04,'in'),just=c('left','top'),gp=gpar(fontfamily='TDD Regular',fontsize=19,col=support))
 pushViewport(viewport(x=unit(7.2,'in'),y=unit(6.95,'in'),width=unit(14.0,'in'),height=unit(7.0,'in')));grid.draw(ggplotGrob(map_for(mode)));popViewport()
 lx<-.8; rx<-13.6; cy<-2.69
 grid.text(if(mode=='stepped') 'Below Swiss rate · Tighter market' else 'Tighter housing market / At or below Swiss rate',x=unit(lx,'in'),y=unit(3.04,'in'),just='left',gp=gpar(fontfamily='TDD Bold',fontsize=13,col=ink))
 grid.text(if(mode=='stepped') 'Above Swiss rate · More vacancies' else 'More vacant housing / Above Swiss rate',x=unit(rx,'in'),y=unit(3.04,'in'),just='right',gp=gpar(fontfamily='TDD Bold',fontsize=13,col=ink))
 if(mode=='stepped') {
   mid<-(lx+rx)/2; w<-(rx-lx)/7; labs<-c('≤ 0.30%','> 0.30–0.60%','> 0.60–0.93%','> 0.93–1.50%','> 1.50–2.50%','> 2.50–5.00%','> 5.00%')
   for(i in 1:7) { x<-lx+(i-.5)*w; grid.rect(x=unit(x,'in'),y=unit(cy,'in'),width=unit(w-.035,'in'),height=unit(.18,'in'),gp=gpar(fill=palette[i],col=NA)); grid.text(labs[i],x=unit(x,'in'),y=unit(2.52,'in'),just=c('centre','top'),gp=gpar(fontfamily='TDD Regular',fontsize=12.3,col=ink)) }
   reference_x<-lx+3*w
   grid.lines(x=unit(c(reference_x,reference_x),'in'),y=unit(c(2.60,2.16),'in'),gp=gpar(col=support,lwd=.7))
   grid.text('Swiss national rate: 0.93%',x=unit(reference_x,'in'),y=unit(2.13,'in'),just=c('centre','top'),gp=gpar(fontfamily='TDD Bold',fontsize=12,col=ink))
 } else {
   cols<-colorRampPalette(c(original_palette[1],'#F7F7F7',original_palette[6]),space='Lab')(512); grid.raster(as.raster(matrix(cols,nrow=1)),x=unit((lx+rx)/2,'in'),y=unit(cy,'in'),width=unit(rx-lx,'in'),height=unit(.18,'in'),interpolate=TRUE)
   ticks<-c(.11,.30,.60,.93,1.5,2.5,4,7.27); pos<-lx+(rx-lx)*transform_rate(ticks)
   for(i in seq_along(ticks)) {grid.lines(x=unit(c(pos[i],pos[i]),'in'),y=unit(c(2.48,2.43),'in'),gp=gpar(col=ink,lwd=.6));grid.text(sprintf('%.2f%%',ticks[i]),x=unit(pos[i],'in'),y=unit(2.38,'in'),just=c('centre','top'),gp=gpar(fontfamily='TDD Regular',fontsize=11,col=ink))}
   grid.text('Swiss national rate: 0.93%',x=unit((lx+rx)/2,'in'),y=unit(2.13,'in'),just=c('centre','top'),gp=gpar(fontfamily='TDD Bold',fontsize=12,col=ink))
 }
 field<-function(label,value,y) {a<-gpar(fontfamily='TDD Bold',fontsize=14,col=support);b<-gpar(fontfamily='TDD Regular',fontsize=14,col=support);off<-convertWidth(grobWidth(textGrob(label,gp=a))+grobWidth(textGrob(' ',gp=b)),'in',valueOnly=TRUE);grid.text(label,x=unit(left,'in'),y=unit(y,'in'),just=c('left','top'),gp=a);grid.text(value,x=unit(left+off,'in'),y=unit(y,'in'),just=c('left','top'),gp=b)}
 field('Source:','Swiss Federal Statistical Office (FSO), Empty Dwellings Census and Buildings and Dwellings Statistics; swisstopo.',1.73)
 field('Notes:','District-level data where available; nine areas are canton equivalents in FSO geography.',1.43)
 grid.lines(x=unit(c(left,right),'in'),y=unit(1.1,'in'),gp=gpar(col='#DEE1E5',lwd=.7))
 lw<-.75;grid.raster(logo_img,x=unit(left+lw/2,'in'),y=unit(.58,'in'),width=unit(lw,'in'),height=unit(lw/ratio,'in'));grid.text('THE DATA DECODED',x=unit(left+lw+.16,'in'),y=unit(.58,'in'),just='left',gp=gpar(fontfamily='TDD Regular',fontsize=17,col=ink))
}
args <- commandArgs(trailingOnly=TRUE)
modes <- if(length(args)) args else 'stepped'
stopifnot(all(modes %in% c('stepped','continuous')))
for(mode in modes) {
 base<-path(paste0('plots/switzerland-housing-vacancy-districts-2026-',mode))
 ragg::agg_png(paste0(base,'.png'),width=14.4,height=12,units='in',res=300,background='white');draw(mode);dev.off()
 svg_path<-paste0(base,'.svg');svglite::svglite(svg_path,width=14.4,height=12,bg='white');draw(mode);dev.off()
 svg<-paste(readLines(svg_path,warn=FALSE,encoding='UTF-8'),collapse='\n');license<-paste(readLines(file.path(font_dir,'Lato-OFL.txt'),warn=FALSE),collapse='\n');license<-gsub('&','&amp;',license,fixed=TRUE);license<-gsub('<','&lt;',license,fixed=TRUE);svg<-sub('(<svg\\b[^>]*>)',paste0('\\1\n<metadata>',license,'</metadata><style></style>'),svg,perl=TRUE);writeLines(svg,svg_path,useBytes=TRUE)
 python<-Sys.getenv('TDD_PYTHON',unset='python');optimizer<-'visuals/2026-10-eu-youth-unemployment/optimize-svg-fonts.py';result<-system2(python,c(shQuote(optimizer),shQuote(svg_path),shQuote(svg_path)),stdout=TRUE,stderr=TRUE);if(!is.null(attr(result,'status'))&&attr(result,'status')!=0)stop(paste(result,collapse='\n'));cat(paste(result,collapse='\n'),'\n')
}
