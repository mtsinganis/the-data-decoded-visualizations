# Run from the repository root. Preserved sources are used offline by default.
# Override TDD_PYTHON only to an interpreter with pdfplumber installed.
required <- c("readr","readxl","dplyr","ggplot2","scales","grid","ragg",
              "svglite","systemfonts","rsvg","png","base64enc","jsonlite","digest")
missing <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop("Missing R packages: ",paste(missing,collapse=", "))
suppressPackageStartupMessages({
  library(readr); library(readxl); library(dplyr); library(ggplot2)
  library(scales); library(grid)
})
project <- "visuals/2026-10-israel-migration-balance"
data_dir <- file.path(project,"data")
stopifnot(file.exists("R/theme_data_decoded.R"),dir.exists(data_dir))
python <- Sys.getenv("TDD_PYTHON",file.path(Sys.getenv("USERPROFILE"),
  ".cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe"))
if(!file.exists(python)) python <- Sys.which("python")
if(!nzchar(python)) stop("Set TDD_PYTHON to Python with pdfplumber installed")
extract_log <- system2(python,shQuote(file.path(data_dir,"extract_pdf.py")),stdout=TRUE,stderr=TRUE)
if(!is.null(attr(extract_log,"status"))) stop(paste(extract_log,collapse="\n"))
cat(paste(extract_log,collapse="\n"),"\n")
  audit_status <- system2(python,shQuote(file.path(data_dir,"historical_audit.py")))
  stopifnot(audit_status==0)
latest <- read_csv(file.path(data_dir,"latest_period.csv"),show_col_types=FALSE)
stopifnot(nrow(latest)==8,!anyDuplicated(latest$component),
          all(latest$period_months==11.63),all(latest$status=="provisional"))
v <- setNames(latest$people,latest$component)
natural <- unname(v["births"]-v["deaths"])
components <- unname(v[c("new_immigrants","family_reunification","returning_israelis","israeli_emigrants")])
migration <- unname(v["total_migration_balance"])
growth <- unname(v["population_increase"])
migration_residual <- sum(components)-migration
growth_residual <- natural+migration-growth
# These rounded values reconcile exactly. Do not invent a rounding-adjustment bar.
stopifnot(migration_residual==0,growth_residual==0,natural>0,migration<0,growth>0)
write_csv(tibble(check=c("Four migration components minus reported balance",
                         "Births minus deaths plus migration minus population increase"),
                 residual_people=c(migration_residual,growth_residual),
                 precision="CBS approximate thousand; zero residual at reported precision"),
          file.path(data_dir,"reconciliation.csv"))

# Direct TOTAL migration-balance fields, never E/4 or a residual from population stocks.
a <- read_excel(file.path(data_dir,"st02_08-2025.xlsx"),sheet="ST02-08a",col_names=FALSE,
                col_types="text",.name_repair="minimal")
stopifnot(grepl("SOURCES OF ISRAELIS",a[[1]][2]),
          a[[8]][8]=="Total",grepl("Thousands",a[[1]][3]))
end_total <- which(trimws(a[[2]])=="POPULATION GROUP")[1]
first_total <- which(trimws(a[[2]])=="TOTAL POPULATION")[1]
rows <- seq(first_total+1,end_total-1)
row_year <- suppressWarnings(as.integer(sub("\\(.*","",a[[1]][rows])))
keep <- !is.na(row_year) & row_year %in% 2023:2024
annual_a <- tibble(year=row_year[keep],
  balance_people=as.numeric(a[[8]][rows[keep]])*1000,
  source_file="st02_08-2025.xlsx",sheet="ST02-08a",excel_row=rows[keep],
  source_column="H",source_published="2025-12-24")
b <- read_excel(file.path(data_dir,"st02_09-2026.xlsx"),sheet="ST02-09a",col_names=FALSE,
                col_types="text",.name_repair="minimal")
stopifnot(grepl("SOURCES OF ISRAELIS",b[[1]][3]),
          b[[7]][11]=="Total(1)",grepl("Thousands",b[[1]][5]))
grand <- which(trimws(b[[1]])=="GRAND TOTAL")
stopifnot(length(grand)==1,as.integer(b[[5]][5])==2025,as.numeric(b[[5]][grand])==0)
annual_b <- tibble(year=as.integer(b[[5]][5]),
  balance_people=as.numeric(b[[7]][grand])*1000,
  source_file="st02_09-2026.xlsx",sheet="ST02-09a",excel_row=grand,
  source_column="G",source_published="2026-10-08")
annual <- bind_rows(annual_a,annual_b) %>% mutate(
  measure="Total international migration balance of Israeli population; excludes foreign population",
  methodology="Post-2023 population-estimation methodology",
  vintage_note=if_else(year<2025,"2025 annual table; not recomputed with E/4",
    "2026 annual table; same post-2023 definitions; revisions possible"),
  balance_thousands=balance_people/1000)
stopifnot(identical(annual$year,2023:2025),!anyNA(annual$balance_people),!anyDuplicated(annual$year))
write_csv(annual,file.path(data_dir,"annual_total_balance.csv"))
# Preserve earlier available totals as an exclusion audit, not as chart observations.
prior <- rows[!is.na(row_year) & row_year<2023]
write_csv(tibble(year=as.integer(sub("\\(.*","",a[[1]][prior])),
  reported_total_thousands=as.numeric(a[[8]][prior]),
  decision="Excluded: pre-2023 population methodology; no verified harmonized total backcast"),
  file.path(data_dir,"excluded_annual_rows.csv"))
sources <- read_csv(file.path(data_dir,"sources.csv"),show_col_types=FALSE)
stopifnot(all(file.exists(file.path(data_dir,sources$file))))
hashes <- vapply(file.path(data_dir,sources$file),function(p) {
  raw <- readBin(p,"raw",n=file.size(p)); digest::digest(raw,algo="sha256",serialize=FALSE)
},character(1))
write_csv(mutate(sources,sha256=hashes),file.path(data_dir,"source_checksums.csv"))

# Start with the established repository theme; adapt only this project's presentation.
source("R/theme_data_decoded.R")
paper <- "#FFFFFF"; ink <- "#172033"; support <- "#666666"
blue <- "#2455FF"; crimson <- "#C83242"; grey <- "#A6B0BD"; grid_col <- "#E6E8EB"
font_dir <- Sys.getenv("TDD_LATO_FONT_DIR","assets/fonts/lato")
font_files <- file.path(font_dir,paste0("Lato-",c("Regular","Bold","Black"),".ttf"))
if(any(!file.exists(font_files))) stop("Bundled Lato Regular, Bold and Black are required")
infos <- lapply(font_files,function(p) systemfonts::font_info(path=p))
stopifnot(all(vapply(infos,function(i)i$family[[1]]=="Lato",logical(1))),
  identical(vapply(infos,function(i)i$style[[1]],character(1)),c("Regular","Bold","Black")))
regular_alias <- "TDD Lato"; bold_alias <- "TDD Lato Bold"; title_alias <- "TDD Lato Black"
italic_file <- file.path(font_dir,"Lato-Italic.ttf")
stopifnot(file.exists(italic_file),systemfonts::font_info(path=italic_file)$style[[1]]=="Italic")
systemfonts::register_font(regular_alias,plain=font_files[1],bold=font_files[2],italic=italic_file)
systemfonts::register_font(bold_alias,plain=font_files[2])
systemfonts::register_font(title_alias,plain=font_files[3],bold=font_files[3])
resolved <- c(systemfonts::match_fonts(regular_alias)$path[1],
  systemfonts::match_fonts(bold_alias)$path[1],
  systemfonts::match_fonts(title_alias,weight="bold")$path[1])
stopifnot(identical(normalizePath(resolved),normalizePath(font_files)))
write_csv(tibble(role=c("support","direct labels","title"),weight=c(400,700,900),
                 file=font_files,resolved=resolved),file.path(data_dir,"font_validation.csv"))
base_theme <- theme_data_decoded() + theme(
  text=element_text(family=regular_alias,colour=support,size=14),
  panel.background=element_rect(fill=paper,colour=NA),
  plot.background=element_rect(fill=paper,colour=NA),
  panel.grid.major.x=element_blank(),panel.grid.minor=element_blank(),
  panel.grid.major.y=element_line(colour=grid_col,linewidth=.35),
  axis.title=element_blank(),axis.text=element_text(size=13.5,colour=support),
  axis.text.x=element_text(margin=margin(t=9),lineheight=1.03),
  plot.margin=margin(10,8,8,0),legend.position="none")
signed <- function(x,digits=0) paste0(ifelse(x>=0,"+","\u2212"),
  format(abs(x)*1000,trim=TRUE,big.mark=",",nsmall=0,scientific=FALSE))
axis_k <- function(x) ifelse(x<0,paste0("\u2212",abs(x)),as.character(x))

# Chart 1: signed changes bridge cumulatively to the independently reported total.
wf <- tibble(x=1:4,value=components/1000) %>% mutate(
  end=cumsum(value),start=lag(end,default=0),low=pmin(start,end),high=pmax(start,end),
  fill=if_else(value>0,blue,crimson),label=signed(value),
  label_y=if_else(value>0,high+3,high+4))
wf_total <- tibble(x=5,value=migration/1000,start=0,end=migration/1000,
  low=migration/1000,high=0,fill=crimson,label=signed(migration/1000),
  label_y=migration/1000-5)
wf_all <- bind_rows(wf,wf_total)
p1 <- ggplot(wf_all) +
  geom_rect(data=wf,aes(xmin=x-.33,xmax=x+.33,ymin=low,ymax=high),fill=wf$fill) +
  geom_rect(data=wf_total,aes(xmin=x-.33,xmax=x+.33,ymin=low,ymax=high),fill=grey) +
  geom_segment(data=wf %>% filter(x<=4),aes(x=x+.33,xend=x+.67,y=end,yend=end),
    colour=grey,linewidth=.5) +
  geom_hline(yintercept=0,colour="#7B8490",linewidth=.65) +
  geom_text(aes(x=x,y=label_y,label=label),family=bold_alias,size=5.4,colour=c(wf$fill,ink)) +
  annotate("segment",x=.67,xend=3.33,y=59,yend=59,colour=blue,linewidth=.45) +
  annotate("segment",x=c(.67,3.33),xend=c(.67,3.33),y=59,yend=56.5,colour=blue,linewidth=.45) +
  annotate("text",x=2,y=63,label="49,000 arrivals",family=regular_alias,size=4.6,colour=blue) +
  scale_x_continuous(breaks=1:5,labels=c("New\nimmigrants","Family\nreunification",
    "Returning\nIsraelis","Israelis moving\nabroad","Net\nmigration"),limits=c(.5,5.5),expand=c(0,0)) +
  scale_y_continuous(breaks=seq(-20,60,20),labels=axis_k,limits=c(-21,72),expand=c(0,0)) +
  base_theme

# Annual chart: three calendar-year totals only.
annual <- mutate(annual,x=year-2022,fill=if_else(balance_people>0,blue,crimson),
  label=signed(balance_thousands),label_y=balance_thousands+if_else(balance_thousands>0,4,-4))
p2 <- ggplot(annual) +
  annotate("segment",x=.5,xend=3.5,y=seq(-30,30,10),yend=seq(-30,30,10),colour=grid_col,linewidth=.35) +
  geom_col(aes(x=x,y=balance_thousands),fill=annual$fill,width=.56) +
  annotate("segment",x=.5,xend=3.5,y=0,yend=0,colour="#7B8490",linewidth=.65) +
  geom_text(aes(x=x,y=label_y,label=label),family=bold_alias,size=5.7,colour=annual$fill) +
  scale_x_continuous(breaks=1:3,labels=2023:2025,limits=c(.5,3.5),expand=c(0,0)) +
  scale_y_continuous(breaks=seq(-30,30,10),labels=axis_k,limits=c(-36,39),expand=c(0,0)) +
  base_theme + theme(panel.grid.major.y=element_blank(),axis.text.x=element_text(family=bold_alias))

# Chart 3: two-component arithmetic bridge; final bar is the reported total.
pop <- tibble(x=1:3,low=c(0,growth/1000,0),high=c(natural,natural,growth)/1000,
  fill=c(blue,crimson,grey),value=c(natural,migration,growth)/1000)
p3 <- ggplot(pop) +
  geom_rect(aes(xmin=x-ifelse(x==2,.20,.34),xmax=x+ifelse(x==2,.20,.34),ymin=low,ymax=high),fill=pop$fill) +
  annotate("segment",x=1.34,xend=1.8,y=natural/1000,yend=natural/1000,
    colour=grey,linewidth=.5) +
  annotate("segment",x=2.2,xend=2.66,y=growth/1000,yend=growth/1000,
    colour=grey,linewidth=.5) +
  geom_hline(yintercept=0,colour="#7B8490",linewidth=.65) +
  annotate("text",x=1,y=natural/1000*.68,label=signed(natural/1000),
    family=bold_alias,size=6,colour=paper) +
  annotate("text",x=2,y=natural/1000+8,hjust=.5,label=signed(migration/1000),
    family=bold_alias,size=4.8,colour=crimson) +
  annotate("text",x=3,y=growth/1000*.68,label=signed(growth/1000),
    family=bold_alias,size=6,colour=ink) +
  annotate("text",x=1,y=141,label="182,000 births\n\u2212 50,000 deaths",family=regular_alias,size=4.8,lineheight=1.15,colour=ink) +
  scale_x_continuous(breaks=1:3,labels=c("Births minus\ndeaths","Net\nmigration",
    "Total population\ngrowth"),limits=c(.5,3.5),expand=c(0,0)) +
  scale_y_continuous(breaks=seq(0,150,50),labels=axis_k,limits=c(0,164),expand=c(0,0)) +
  base_theme

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
frame <- function(plot,title,subtitle,key,source,note,width=8.8,height=8.8,dpi=240) {
  draw <- function() {
    grid.newpage(); grid.rect(gp=gpar(fill=paper,col=NA))
    left <- .4; content <- width-.8; top <- height-.34
    title_lines <- wrap_lines(title,content,22,family=title_alias)
    sub_lines <- wrap_lines(subtitle,content,14.5)
    stopifnot(length(title_lines)>=1,length(sub_lines)>=1)
    # Identical font-metric slots across all three charts. Their title lines all
    # wrap across the full content width; slot origins remain consistent.
    title_step <- .32
    sub_top <- top-length(title_lines)*title_step
    for(i in seq_along(title_lines)) grid.text(title_lines[i],
      x=unit(left,"in"),y=unit(top-(i-1)*title_step,"in"),just=c("left","top"),
      gp=gpar(fontfamily=title_alias,fontsize=22,col=ink))
    for(i in seq_along(sub_lines)) grid.text(sub_lines[i],
      x=unit(left,"in"),y=unit(sub_top-(i-1)*.23,"in"),just=c("left","top"),
      gp=gpar(fontfamily=regular_alias,fontsize=14.5,col=support))
    header_audit[[key]] <<- tibble(chart=key,title_line=seq_along(title_lines),subtitle_lines=length(sub_lines),
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
    grid.text("People, thousands",x=unit(left,"in"),y=unit(plot_top-.10,"in"),
      just=c("left","top"),gp=gpar(fontfamily=regular_alias,fontface="italic",fontsize=4.6*72.27/25.4,col=support))
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
    paste0('@font-face{font-family:"Lato";font-weight:400;font-style:italic;src:url(data:font/ttf;base64,',
      base64enc::base64encode(italic_file,linewidth=0),') format("truetype");}'),']]></style>')
  svg <- paste(readLines(svg_path,warn=FALSE),collapse="\n")
  svg <- sub("(<svg\\b[^>]*>)",paste0("\\1\n",css),svg,perl=TRUE)
  writeLines(svg,svg_path,useBytes=TRUE)
}
period_sub <- "International migration over approximately 11\u00bd months, approximately September 2025\u2013September 2026"
frame(p1,"International migration reduced Israel\u2019s population by about 8,000 in the year to September 2026",
  "Late September 2025\u2013early September 2026 \u00b7 Israeli residents \u00b7 provisional estimates","01-migration-components",
  "Israel CBS, Rosh Hashana release 282/2026, p. 1 (Sep 9, 2026).",
  "Published ahead of Rosh Hashana, the Jewish New Year. Figures rounded.")
frame(p2,"Israel's net migration turned negative in 2024",
  "Annual international migration balance, 2023\u20132025. Calendar-year totals for the Israeli population",
  "02-annual-migration-balance","Israel CBS, annual tables 2.8 (2025) and 2.9 (2026).",
  "Annual figures may be revised.")
frame(p3,"Israel's population grew despite negative net migration",
  "Population change over approximately 11\u00bd months, approximately September 2025\u2013September 2026","03-population-growth",
  "Israel CBS, Rosh Hashana release 282/2026, p. 1 (Sep 9, 2026).",
  "Published ahead of Rosh Hashana, the Jewish New Year. Provisional CBS estimates; figures rounded. Excludes the foreign population.")
write_csv(bind_rows(header_audit),file.path(data_dir,"header_slots.csv"))
cat("Reconciliation: exact at reported rounded precision. Annual coverage: 2023-2025; historical reconstruction remains unverified.\n")
cat("Exported exactly three charts as PNG and self-contained SVG at 8.8 x 8.8 inches (PNG 2112 x 2112).\n")
