# Run from the repository root; read the archived FSO response offline.
required <- c("jsonlite", "readr", "ggplot2", "grid", "ragg", "svglite", "systemfonts", "rsvg", "png", "base64enc")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly=TRUE)]
if(length(missing)) stop("Missing R packages: ", paste(missing, collapse=", "))
suppressPackageStartupMessages({library(ggplot2); library(grid)})
project <- "visuals/2026-10-switzerland-population-growth"
data_dir <- file.path(project,"data")
raw <- jsonlite::fromJSON(file.path(data_dir,"fso-response.json"), simplifyVector=FALSE)
idx <- unlist(raw$dimension$Jahr$category$index)
years <- as.integer(names(idx)[order(idx)])
components <- unlist(raw$dimension[["Demografische Komponente"]]$category$index)
stopifnot(identical(years,1971:2025), identical(names(components)[order(components)],c("1","2","3","8","13","15")), length(raw$value)==330)
values <- matrix(unlist(raw$value),ncol=6,byrow=TRUE)
dat <- data.frame(year=years,births=values[,1],deaths=values[,2],natural_increase=values[,3],net_migration=values[,4],statistical_adjustment=values[,5],population_change=values[,6])
old <- readr::read_csv("visuals/2026-10-switzerland-net-migration/data/annual-net-migration.csv",show_col_types=FALSE)
stopifnot(all(is.finite(values)), !anyDuplicated(years), all(dat$natural_increase==dat$births-dat$deaths), all(dat$population_change==dat$natural_increase+dat$net_migration+dat$statistical_adjustment), all(dat$year==old$year), all(dat$net_migration==old$net_migration), identical(as.numeric(values[55,]),c(78153,71904,6249,70432,-585,76096)))
readr::write_csv(dat,file.path(data_dir,"annual-population-growth.csv"))
source("R/theme_data_decoded.R")
paper <- "#FFFFFF"; ink <- "#172033"; support <- "#666666"; blue <- "#2455FF"
font_dir <- "assets/fonts/lato"
font_files <- file.path(font_dir,paste0("Lato-",c("Regular","Bold","Black"),".ttf"))
italic_file <- file.path(font_dir,"Lato-Italic.ttf")
regular_alias <- "TDD Lato"; bold_alias <- "TDD Lato Bold"; title_alias <- "TDD Lato Black"
systemfonts::register_font(regular_alias,plain=font_files[1],bold=font_files[2],italic=italic_file)
semi_file <- file.path(data_dir,"Lato-SemiBold.ttf"); semi_alias <- "TDD Lato Semibold"
systemfonts::register_font(semi_alias,plain=semi_file)
systemfonts::register_font(bold_alias,plain=font_files[2]); systemfonts::register_font(title_alias,plain=font_files[3],bold=font_files[3])
# Explicit signed bounds: natural increase begins at zero; migration starts at the
# positive natural top only when positive, otherwise extends downward from zero.
bars <- rbind(data.frame(year=dat$year, ymin=pmin(dat$natural_increase,0), ymax=pmax(dat$natural_increase,0), colour="#B4ABA2"),
 data.frame(year=dat$year, ymin=ifelse(dat$net_migration<0,dat$net_migration,pmax(dat$natural_increase,0)), ymax=ifelse(dat$net_migration<0,0,pmax(dat$natural_increase,0)+dat$net_migration), colour=ifelse(dat$net_migration<0,"#B86760",ifelse(dat$year==2023,blue,"#2455FF"))))
# The selected series contains no negative natural increases; fail rather than silently mis-stack.
stopifnot(all(dat$natural_increase>=0),all(bars$ymin<=bars$ymax))
p <- ggplot() +
 geom_hline(yintercept=c(-50,50,100,150),colour="#ECE9E6",linewidth=.3) +
 geom_rect(data=bars,aes(xmin=year-.39,xmax=year+.39,ymin=ymin/1000,ymax=ymax/1000,fill=colour)) + scale_fill_identity() +
 geom_hline(yintercept=0,colour="#777777",linewidth=.65) +
 annotate("text",x=1975,y=-69,label="1975\nNet: \u221257,847",family=bold_alias,size=4,lineheight=.85,colour="#9D514C") +
 annotate("text",x=1976.5,y=45,label="Oil-crisis\nrecession",family=semi_alias,size=4,lineheight=.9,colour="#A7544E") +
 annotate("text",x=2023,y=158,label="2023\nNet: +139,118",family=bold_alias,size=4,lineheight=.85,colour=blue) +
 annotate("text",x=2023,y=-19,label="Some 2022 Ukrainian arrivals\ncounted as permanent residents\nin 2023",family=semi_alias,size=4,lineheight=.9,colour="#315DE1") +
 annotate("text",x=2025,y=91,label="2025\nNatural: +6,249\nNet: +70,432",hjust=0,family=bold_alias,size=4,lineheight=.9,colour=ink) +
 scale_x_continuous(breaks=seq(1975,2025,5),limits=c(1970,2036),expand=c(0,0)) +
 scale_y_continuous(breaks=c(-50,0,50,100,150),labels=c("\u221250","0","50","100","150"),limits=c(-85,177),expand=c(0,0)) +
 theme_data_decoded() + theme(text=element_text(family=regular_alias,colour=support),panel.grid=element_blank(),axis.title=element_blank(),axis.text=element_text(size=11,colour=support),axis.text.x=element_text(margin=margin(t=8)),plot.margin=margin(20,4,6,0),legend.position="none")
# Local adaptation of the recent NYC grid frame. No shared framework is extracted.
logo_source <- paste(readLines("assets/brand/pterosaur-simplified.svg",warn=FALSE),collapse="\n")
viewbox <- regmatches(logo_source,regexec('viewBox="[0-9.]+ [0-9.]+ ([0-9.]+) ([0-9.]+)"',logo_source))[[1]]
logo_ratio <- as.numeric(viewbox[2])/as.numeric(viewbox[3])
logo_raster <- png::readPNG(rsvg::rsvg_png(charToRaw(logo_source),width=488,
  height=round(488/logo_ratio)),native=TRUE)
wrap_lines <- function(text,width,fontsize,family=regular_alias) {
  pushViewport(viewport(gp=gpar(fontfamily=family,fontsize=fontsize)))
  on.exit(popViewport())
  lines <- character()
  for(paragraph in strsplit(text,"\n",fixed=TRUE)[[1]]) {
    current <- ""
    for(word in strsplit(paragraph," +")[[1]]) {
      candidate <- if(nzchar(current)) paste(current,word) else word
      if(convertWidth(stringWidth(candidate),"in",valueOnly=TRUE)>width && nzchar(current)) {
        lines <- c(lines,current); current <- word
      } else current <- candidate
    }
    lines <- c(lines,current)
  }
  lines
}
header_audit <- list()
frame <- function(plot,title,subtitle,key,source,note,width=10,height=8.8,dpi=240) {
  draw <- function() {
    grid.newpage(); grid.rect(gp=gpar(fill=paper,col=NA))
    left <- .4; content <- width-.8; top <- height-.34
    title_lines <- wrap_lines(title,content,22,family=title_alias)
    sub_lines <- wrap_lines(subtitle,content,14.5)
    stopifnot(length(title_lines)>=1,length(sub_lines)>=1)
    # Identical font-metric slots across all three charts. Their title lines all
    # wrap across the full content width; slot origins remain consistent.
    title_step <- .36
    sub_top <- top-length(title_lines)*title_step
    for(i in seq_along(title_lines)) grid.text(title_lines[i],
      x=unit(left,"in"),y=unit(top-(i-1)*title_step,"in"),just=c("left","top"),
      gp=gpar(fontfamily=title_alias,fontsize=22,col=ink))
    for(i in seq_along(sub_lines)) grid.text(sub_lines[i],
      x=unit(left,"in"),y=unit(sub_top-(i-1)*.23,"in"),just=c("left","top"),
      gp=gpar(fontfamily=regular_alias,fontsize=14.5,col=support))
    header_audit[[key]] <<- data.frame(chart=key,title_line=seq_along(title_lines),subtitle_lines=length(sub_lines),
      title_top_inches=top-(seq_along(title_lines)-1)*title_step,subtitle_top_inches=sub_top,
      title_font_size=22,subtitle_font_size=14.5)
    plot_top <- sub_top-length(sub_lines)*.23-.18
    meta_size <- 12.3; meta_leading <- .19; field_gap <- .035
    source_lines <- wrap_lines(paste("Source:",source),content,meta_size)
    note_lines <- wrap_lines(paste("Notes:",note),content,meta_size)
    metadata_top <- 1.01+(length(source_lines)+length(note_lines))*meta_leading+field_gap
    field <- function(label,lines,y) {
      for(i in seq_along(lines)) {
        line_y <- y-(i-1)*meta_leading
        if(i==1) {
          offset <- convertWidth(grobWidth(textGrob(label,gp=gpar(fontfamily=bold_alias,fontsize=meta_size)))+
            grobWidth(textGrob(" ",gp=gpar(fontfamily=regular_alias,fontsize=meta_size))),"in",valueOnly=TRUE)
          grid.text(label,x=unit(left,"in"),y=unit(line_y,"in"),just=c("left","top"),
            gp=gpar(fontfamily=bold_alias,fontsize=meta_size,col=support))
          grid.text(substring(lines[i],nchar(label)+2),x=unit(left+offset,"in"),
            y=unit(line_y,"in"),just=c("left","top"),
            gp=gpar(fontfamily=regular_alias,fontsize=meta_size,col=support))
        } else grid.text(lines[i],x=unit(left,"in"),y=unit(line_y,"in"),just=c("left","top"),
            gp=gpar(fontfamily=regular_alias,fontsize=meta_size,col=support))
      }
    }
    field("Source:",source_lines,metadata_top)
    field("Notes:",note_lines,metadata_top-length(source_lines)*meta_leading-field_gap)
    plot_bottom <- metadata_top+.27
    stopifnot(plot_top-plot_bottom>3)
    pushViewport(viewport(x=unit(left,"in"),y=unit(plot_bottom,"in"),width=unit(content,"in"),
      height=unit(plot_top-plot_bottom,"in"),just=c("left","bottom")))
    grid.draw(ggplotGrob(plot)); popViewport()
    # Physical units keep symbols square and align the first with the header.
    legend_labels <- c("Natural increase", "Net migration (+)", "Net migration (\u2212)")
    legend_colours <- c("#B4ABA2", blue, "#B86760")
    legend_size <- .105; label_gap <- .09; entry_gap <- .32
    legend_y <- plot_top-.50; legend_x <- left
    for(i in seq_along(legend_labels)) {
      grid.rect(x=unit(legend_x,"in"),y=unit(legend_y,"in"),
        width=unit(legend_size,"in"),height=unit(legend_size,"in"),
        just="left",gp=gpar(fill=legend_colours[i],col=NA))
      label_x <- legend_x+legend_size+label_gap
      grid.text(legend_labels[i],x=unit(label_x,"in"),y=unit(legend_y,"in"),
        just="left",gp=gpar(fontfamily=regular_alias,fontsize=4*72.27/25.4,col=support))
      label_width <- convertWidth(grobWidth(textGrob(legend_labels[i],
        gp=gpar(fontfamily=regular_alias,fontsize=4*72.27/25.4))),"in",valueOnly=TRUE)
      legend_x <- label_x+label_width+entry_gap
    }
    stopifnot(legend_x-entry_gap <= left+content)
    grid.text("People, thousands",x=unit(left,"in"),y=unit(plot_top-.10,"in"),
      just=c("left","top"),gp=gpar(fontfamily=regular_alias,fontface="italic",fontsize=12,col=support))
    grid.lines(x=unit(c(left,width-left),"in"),y=unit(.85,"in"),gp=gpar(col="#DEE1E5",lwd=.7))
    logo_w <- .6
    grid.raster(logo_raster,x=unit(left+logo_w/2,"in"),y=unit(.43,"in"),
      width=unit(logo_w,"in"),height=unit(logo_w/logo_ratio,"in"))
    grid.text("THE DATA DECODED",x=unit(left+logo_w+.14,"in"),y=unit(.43,"in"),just="left",
      gp=gpar(fontfamily=regular_alias,fontsize=14,col=ink))
  }
  png_path <- file.path(project,"plots",paste0(key,".png"))
  svg_path <- file.path(project,"plots",paste0(key,".svg"))
  png_temp <- tempfile(fileext=".png")
  ragg::agg_png(png_temp,width=width,height=height,units="in",res=dpi,background=paper)
  draw(); dev.off()
  stopifnot(file.copy(png_temp,png_path,overwrite=TRUE)); unlink(png_temp)
  svglite::svglite(svg_path,width=width,height=height,bg=paper); draw(); dev.off()
  notices <- paste(readLines(file.path(font_dir,"Lato-OFL.txt"),warn=FALSE),collapse="\n")
  notices <- gsub("&","&amp;",notices,fixed=TRUE); notices <- gsub("<","&lt;",notices,fixed=TRUE)
  css <- paste0('<metadata>',notices,'</metadata><style type="text/css"><![CDATA[',
    paste(vapply(seq_along(font_files),function(i) paste0('@font-face{font-family:"Lato";font-weight:',
      c(400,700,900)[i],';src:url(data:font/ttf;base64,',
      base64enc::base64encode(font_files[i],linewidth=0),') format("truetype");}'),character(1)),
      collapse=""),
    paste0('@font-face{font-family:"Lato";font-weight:600;src:url(data:font/ttf;base64,',base64enc::base64encode(semi_file,linewidth=0),') format("truetype");}'),
    paste0('@font-face{font-family:"Lato";font-weight:400;font-style:italic;src:url(data:font/ttf;base64,',
      base64enc::base64encode(italic_file,linewidth=0),') format("truetype");}'),']]></style>')
  svg <- paste(readLines(svg_path,warn=FALSE),collapse="\n")
  svg <- sub("(<svg\\b[^>]*>)",paste0("\\1\n",css),svg,perl=TRUE)
  writeLines(svg,svg_path,useBytes=TRUE)
}
frame(p,"What Drives Switzerland's Population Growth?",
  "Natural increase and net migration, 1971\u20132025", "switzerland-population-growth",
  "Swiss Federal Statistical Office (FSO), Demographic Balance, August 2026.",
  "Natural increase is births minus deaths. Net migration includes changes into permanent-resident status, not just physical arrivals and departures. The transition from ESPOP to STATPOP in 2011 changed the population definition, affecting historical comparability. Statistical adjustments are excluded, so the two components may not sum exactly to the officially reported population change.")


