# Reproduce from the committed snapshot; run from the repository root.
required <- c("readr", "dplyr", "tidyr", "lubridate", "ggplot2", "scales",
              "ragg", "svglite", "systemfonts", "rsvg", "png", "base64enc")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required packages: ", paste(missing, collapse = ", "))
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(lubridate)
  library(ggplot2); library(scales); library(grid)
})
project <- "visuals/2026-10-nyc-shootings"
snapshot <- file.path(project, "data/shootings_snapshot.csv")
raw <- read_csv(snapshot, col_types = cols(.default = col_character()), na = c("", "NA", "NULL"), show_col_types = FALSE)
required_cols <- c("INCIDENT_KEY", "OCCUR_DATE")
if (!all(required_cols %in% names(raw))) stop("Snapshot lacks required incident fields")
raw <- raw %>% mutate(occur_date = as.Date(OCCUR_DATE, format = "%m/%d/%Y"))
if (any(is.na(raw$INCIDENT_KEY)) || any(!nzchar(raw$INCIDENT_KEY))) stop("Missing incident key")
if (any(is.na(raw$occur_date))) stop("Missing or unparseable occurrence date")
checks <- tibble(
  records = nrow(raw), unique_incident_keys = n_distinct(raw$INCIDENT_KEY),
  duplicate_key_records = sum(duplicated(raw$INCIDENT_KEY)), missing_incident_keys = sum(is.na(raw$INCIDENT_KEY)),
  missing_occurrence_dates = sum(is.na(raw$occur_date)), earliest_occurrence = min(raw$occur_date),
  latest_occurrence = max(raw$occur_date), retrieved_utc = "2026-10-02",
  source_url = "https://data.cityofnewyork.us/api/views/5ucz-vwe8/rows.csv?accessType=DOWNLOAD"
)
write_csv(checks, file.path(project, "data/quality_checks.csv"))

# Treat each INCIDENT_KEY as one shooting incident; the source has one row per ID here.
incidents <- raw %>% distinct(INCIDENT_KEY, .keep_all = TRUE) %>%
  transmute(incident_key = INCIDENT_KEY, date = occur_date, year = year(date), month = month(date))
if (nrow(incidents) != nrow(raw)) warning("Duplicate IDs were deduplicated for all counts")
if (!all(incidents$date[incidents$year == 2025] <= as.Date("2025-12-31"))) stop("Unexpected 2025 dates")

# NYPD's July 2, 2026 first-half release independently reports Jan-Jun = 322.
cutoff <- as.Date("2026-06-30")
if (sum(incidents$year == 2026 & incidents$date <= cutoff) != 322L) stop("2026 Jan-Jun no longer matches NYPD's first-half report; review cutoff/coverage")
if (max(incidents$date) < cutoff) stop("Snapshot does not reach the verified 2026 cutoff")

observed_month <- incidents %>% count(year, month, name = "incidents")
month_grid <- tidyr::expand_grid(year = 2006:2026, month = 1:12) %>%
  mutate(month_start = as.Date(sprintf("%d-%02d-01", year, month)),
         month_end = ceiling_date(month_start, "month") - days(1)) %>%
  filter(month_start >= min(incidents$date), month_end <= cutoff) %>%
  left_join(observed_month, by = c("year", "month")) %>%
  mutate(incidents = replace_na(incidents, 0L),
         coverage = if_else(month_end <= as.Date("2025-12-31"), "complete_calendar_month", "verified_through_2026-06-30"),
         month_label = factor(month, levels = 1:12, labels = month.abb))
write_csv(month_grid, file.path(project, "data/monthly_incident_counts.csv"))
annual <- month_grid %>% filter(year <= 2025) %>% group_by(year) %>%
  summarise(incidents = sum(incidents), observed_months = n(), .groups = "drop")
write_csv(annual, file.path(project, "data/annual_incident_counts.csv"))
monthly_compare <- month_grid %>% filter(month <= 6, year <= 2026) %>%
  group_by(year) %>% summarise(jan_jun_incidents = sum(incidents), .groups = "drop")
write_csv(monthly_compare, file.path(project, "data/january_june_comparison.csv"))
coverage <- month_grid %>% group_by(year) %>% summarise(covered_months = n(),
  zero_incident_months = sum(incidents == 0), .groups = "drop")
write_csv(coverage, file.path(project, "data/monthly_coverage.csv"))

# Use confirmed palette roles from the brand study. 2021 amber (#D49A44) is palette B.
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

months <- month_grid %>% arrange(year, month) %>%
  mutate(x = month, year_group = factor(year),
         highlight = year %in% c(2020, 2021, 2025, 2026),
         endpoint = case_when(year == 2026 & month == 6 ~ "2026 - through June 30",
                              year == 2025 & month == 12 ~ "2025",
                              year == 2021 & month == 12 ~ "2021",
                              year == 2020 & month == 12 ~ "2020",
                              TRUE ~ NA_character_))
annual_totals <- annual$incidents[annual$year == 2025]
peak_total <- annual$incidents[annual$year == 2021]
if (length(annual_totals) != 1 || length(peak_total) != 1) stop("Missing comparison years")
change_n <- annual_totals - peak_total
change_pct <- change_n / peak_total * 100
first_half <- monthly_compare$jan_jun_incidents[monthly_compare$year == 2026]
first_half_25 <- monthly_compare$jan_jun_incidents[monthly_compare$year == 2025]
change_half <- first_half - first_half_25
pct_half <- 100 * change_half / first_half_25
peak_month <- month_grid %>% filter(year == 2020) %>% slice_max(incidents, n=1, with_ties=FALSE)


# Presentation trial: flexible frame, solid data series, one master per chart.
support <- "#666666"
styles <- c("2020"=crimson, "2021"=amber, "2025"=blue, "2026"=teal)
base_theme <- theme_minimal(base_family=regular_alias, base_size=16) +
  theme(text=element_text(colour=ink), axis.text=element_text(colour=support,size=14.5),
    axis.title=element_blank(), legend.position="none", panel.grid.minor=element_blank(),
    panel.grid.major.x=element_blank(), panel.grid.major.y=element_blank(),
    panel.background=element_rect(fill=paper,colour=NA), plot.background=element_rect(fill=paper,colour=NA),
    legend.background=element_rect(fill=paper,colour=NA), plot.margin=margin(4,2,3,0))
context_years <- months %>% filter(!highlight)
axis_months <- scale_x_continuous(breaks=1:12,labels=month.abb,limits=c(.8,14.4),expand=c(0,0))

# Refine the monthly view first; endpoint labels have short solid leaders.
month_ends <- months %>% filter((year %in% c(2020,2021,2025) & month==12) | (year==2026 & month==6)) %>%
  mutate(label=if_else(year==2026,"2026 \u00b7\nthrough June",as.character(year)),
    lx=if_else(year==2026,6.4,12.3),
    ly=case_when(year==2020 ~ 140,year==2021 ~ 105,year==2025 ~ 36,TRUE ~ 61))
p_month <- ggplot() +
  annotate("segment",x=.8,xend=12,y=seq(50,250,50),yend=seq(50,250,50),colour="#E6E8EB",linewidth=.35) +
  annotate("segment",x=.8,xend=12,y=0,yend=0,colour="#939BA5",linewidth=.5) +
  geom_line(data=context_years,aes(x=month,y=incidents,group=year),colour=context,alpha=.45,linewidth=.30) +
  geom_line(data=months %>% filter(highlight & year!=2026),aes(x=month,y=incidents,group=year,colour=factor(year)),linewidth=1.2) +
  geom_line(data=months %>% filter(year==2026),aes(x=month,y=incidents),colour=paper,linewidth=1.65) +
  geom_line(data=months %>% filter(year==2026),aes(x=month,y=incidents),colour=teal,linewidth=1.2) +
  geom_segment(data=month_ends,aes(x=month,y=incidents,xend=if_else(year==2026,lx-.10,lx),yend=ly,colour=factor(year)),linewidth=.4) +
  geom_point(data=month_ends,aes(x=month,y=incidents,colour=factor(year)),size=2.5) +
  geom_label(data=month_ends %>% filter(year!=2026),aes(x=lx,y=ly,label=label,colour=factor(year)),hjust=0,
    fill=paper,linewidth=0,label.padding=unit(.08,"lines"),family=bold_alias,size=4.6,lineheight=.95) +
  geom_text(data=month_ends %>% filter(year==2026),aes(x=lx,y=ly,label=label,colour=factor(year)),hjust=0,
    family=bold_alias,size=4.6,lineheight=.95) +
  annotate("text",x=7.25,y=275,label="Jul 2020: 243\nhighest month since 2006",hjust=0,family=bold_alias,size=4.6,colour=crimson,lineheight=.95) +
  annotate("segment",x=7.2,y=264,xend=7,yend=243,colour=crimson,linewidth=.5) +
  annotate("text",x=10.7,y=14,label="Dec 2025: 35\nlowest month since 2006",hjust=1,
    family=bold_alias,size=4.6,colour=blue,lineheight=.95) +
  annotate("segment",x=10.9,y=20,xend=12,yend=35,colour=blue,linewidth=.5) +
  scale_colour_manual(values=styles) + axis_months +
  scale_y_continuous(breaks=seq(0,250,50),limits=c(0,287),expand=c(0,0)) + base_theme

cum <- months %>% group_by(year) %>% arrange(month,.by_group=TRUE) %>% mutate(cumulative=cumsum(incidents)) %>% ungroup()
cum_ends <- cum %>% filter((year %in% c(2020,2021,2025) & month==12) | (year==2026 & month==6)) %>%
  mutate(label=if_else(year==2026,"2026: 322\nthrough Jun 30",paste0(year,": ",comma(cumulative))),
    lx=if_else(year==2026,6.35,12.3),
    ly=case_when(year==2020 ~ 1460,year==2021 ~ 1650,year==2025 ~ 688,TRUE ~ 240))
p_cum <- ggplot() +
  annotate("segment",x=.8,xend=12,y=seq(500,1500,500),yend=seq(500,1500,500),colour="#E6E8EB",linewidth=.35) +
  annotate("segment",x=.8,xend=12,y=0,yend=0,colour="#939BA5",linewidth=.5) +
  geom_line(data=cum %>% filter(!highlight),aes(x=month,y=cumulative,group=year),colour=context,alpha=.65,linewidth=.42) +
  geom_line(data=cum %>% filter(highlight & year!=2026),aes(x=month,y=cumulative,group=year,colour=factor(year)),linewidth=1.2) +
  geom_line(data=cum %>% filter(year==2026),aes(x=month,y=cumulative),colour=paper,linewidth=1.65) +
  geom_line(data=cum %>% filter(year==2026),aes(x=month,y=cumulative),colour=teal,linewidth=1.2) +
  geom_point(data=cum_ends,aes(x=month,y=cumulative,colour=factor(year)),size=2.5) +
  geom_segment(data=cum_ends,aes(x=month,y=cumulative,xend=lx,yend=ly,colour=factor(year)),linewidth=.4) +
  geom_label(data=cum_ends,aes(x=lx,y=ly,label=label,colour=factor(year)),hjust=0,
    fill=paper,linewidth=0,label.padding=unit(.08,"lines"),family=bold_alias,size=4.6,lineheight=.95) +
  annotate("text",x=2,y=1250,label="2025 had less than half\nthe shootings of 2021",
    hjust=0,family=regular_alias,size=4.6,colour=support,lineheight=.95) +
  scale_colour_manual(values=styles) + axis_months +
  scale_y_continuous(breaks=seq(0,1500,500),limits=c(0,1780),expand=c(0,0)) + base_theme

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
frame <- function(plot,title,subtitle,key,width=8.8,height=8.8,dpi=240) {
  draw <- function() {
    grid.newpage(); grid.rect(gp=gpar(fill=paper,col=NA))
    left <- .40; content <- width-.80; top <- height-.34
    title_lines <- wrap_lines(title,content,22,"bold",family=title_alias)
    title_h <- length(title_lines)*22/72*1.08
    grid.text(paste(title_lines,collapse="\n"),x=unit(left,"in"),y=unit(top,"in"),just=c("left","top"),
      gp=gpar(fontfamily=title_alias,fontface="bold",fontsize=22,col=ink,lineheight=1.08))
    sub_top <- top-title_h-.10
    sub_lines <- wrap_lines(subtitle,content,14.5)
    grid.text(paste(sub_lines,collapse="\n"),x=unit(left,"in"),y=unit(sub_top,"in"),just=c("left","top"),
      gp=gpar(fontfamily=regular_alias,fontsize=14.5,col=support,lineheight=1.1))
    plot_top <- sub_top-length(sub_lines)*14.5/72*1.1-.16
    meta_size <- 13; meta_leading <- .195; field_gap <- .035
    source <- "NYPD via NYC Open Data (5ucz-vwe8). Snapshot: Oct 2, 2026."
    note <- if(key=="monthly") "Incidents, not people shot. Counts are by incident month; 2026 includes January\u2013June only." else
      "Incidents, not people shot. 2025: lowest annual total in this dataset since 2006."
    source_lines <- wrap_lines(paste("Source:",source),content,meta_size)
    note_lines <- if(nzchar(note)) wrap_lines(paste("Notes:",note),content,meta_size) else character()
    metadata_top <- 1.01+(length(source_lines)+length(note_lines))*meta_leading+field_gap
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
    plot_bottom <- metadata_top+.23
    pushViewport(viewport(x=unit(left,"in"),y=unit(plot_bottom,"in"),width=unit(content,"in"),
      height=unit(plot_top-plot_bottom,"in"),just=c("left","bottom")))
    grid.draw(ggplotGrob(plot)); popViewport()
    grid.lines(x=unit(c(left,width-left),"in"),y=unit(.85,"in"),gp=gpar(col="#DEE1E5",lwd=.7))
    logo_w <- .60; logo_h <- logo_w/logo_ratio
    grid.raster(logo_raster,x=unit(left+logo_w/2,"in"),y=unit(.43,"in"),width=unit(logo_w,"in"),height=unit(logo_h,"in"))
    grid.text("THE DATA DECODED",x=unit(left+logo_w+.14,"in"),y=unit(.43,"in"),just="left",
      gp=gpar(fontfamily=regular_alias,fontsize=14,col=ink))
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
  svg <- paste(readLines(svg_path,warn=FALSE),collapse="\n")
  if(length(regmatches(svg,gregexpr("<svg[ >]",svg))[[1]])!=1) stop("Expected one SVG root")
  svg <- sub("(<svg\\b[^>]*>)",paste0("\\1\n",css),svg,perl=TRUE)
  writeLines(svg,svg_path,useBytes=TRUE)
}
headline <- "NYC shootings surged in 2020\u20132021, then fell to a record low in 2025"
frame(p_month,"The summer 2020 spike stands out against 2025\u2019s lower monthly counts",
      "Monthly incident counts since 2006; 2026 through June 30", "monthly",8.8,8.8)
if(Sys.getenv("TDD_EXPORT_ONLY")!="monthly") frame(p_cum,headline,
      "Cumulative incident counts since 2006; 2026 through June 30", "cumulative",8.8,8.8)
cat(sprintf("Verified calculations retained: 2025=%d; 2021=%d; Jan-Jun 2026=%d vs 2025=%d\n",annual_totals,peak_total,first_half,first_half_25))

