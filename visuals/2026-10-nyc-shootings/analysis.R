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
paper <- "#F7F5EE"; ink <- "#172033"; blue <- "#2455FF"
crimson <- "#C83242"; amber <- "#D49A44"; teal <- "#087F79"; context <- "#A6B0BD"
font_dir <- "brand-exploration/fonts"
font_files <- file.path(font_dir, paste0("WorkSans-", c("Regular", "Medium", "Bold"), ".ttf"))
if (any(!file.exists(font_files))) stop("Bundled Work Sans font files missing")
font_info <- lapply(font_files, function(path) systemfonts::font_info(path = path))
if (!all(vapply(font_info, function(x) identical(x$family[[1]], "Work Sans"), logical(1)))) stop("A bundled font is not Work Sans")
regular_alias <- "TDD Work Sans"; medium_alias <- "TDD Work Sans Medium"
systemfonts::register_font(regular_alias, plain = font_files[1], bold = font_files[3])
systemfonts::register_font(medium_alias, plain = font_files[2])
resolved <- c(systemfonts::match_fonts(regular_alias)$path[1],
              systemfonts::match_fonts(medium_alias)$path[1],
              systemfonts::match_fonts(regular_alias, weight = "bold")$path[1])
if (!identical(normalizePath(resolved), normalizePath(font_files))) stop("Work Sans resolved to a substitute font")

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

base_theme <- theme_minimal(base_family = regular_alias, base_size = 13) +
  theme(text = element_text(colour = ink, family = regular_alias),
    axis.text = element_text(colour = ink, size = 14),
    axis.title = element_blank(), legend.position = "none",
    panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(colour = "#D9D8D2", linewidth = 0.35, linetype = "dashed"),
    panel.background = element_rect(fill = paper, colour = NA),
    plot.background = element_rect(fill = paper, colour = NA),
    plot.margin = margin(8, 16, 2, 8))
line_group <- function(d, year, color, width = 1.25, linetype = "solid") {
  geom_line(data = d %>% filter(.data$year == !!year),
    aes(x = x, y = cumulative, group = year), colour = color,
    linewidth = width, linetype = linetype, lineend = "round")
}
# The context series are thin and subdued; highlights use consistent colors in both charts.
context_years <- months %>% filter(!year %in% c(2020, 2021, 2025, 2026))

cum <- months %>% group_by(year) %>% arrange(month, .by_group=TRUE) %>%
  mutate(cumulative = cumsum(incidents)) %>% ungroup()
full_end <- cum %>% filter(year %in% c(2020, 2021, 2025), month == 12)
partial_end <- cum %>% filter(year == 2026, month == 6)
labels_cum <- bind_rows(full_end, partial_end) %>%
  mutate(label = case_when(year == 2020 ~ paste0("2020 - ", comma(cumulative)),
                           year == 2021 ~ paste0("2021 - ", comma(cumulative)),
                           year == 2025 ~ paste0("2025 - ", comma(cumulative)),
                           TRUE ~ paste0("2026 - ", comma(cumulative), "\nthrough June 30")),
         label_y = cumulative + case_when(year == 2021 ~ 70, year == 2020 ~ -34, year == 2025 ~ 30, year == 2026 ~ 120, TRUE ~ 65),
         label_x = if_else(year == 2026, 6.3, 12), label_hjust = if_else(year == 2026, 0, 1.02))
comparison_label <- sprintf("2025 was %.1f%% below 2021 (%s fewer incidents)", abs(change_pct), comma(abs(change_n)))

p_cum <- ggplot() +
  geom_line(data = cum %>% filter(!year %in% c(2020, 2021, 2025, 2026)), aes(x=x, y=cumulative, group=year),
    colour = context, alpha = .68, linewidth = .45) +
  line_group(cum, 2020, crimson, 1.4) + line_group(cum, 2021, amber, 1.4, "longdash") +
  line_group(cum, 2025, blue, 1.8) + line_group(cum, 2026, teal, 1.55, "dotdash") +
  geom_point(data=labels_cum, aes(x=month, y=cumulative), colour=c(crimson,amber,blue,teal), size=2) +
  geom_label(data=labels_cum %>% filter(year != 2026), aes(x=label_x, y=label_y, label=label, hjust=label_hjust),
    fill=paper, label.padding=unit(.1,"lines"), linewidth=0,
    colour=c(crimson,amber,blue), family=medium_alias, fontface="plain", size=4.1,
    vjust=.5, lineheight=.95) +
  geom_text(data=labels_cum %>% filter(year == 2026), aes(x=label_x, y=label_y, label=label, hjust=label_hjust),
    colour=teal, family=medium_alias, size=4.1, vjust=.5, lineheight=.95) +  annotate("label", x=1.15, y=max(cum$cumulative[cum$year==2025]) + 170,
    label=comparison_label, hjust=0, family=medium_alias, size=3.15,
    colour=ink, fill=paper, linewidth=0, label.padding=unit(.15,"lines")) +
  scale_x_continuous(breaks=1:12, labels=month.abb, limits=c(1,12), expand=expansion(mult=c(.01,.01))) +
  scale_y_continuous(labels=comma, breaks=pretty_breaks(6), expand=expansion(mult=c(.02,.16))) +
  coord_cartesian(clip="off") + base_theme

# Direct end labels for annual monthly lines; 2026 stops at June and is explicitly marked.
month_ends <- months %>% filter((year %in% c(2020,2021,2025) & month==12) | (year==2026 & month==6))
month_ends <- month_ends %>% mutate(label = case_when(year==2026 ~ "2026 - Jun 30",
  TRUE ~ as.character(year)), label_y = incidents + case_when(year==2020 ~ 28, year==2021 ~ -18, year==2025 ~ -8, TRUE ~ 32),
  label_x = if_else(year==2026, 6.2, 12), label_hjust = if_else(year==2026, 0, 1.02))
p_month <- ggplot() +
  geom_line(data=context_years, aes(x=x, y=incidents, group=year), colour=context, alpha=.68, linewidth=.45) +
  geom_line(data=months %>% filter(year==2020), aes(x=x,y=incidents,group=year), colour=crimson, linewidth=1.35) +
  geom_line(data=months %>% filter(year==2021), aes(x=x,y=incidents,group=year), colour=amber, linewidth=1.35, linetype="longdash") +
  geom_line(data=months %>% filter(year==2025), aes(x=x,y=incidents,group=year), colour=blue, linewidth=1.65) +
  geom_line(data=months %>% filter(year==2026), aes(x=x,y=incidents,group=year), colour=teal, linewidth=1.45, linetype="dotdash") +
  geom_point(data=month_ends, aes(x=month,y=incidents), colour=c(crimson,amber,blue,teal), size=1.8) +
  geom_label(data=month_ends, aes(x=label_x,y=label_y,label=label,hjust=label_hjust), fill=paper,
    label.padding=unit(.1,"lines"), linewidth=0, colour=c(crimson,amber,blue,teal),
    family=medium_alias, size=4.0, vjust=.5) +
  annotate("label", x=7.1, y=268, label="Jul 2020 - 243 incidents", hjust=0,
    family=medium_alias, colour=ink, fill=paper, linewidth=0, size=3.2) +
  annotate("segment", x=7.35, y=255, xend=7, yend=243, colour=crimson, linewidth=.45) +
  annotate("label", x=1.1, y=202, label="December 2025 - 35 incidents\nlowest month since 2006 in this dataset", hjust=0,
    family=medium_alias, colour=ink, fill=paper, linewidth=0, size=3.05, lineheight=.95) +
  scale_x_continuous(breaks=1:12, labels=month.abb, limits=c(1,12), expand=expansion(mult=c(.01,.01))) +
  scale_y_continuous(breaks=seq(0,250,50), limits=c(0,280), expand=expansion(mult=c(.01,.01))) +
  coord_cartesian(clip="off") + base_theme

# Draw the real-project trial frame around a plot. Dimensions stay landscape for line charts.
logo_source <- paste(readLines("brand-exploration/pterosaur-simplified.svg", warn=FALSE), collapse="\n")
viewbox <- regmatches(logo_source, regexec('viewBox="[0-9.]+ [0-9.]+ ([0-9.]+) ([0-9.]+)"',logo_source))[[1]]
logo_ratio <- as.numeric(viewbox[2])/as.numeric(viewbox[3])
logo_raw <- rsvg::rsvg_png(charToRaw(logo_source), width=366, height=round(366/logo_ratio))
logo_raster <- png::readPNG(logo_raw, native=TRUE)
footer <- function(plot, title, subtitle, source, note, path_stub, width, height, dpi) {
  draw <- function() {
    grid::grid.newpage(); grid::grid.rect(gp=grid::gpar(fill=paper,col=NA))
    left <- .58; right <- .58; top <- height-.38; cw <- width-left-right
    grid::grid.text(title,x=unit(left,"in"),y=unit(top,"in"),just=c("left","top"),
      gp=gpar(fontfamily=regular_alias,fontface="bold",fontsize=29,col=ink,lineheight=1.03))
    grid::grid.text(subtitle,x=unit(left,"in"),y=unit(top-.66,"in"),just=c("left","top"),
      gp=gpar(fontfamily=regular_alias,fontsize=15,col=ink))
    plot_top <- top-1.14
    divider_y <- .92
    note_y <- 1.38; source_y <- 1.64
    grid::grid.text(source,x=unit(left,"in"),y=unit(source_y,"in"),just=c("left","bottom"),
      gp=gpar(fontfamily=regular_alias,fontsize=14,col=ink))
    grid::grid.text(note,x=unit(left,"in"),y=unit(note_y,"in"),just=c("left","bottom"),
      gp=gpar(fontfamily=regular_alias,fontsize=13.5,col="#576071"))
    plot_bottom <- 1.95
    grid::pushViewport(viewport(x=unit(left,"in"),y=unit(plot_bottom,"in"), width=unit(cw,"in"),height=unit(plot_top-plot_bottom,"in"),just=c("left","bottom"))); grid::grid.draw(ggplotGrob(plot)); grid::popViewport()
    grid::grid.lines(x=unit(c(left,width-right),"in"),y=unit(divider_y,"in"),gp=gpar(col="#C9C8C2",lwd=.7))
    logo_w <- .48; logo_h <- logo_w/logo_ratio; signature_y <- .51
    grid::grid.raster(logo_raster,x=unit(left+logo_w/2,"in"),y=unit(signature_y,"in"),width=unit(logo_w,"in"),height=unit(logo_h,"in"))
    grid::grid.text("THE DATA DECODED",x=unit(left+.59,"in"),y=unit(signature_y,"in"),just="left",
      gp=gpar(fontfamily=medium_alias,fontsize=14,col=ink))
  }
  png_path <- file.path(project,"plots",paste0(path_stub,".png"))
  svg_path <- file.path(project,"plots",paste0(path_stub,".svg"))
  ragg::agg_png(png_path,width=width,height=height,units="in",res=dpi,background=paper); draw(); dev.off()
  svglite::svglite(svg_path,width=width,height=height,bg=paper); draw(); dev.off()
  css <- paste0('<metadata>Work Sans, SIL Open Font License 1.1; see brand-exploration/fonts/OFL.txt in the repository.</metadata><style>',
    '@font-face{font-family:"Work Sans";font-weight:400;src:url(data:font/ttf;base64,',base64enc::base64encode(font_files[1],linewidth=0),') format("truetype");}',
    '@font-face{font-family:"Work Sans";font-weight:500;src:url(data:font/ttf;base64,',base64enc::base64encode(font_files[2],linewidth=0),') format("truetype");}',
    '@font-face{font-family:"Work Sans";font-weight:700;src:url(data:font/ttf;base64,',base64enc::base64encode(font_files[3],linewidth=0),') format("truetype");}</style>')
  svg <- readLines(svg_path,warn=FALSE); svg[1] <- sub(">$",paste0(">",css),svg[1]); writeLines(svg,svg_path,useBytes=TRUE)
}
source_text <- "Source: NYPD via NYC Open Data / Shootings (2006-Present), dataset 5ucz-vwe8"
note_text <- "Reported shooting incidents (unique INCIDENT_KEYs); counts are not people shot or all gun violence."
footer(p_cum,"NYC shooting counts fell after the 2020-2021 peak","Cumulative incident counts by month | 2006-2025; 2026 through June 30",source_text,note_text,"cumulative_web",12,8.3,180)
footer(p_month,"NYC shooting counts fell after the 2020-2021 peak","Monthly incident counts | 2006-2025; 2026 through June 30",source_text,note_text,"monthly_web",12,8.3,180)
footer(p_cum,"NYC shooting counts fell after the 2020-2021 peak","Cumulative incident counts by month | 2006-2025; 2026 through June 30",source_text,note_text,"cumulative_x",12,8.8,180)
footer(p_month,"NYC shooting counts fell after the 2020-2021 peak","Monthly incident counts | 2006-2025; 2026 through June 30",source_text,note_text,"monthly_x",12,8.8,180)
cat(sprintf("2025=%d; 2021=%d; difference=%d (%.1f%%); 2026 Jan-Jun=%d vs 2025=%d (%d, %.1f%%); peak 2020 month %s=%d\n",
 annual_totals,peak_total,change_n,change_pct,first_half,first_half_25,change_half,pct_half,month.abb[peak_month$month],peak_month$incidents))
print(checks); print(annual)












