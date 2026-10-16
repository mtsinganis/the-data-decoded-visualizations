font_paths <- normalizePath(file.path('assets/fonts/lato',c('Lato-Regular.ttf','Lato-Bold.ttf','Lato-Black.ttf')),winslash='/')
families <- c('TDD ECI Lato','TDD ECI Lato Bold','TDD ECI Lato Black')
for(i in 1:3) systemfonts::register_font(families[i],plain=font_paths[i])
regular <- families[1]; bold <- families[2]; black <- families[3]
ink <- '#242A32'; support <- '#666666'; left <- .35; old_content <- 6.8
footer_extra <- .11
# Previous exported panel spans 377.40 SVG points (72 points per inch).
# Two successive 15% height increases, followed by a 10% contraction.
# Fixed header, axes and footer retain their sizes.
previous_panel_height <- 377.40/72
panel_vertical_scale <- 1.15^2*.90
plot_height_extra <- previous_panel_height*(panel_vertical_scale-1)
previous_canvas_width <- 8.209431056723298
previous_panel_width <- 7.215831417625
panel_horizontal_scale <- 1.15*.90
plot_width_extra <- previous_panel_width*(panel_horizontal_scale-1)
canvas_width <- previous_canvas_width+plot_width_extra
canvas_height <- 8.183990138694458+footer_extra+plot_height_extra
content <- previous_canvas_width-2*left
plot_content <- content+plot_width_extra
plot_scale <- 1.15; right_limit <- 2029.7
chart_specs <- list(
  main=list(file='chart_final',codes=c('CHN','AUS'),title=c(
    "China's industrial rise fueled Australia's resource",
    'boom as its economic complexity ranking fell')),
  comparison=list(file='chart_asian_comparison',codes=c('AUS','PHL','VNM'),title=c(
    'Vietnam and the Philippines also overtook',
    'resource-rich Australia in economic complexity',
    'since 1995')))
title_lines <- chart_specs$main$title
subtitle_lines <- c('Global Economic Complexity Index rankings, 1995\u20132024.',
  'Rank 1 = most complex mix of exported goods.')
logo_svg <- paste(readLines('assets/brand/pterosaur-simplified.svg',warn=FALSE),collapse='\n')
logo_ratio <- 1220/900
logo <- png::readPNG(rsvg::rsvg_png(charToRaw(logo_svg),width=600,height=round(600/logo_ratio)),native=TRUE)
ends <- filter(h,year==2024) %>% left_join(summary %>% select(country_code,net_improvement),by='country_code') %>%
  mutate(stats=sprintf('#%d \u00b7 %s%d',global_rank,ifelse(net_improvement>0,'\u2191','\u2193'),abs(net_improvement)),
    label_rank=case_when(country_code=='PHL'~35,country_code=='VNM'~46.8,TRUE~global_rank))
# Installed ggbump retains x_lag/y_lag in a key-only join, multiplying each
# smooth point by the number of observations. Remove that unused join metadata
# for multirow groups in a local stat copy; keep geom_bump and its sigmoid math.
bump_layer <- function(...) {
  layer <- ggbump::geom_bump(...)
  original <- layer$stat
  layer$stat <- ggproto(NULL,original,compute_group=function(data,scales,smooth=8,direction='x') {
    if(nrow(data)>1) {data$x_lag<-NULL;data$y_lag<-NULL}
    out <- original$compute_group(data,scales,smooth=smooth,direction=direction)
    out$x_lag <- NA_real_; out$y_lag <- NA_real_
    out
  })
  layer
}
annotations <- data.frame(country_code=c('CHN','VNM','AUS','PHL'),x=c(1999,2002.3,2012.5,2009.5),y=c(10.5,98,82,30),
  label=c('Expansion into increasingly\nsophisticated manufacturing',
    'Rapid diversification into\nelectronics and machinery',
    'Exports remain concentrated\nin minerals and energy',
    'Growing specialization in electronics\nand semiconductor exports'))
annotations$font_size <- ifelse(annotations$country_code=='PHL',12,12.5)
annotations$line_height <- ifelse(annotations$country_code=='PHL',1.05,1.15)
readr::write_csv(annotations,file.path(data_dir,'annotation_layout.csv'))
make_plot <- function(selected_codes) {
  selected_h <- filter(h,country_code %in% selected_codes)
  selected_ends <- filter(ends,country_code %in% selected_codes)
  selected_annotations <- filter(annotations,country_code %in% selected_codes)
  # Preserve a two-thirds physical label gap after tightening the x range.
  label_x <- 2024+(2025.35-2024)*(2031-1994.5)/(2034-1994.5)*2/3/plot_scale/panel_horizontal_scale
  background <- filter(d,!country_code %in% selected_codes)
  stopifnot(n_distinct(background$country_code)==145-length(selected_codes),n_distinct(d$country_code)==145,
    'VEN' %in% background$country_code)
  # Factor group order controls draw order within the foreground layer.
  draw_codes <- c('VNM','PHL','CHN','AUS')
  highlighted_lines <- filter(d,country_code %in% selected_codes)
  draw_keys <- unique(highlighted_lines$line_group[order(match(highlighted_lines$country_code,draw_codes),highlighted_lines$line_group)])
  highlighted_lines <- mutate(highlighted_lines,draw_group=factor(line_group,levels=draw_keys),
    line_width=.8)
  p <- ggplot() +
    bump_layer(data=background,aes(year,global_rank,group=line_group),
      smooth=8,colour='#e9e9e9',linewidth=.14,alpha=1) +
    bump_layer(data=highlighted_lines,
      aes(year,global_rank,group=draw_group,colour=country_code,linewidth=line_width),smooth=8) +
    geom_point(data=filter(selected_h,year==2024),aes(year,global_rank,colour=country_code),size=1.35) +
    geom_text(data=selected_ends,aes(x=label_x,y=label_rank-1.6/plot_scale,label=country,colour=country_code),
      family=bold,size=13/ggplot2::.pt,hjust=0) +
    geom_text(data=selected_ends,aes(x=label_x,y=label_rank+4.1/plot_scale,label=stats,colour=country_code),
      family=regular,size=11.5/ggplot2::.pt,hjust=0) +
    geom_text(data=selected_annotations,aes(x,y,label=label,colour=country_code,
      size=font_size/ggplot2::.pt,lineheight=line_height),family=regular,hjust=0) +
    scale_size_identity() +
    scale_linewidth_identity() +
    scale_colour_manual(values=colors,guide='none') +
    scale_x_continuous(breaks=c(1995,2000,2005,2010,2015,2020,2024),expand=c(0,0)) +
    scale_y_reverse(breaks=c(1,20,40,60,80,100,120,140),expand=c(0,0)) +
    coord_cartesian(xlim=c(1994.5,right_limit),ylim=c(147,-1),clip='off') +
    theme_minimal(base_family=regular,base_size=11.5) +
    theme(axis.title=element_blank(),axis.text=element_text(colour=support),
      axis.text.x=element_text(margin=margin(t=7)),axis.text.y=element_text(margin=margin(r=6)),
      panel.grid=element_blank(),panel.grid.major.x=element_line(colour='#dedede',linewidth=.22),
      plot.margin=margin(3,0,0,0),
      plot.background=element_rect(fill='white',colour=NA),panel.background=element_rect(fill='white',colour=NA))
  built <- ggplot_build(p)
  stopifnot(identical(built$data[[3]]$x,filter(selected_h,year==2024)$year),identical(built$data[[3]]$y,-filter(selected_h,year==2024)$global_rank),
    nrow(built$data[[3]])==length(selected_codes),all(built$data[[3]]$size==1.35),
    n_distinct(built$data[[1]]$group)==145-length(selected_codes),n_distinct(built$data[[2]]$group)==length(selected_codes))
  # Reversed scale acts before the bump statistic. Verify each smooth curve stays
  # inside that country's observed rank extrema; endpoints are annual observations.
  for(layer in c(1,2)) {
    stopifnot(all(is.finite(built$data[[layer]]$y)),
      all(built$data[[layer]]$y<=-1),all(built$data[[layer]]$y>=-145))
  }
  for(code in selected_codes) {
    observed <- filter(h,country_code==code)$global_rank
    # Validate each country by its explicit group identity.
    group_keys <- levels(highlighted_lines$draw_group)
    group_ids <- which(startsWith(group_keys,paste0(code,' ')))
    curve <- built$data[[2]]$y[built$data[[2]]$group %in% group_ids]
    stopifnot(length(curve)>0)
    stopifnot(all(curve>=-max(observed)-1e-9),all(curve<=-min(observed)+1e-9))
  }
  p
}
plots <- lapply(chart_specs,function(spec)make_plot(spec$codes))
text_width <- function(s,size,family=regular) convertWidth(grobWidth(textGrob(s,gp=gpar(fontfamily=family,fontsize=size))),'in',valueOnly=TRUE)
wrap <- function(s,size,width=content) {
  out <- character(); current <- ''
  for(w in strsplit(s,' ',fixed=TRUE)[[1]]) {
    candidate <- if(nzchar(current))paste(current,w) else w
    if(nzchar(current) && text_width(candidate,size)>width) {out<-c(out,current);current<-w} else current<-candidate
  }
  c(out,current)
}
# Fixed baseline slots use the exact registered font's glyph bounds. Title gaps
# gap is .055 inches; the last-title/subtitle gap adds .005 inches for SVG's
# rasterized font-bound rounding, independent of wording height.
metric <- function(family,size) {
  g <- systemfonts::glyph_info('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',family=family,size=size,res=720)
  c(top=max(g$y_bearing)/720,bottom=min(g$y_bearing-g$height)/720)
}
tm <- metric(black,22.5); sm <- metric(regular,14.3)
title_step <- tm['top']-tm['bottom']+.055
canvas_height <- canvas_height+(length(title_lines)-2)*title_step
title_baselines <- 7.18-tm['top']-(seq_along(title_lines)-1)*title_step
subtitle_baselines <- tail(title_baselines,1)+tm['bottom']-.060-sm['top']-(0:1)*(sm['top']-sm['bottom']+.055)
# This headline's first line has no descenders. Tighten its fixed slot by the
# font's descent allowance; the final title, subtitle and plot positions stay fixed.
title_baselines[1] <- title_baselines[1]+tm['bottom']
# Retain the enlarged canvas and plot spans from the preceding version.
extra_height <- canvas_height-7.5
title_baselines <- title_baselines+extra_height
subtitle_baselines <- subtitle_baselines+extra_height
readr::write_csv(data.frame(canvas_width,canvas_height,previous_panel_height,plot_height_extra,
  panel_vertical_scale,previous_panel_width,plot_width_extra,panel_horizontal_scale,point_size=1.35,right_limit,
  chart=vapply(chart_specs,function(spec)spec$file,character(1)),
  highlighted_economies=vapply(chart_specs,function(spec)length(spec$codes),integer(1)),
  background_economies=vapply(chart_specs,function(spec)145L-length(spec$codes),integer(1)),total_economies=145),
  file.path(data_dir,'plot_layout.csv'))
readr::write_csv(data.frame(role=c('title','subtitle'),top_inches=c(tm['top'],sm['top']),
  bottom_inches=c(tm['bottom'],sm['bottom']),visible_gap_inches=c(.055,.060)),file.path(data_dir,'header_metrics.csv'))
draw_title_line <- function(line,y) {
  hits <- gregexpr('China|Australia|Philippines|Vietnam',line)[[1]]
  starts <- if(hits[1]<0)integer() else as.integer(hits)
  lengths <- if(length(starts))attr(hits,'match.length') else integer()
  boundaries <- sort(unique(c(1,starts,starts+lengths,nchar(line)+1)))
  for(i in seq_len(length(boundaries)-1)) {
    a <- boundaries[i];b <- boundaries[i+1]-1
    run <- substring(line,a,b)
    prefix <- if(a>1)substring(line,1,a-1) else ''
    # Named vector construction preserves plain country names explicitly.
    col <- setNames(unname(colors[c('VNM','CHN','AUS','PHL')]),c('Vietnam','China','Australia','Philippines'))
    grid.text(run,x=unit(left+if(nzchar(prefix))text_width(prefix,22.5,black) else 0,'in'),
      y=unit(y,'in'),just=c('left','bottom'),gp=gpar(fontfamily=black,fontsize=22.5,
        col=if(run %in% names(col))col[[run]] else ink))
  }
}
draw <- function(p) {
  grid.newpage();grid.rect(gp=gpar(fill='white',col=NA))
  for(i in seq_along(title_lines)) {
    stopifnot(text_width(title_lines[i],22.5,black)<=content)
    # Fixed export correction from measured native/browser ink bounds for this
    # multi-run title: keep the visible title gap equal to the subtitle gap.
    title_y <- title_baselines[i]+if(i==1 && names(dev.cur())=='agg_png').05 else 0
    draw_title_line(title_lines[i],title_y)
  }
  for(i in seq_along(subtitle_lines)) {
    grid.text(subtitle_lines[i],x=unit(left,'in'),y=unit(subtitle_baselines[i],'in'),just=c('left','bottom'),
      gp=gpar(fontfamily=regular,fontsize=14.3,col=support))
  }
  # Both exports use the same font-metric line slots, independent of text height.
  print(p,vp=viewport(x=unit(left,'in'),y=unit(1.13+footer_extra,'in'),width=unit(plot_content,'in'),
    height=unit(min(subtitle_baselines)+sm['bottom']-.15-1.13-footer_extra,'in'),just=c('left','bottom')),newpage=FALSE)
  field <- function(label,text,y) {
    lines <- wrap(paste(label,text),10.2,width=content)
    for(i in seq_along(lines)) {
      yy <- y-(i-1)*.165
      if(i==1) {
        grid.text(label,x=unit(left,'in'),y=unit(yy,'in'),just=c('left','top'),gp=gpar(fontfamily=bold,fontsize=10.2,col=support))
        grid.text(substring(lines[i],nchar(label)+2),x=unit(left+text_width(label,10.2,bold)+text_width(' ',10.2),'in'),
          y=unit(yy,'in'),just=c('left','top'),gp=gpar(fontfamily=regular,fontsize=10.2,col=support))
      } else grid.text(lines[i],x=unit(left,'in'),y=unit(yy,'in'),just=c('left','top'),gp=gpar(fontfamily=regular,fontsize=10.2,col=support))
    }
    y-length(lines)*.165-.025
  }
  # Same lower metadata anchor as the border-encounters frame (.55 inches above
  # the canvas bottom, with its divider at .43). Extra canvas space preserves
  # the chart-to-metadata gap and the existing plot's physical dimensions.
  y <- field('Source:','Harvard Growth Lab, Atlas of Economic Complexity (2026 release, HS92).',.96+footer_extra)
  y <- field('Notes:',"The index reflects the diversity and sophistication of a country's goods exports, not its wealth or overall economic performance. Rankings cover 140\u2013145 economies.",y)
  stopifnot(y>.40)
  grid.lines(x=unit(c(left,previous_canvas_width-left),'in'),y=unit(.43,'in'),gp=gpar(col='#E3E3E3',lwd=.6))
  grid.raster(logo,x=unit(left+.19,'in'),y=unit(.22,'in'),width=unit(.38,'in'),height=unit(.38/logo_ratio,'in'))
  grid.text('THE DATA DECODED',x=unit(left+.48,'in'),y=unit(.22,'in'),just='left',gp=gpar(fontfamily=regular,fontsize=10.2,col=ink))
}
for (variant in names(chart_specs)) {
export_plot <- plots[[variant]]
export_name <- chart_specs[[variant]]$file
title_lines <- chart_specs[[variant]]$title
final_png <- file.path(plot_dir,paste0(export_name,'.png'))
temp_png <- tempfile(fileext='.png')
ragg::agg_png(temp_png,width=canvas_width,height=canvas_height,units='in',res=400,background='white')
draw(export_plot);dev.off()
stopifnot(file.exists(temp_png),file.size(temp_png)>0)
# Use a completed temporary export so a failed render cannot replace the final.
stopifnot(file.copy(temp_png,final_png,overwrite=TRUE),
  identical(digest::digest(file=temp_png,algo='sha256'),digest::digest(file=final_png,algo='sha256')))
unlink(temp_png)
svg_path <- file.path(plot_dir,paste0(export_name,'.svg'))
svglite::svglite(svg_path,width=canvas_width,height=canvas_height,bg='white');draw(export_plot);dev.off()
# Keep text editable and make the export self-contained without requiring installed Lato.
svg <- paste(readLines(svg_path,warn=FALSE),collapse='\n')
css <- vapply(1:3,function(i)paste0("@font-face{font-family:'Lato';font-weight:",c(400,700,900)[i],";src:url(data:font/ttf;base64,",
  gsub('[\r\n]','',jsonlite::base64_enc(readBin(font_paths[i],'raw',n=file.info(font_paths[i])$size))),") format('truetype');}"),character(1))
svg <- sub('<defs>',paste0('<defs><style type="text/css">',paste(css,collapse='\n'),'</style>'),svg,fixed=TRUE)
writeLines(svg,svg_path,useBytes=TRUE)
doc <- xml2::read_xml(svg_path)
image_node <- xml2::xml_find_first(doc,'.//*[local-name()="image"]')
vector_logo <- xml2::read_xml(logo_svg)
for(attr in c('x','y','width','height')) xml2::xml_set_attr(vector_logo,attr,xml2::xml_attr(image_node,attr))
for(node in xml2::xml_find_all(vector_logo,'.//*[local-name()="path"]'))
  xml2::xml_set_attr(node,'style','fill:#2455FF;stroke:none')
xml2::xml_replace(image_node,vector_logo)
xml2::write_xml(doc,svg_path)
}
readr::write_csv(data.frame(role=c('regular','bold','black'),weight=c(400,700,900),file=font_paths),file.path(data_dir,'font_audit.csv'))
stopifnot(abs(dim(png::readPNG(file.path(plot_dir,'chart_final.png')))[1]-canvas_height*400)<1,
  grepl('<text',svg,fixed=TRUE),grepl('data:font/ttf;base64',svg,fixed=TRUE))
message('Rendered two charts with all 145 economies: main highlights China/Australia; comparison highlights Australia/Philippines/Vietnam.')

