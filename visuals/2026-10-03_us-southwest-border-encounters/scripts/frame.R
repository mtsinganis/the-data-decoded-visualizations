support <- "#666666"
paper <- "#FFFFFF"; ink <- "#172033"; blue <- "#2455FF"
crimson <- "#C83242"; amber <- "#D49A44"; teal <- "#087F79"; context <- "#A6B0BD"
# Default for new charts: exact licensed Lato Regular 400 / Bold 700 / Black 900.
font_dir <- Sys.getenv("TDD_LATO_FONT_DIR","brand-exploration/fonts/lato")
font_files <- file.path(font_dir,paste0("Lato-",c("Regular","Bold","Black"),".ttf"))
if(any(!file.exists(font_files))) stop("Required bundled Lato font missing: Regular, Bold and Black must exist in ",font_dir)
infos <- lapply(font_files,function(p) systemfonts::font_info(path=p))
if(!all(vapply(infos,function(i) i$family[[1]]=="Lato",logical(1))) ||
   !identical(vapply(infos,function(i) i$style[[1]],character(1)),c("Regular","Bold","Black"))) stop("Unexpected bundled Lato family or weight")
regular_alias <- "TDD Lato"; bold_alias <- "TDD Lato Bold"; title_alias <- "TDD Lato Black"
systemfonts::register_font(regular_alias,plain=font_files[1],bold=font_files[2])
systemfonts::register_font(bold_alias,plain=font_files[2])
systemfonts::register_font(title_alias,plain=font_files[3],bold=font_files[3])
resolved <- c(systemfonts::match_fonts(regular_alias)$path[1],systemfonts::match_fonts(bold_alias)$path[1],systemfonts::match_fonts(title_alias,weight="bold")$path[1])
if(!identical(normalizePath(resolved),normalizePath(font_files))) stop("Lato resolved to a substitute font")

logo_source <- paste(readLines("brand-exploration/pterosaur-simplified.svg",warn=FALSE),collapse="\n")
viewbox <- regmatches(logo_source,regexec('viewBox="[0-9.]+ [0-9.]+ ([0-9.]+) ([0-9.]+)"',logo_source))[[1]]
logo_ratio <- as.numeric(viewbox[2])/as.numeric(viewbox[3])
logo_raster <- png::readPNG(rsvg::rsvg_png(charToRaw(logo_source),width=488,height=round(488/logo_ratio)),native=TRUE)

# Text measurements and compact paragraphs are local to this trial, not shared templates.
wrap_lines <- function(text,width,fontsize,face="plain",family=regular_alias) {
  pushViewport(viewport(gp=gpar(fontfamily=family,fontsize=fontsize,fontface=face)))
  on.exit(popViewport())
  lines <- character()
  for (paragraph in strsplit(text,"\n",fixed=TRUE)[[1]]) {
    current <- ""
    for (word in strsplit(paragraph," +")[[1]]) {
      candidate <- if(nzchar(current)) paste(current,word) else word
      if(convertWidth(stringWidth(candidate),"in",valueOnly=TRUE)>width && nzchar(current)) {
        lines <- c(lines,current); current <- word
      } else current <- candidate
    }
    lines <- c(lines,current)
  }
  lines
}
scope_note <- "Published USBP southwest totals include Title 42 expulsions (Mar 2020\u2013May 2023) and at-large events where included. Earlier totals may include a different mix of border and interior apprehensions, limiting comparisons over time."
frame <- function(plot,title,subtitle,key,width=10,height=7.5,dpi=160,note=scope_note,title_size=20,subtitle_size=11.5,footer_size=9,source_text="U.S. Customs and Border Protection. Retrieved Oct 2026.") {
  draw <- function() {
    grid.newpage(); grid.rect(gp=gpar(fill=paper,col=NA))
    left <- .32; content <- width-.64; top <- height-.23
    title_lines <- wrap_lines(title,content,title_size,"bold",family=title_alias)
    # Fixed font-metric line slots keep matching headers aligned across charts.
    header_gap <- .06
    header_line <- function(line,y,size,family,colour,face='plain') {
      grob <- textGrob('Ag',gp=gpar(fontfamily=family,fontface=face,fontsize=size,col=colour))
      ink_height <- convertHeight(grobHeight(grob)+grobDescent(grob),'in',valueOnly=TRUE)
      grid.text(line,x=unit(left,'in'),y=unit(y,'in'),just=c('left','top'),
        gp=gpar(fontfamily=family,fontface=face,fontsize=size,col=colour))
      y-ink_height
    }
    header_y <- top
    for(line in title_lines) header_y <- header_line(line,header_y,title_size,title_alias,ink,'bold')-header_gap
    sub_lines <- wrap_lines(subtitle,content,subtitle_size)
    for(line in sub_lines) header_y <- header_line(line,header_y,subtitle_size,regular_alias,support)-header_gap
    plot_top <- header_y-header_gap
    meta_size <- footer_size; meta_leading <- .14*(footer_size/9); field_gap <- .025
    source <- source_text
    source_lines <- wrap_lines(paste("Source:",source),content,meta_size)
    note_lines <- if(nzchar(note)) wrap_lines(paste("Notes:",note),content,meta_size) else character()
    metadata_top <- .55+(length(source_lines)+length(note_lines))*meta_leading+field_gap
    field <- function(label,lines,y) {
      for(i in seq_along(lines)) {
        line_y <- y-(i-1)*meta_leading
        if(i==1) {
          label_grob <- textGrob(label,gp=gpar(fontfamily=regular_alias,fontface="bold",fontsize=meta_size))
          space_grob <- textGrob(" ",gp=gpar(fontfamily=regular_alias,fontsize=meta_size))
          offset <- convertWidth(grobWidth(label_grob)+grobWidth(space_grob),"in",valueOnly=TRUE)
          grid.text(label,x=unit(left,"in"),y=unit(line_y,"in"),just=c("left","top"),
            gp=gpar(fontfamily=regular_alias,fontface="bold",fontsize=meta_size,col=support))
          grid.text(substring(lines[i],nchar(label)+2),x=unit(left+offset,"in"),y=unit(line_y,"in"),
            just=c("left","top"),gp=gpar(fontfamily=regular_alias,fontsize=meta_size,col=support))
        } else grid.text(lines[i],x=unit(left,"in"),y=unit(line_y,"in"),just=c("left","top"),
          gp=gpar(fontfamily=regular_alias,fontsize=meta_size,col=support))
      }
    }
    field("Source:",source_lines,metadata_top)
    if(length(note_lines)) field("Notes:",note_lines,metadata_top-length(source_lines)*meta_leading-field_gap)
    plot_bottom <- metadata_top+.13
    pushViewport(viewport(x=unit(left,"in"),y=unit(plot_bottom,"in"),width=unit(content,"in"),
      height=unit(plot_top-plot_bottom,"in"),just=c("left","bottom")))
    grid.draw(ggplotGrob(plot)); popViewport()
    grid.lines(x=unit(c(left,width-left),"in"),y=unit(.43,"in"),gp=gpar(col="#DEE1E5",lwd=.7))
    logo_w <- .38; logo_h <- logo_w/logo_ratio
    grid.raster(logo_raster,x=unit(left+logo_w/2,"in"),y=unit(.22,"in"),width=unit(logo_w,"in"),height=unit(logo_h,"in"))
    grid.text("THE DATA DECODED",x=unit(left+logo_w+.14,"in"),y=unit(.22,"in"),just="left",
      gp=gpar(fontfamily=regular_alias,fontsize=10,col=ink))
  }
  png_path <- file.path(project,"plots",paste0(key,".png")); svg_path <- file.path(project,"plots",paste0(key,".svg"))
  png_render <- paste0(png_path,".render.png")
  ragg::agg_png(png_render,width=width,height=height,units="in",res=dpi,background=paper); draw(); dev.off()
  if(!file.exists(png_render) || file.size(png_render)<1000) stop("PNG render failed")
  backup <- paste0(png_path,".previous")
  if(file.exists(backup)) stop("Previous PNG backup exists; review before replacing: ",backup)
  if(file.exists(png_path) && !file.rename(png_path,backup)) stop("Cannot preserve previous PNG")
  if(!file.rename(png_render,png_path)) {
    if(file.exists(backup)) file.rename(backup,png_path)
    stop("PNG replacement failed; previous export restored")
  }
  if(file.exists(backup)) unlink(backup)
  svglite::svglite(svg_path,width=width,height=height,bg=paper); draw(); dev.off()
  # Insert after the complete SVG opening tag, leaving the XML declaration intact.
  notices <- paste(readLines(file.path(font_dir,"Lato-OFL.txt"),warn=FALSE),collapse="\n")
  notices <- gsub("&","&amp;",notices,fixed=TRUE); notices <- gsub("<","&lt;",notices,fixed=TRUE)
  css <- paste0('<metadata>',notices,'</metadata><style type="text/css"><![CDATA[',
    paste(vapply(seq_along(font_files),function(i) paste0('@font-face{font-family:"Lato";font-weight:',c(400,700,900)[i],';src:url(data:font/ttf;base64,',base64enc::base64encode(font_files[i],linewidth=0),') format("truetype");}'),character(1)),collapse=""),']]></style>')
  svg <- paste(readLines(svg_path,warn=FALSE,encoding="UTF-8"),collapse="\n")
  if(length(regmatches(svg,gregexpr("<svg[ >]",svg))[[1]])!=1) stop("Expected one SVG root")
  svg <- sub("(<svg\\b[^>]*>)",paste0("\\1\n",css),svg,perl=TRUE)
  writeLines(svg,svg_path,useBytes=TRUE)
}
