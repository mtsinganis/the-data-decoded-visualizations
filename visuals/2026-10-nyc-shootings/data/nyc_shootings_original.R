project_path <- "C:/Users/marko/Desktop/The Data Decoded - New ideas/NYC Shootings"

setwd(project_path)

dir.create("plots")

library(sysfonts)

font_choice <- "Segoe UI"

font_add(font_choice,
         regular = "C:/Windows/Fonts/segoeui.ttf",
         bold = "C:/Windows/Fonts/segoeuib.ttf",
         italic = "C:/Windows/Fonts/segoeuii.ttf")

# Load packages
library(tidyverse)
library(janitor)
library(scales)
library(ggplot2)
library(ggtext)
library(sf)
library(forcats)
# remotes::install_github("mfherman/nycgeo")
library(nycgeo)

# Direct download link for the dataset (5ucz-vwe8)
url <- "https://data.cityofnewyork.us/api/views/5ucz-vwe8/rows.csv?accessType=DOWNLOAD"

shootings_raw <- read_csv(url, na = c("", "NA", "NULL"), show_col_types = FALSE)

shootings <- shootings_raw %>%
    clean_names()

shootings <- shootings %>%
    select(-c(incident_key, jurisdiction_code, location_desc)) %>% 
    mutate(occur_date = mdy(occur_date),
           year = year(occur_date),
           hour = hour(occur_time),
           period_of_day = cut(hour,
                               breaks = c(0, 6, 12, 18, 24),
                               labels = c("Night (00:00-06:00)", "Morning (06:00-12:00)",
                                          "Afternoon (12:00-18:00)", "Evening (18:00-00:00)"),
                               right = FALSE,          # [0,6) = Night, [6,12) = Morning, etc.
                               include.lowest = TRUE),
           boro = as.factor(boro),
           precinct = as.factor(precinct),
           YearMonth = floor_date(occur_date, "month")  # Create a year-month variable for cleaner x-axis
    )

####################################################################################

library(gganimate)

# 1. Make sure geometry is fixed and data is ordered consistently
map_data <- map_data %>%
    arrange(precinct, year)   # Very important for stability

# 2. Create the base plot (stable map)
base_map <- ggplot(map_data) +
    geom_sf(aes(fill = dominant_period, group = precinct),  # group = precinct is key
            color = "white", 
            linewidth = 0.25) +
    
    scale_fill_manual(
        values = c(
            "Morning"      = "#fad510",
            "Afternoon"    = "#e04b28",
            "Evening"      = "#a2c8ec",
            "Night"        = "#2166ac",
            "No Shootings" = "grey85"
        ),
        name = "Dominant Period",
        drop = FALSE
    ) +
    theme_minimal(base_size = 28, base_family = font_choice) +   # ← Much larger for animation
    theme(
        legend.position = c(0, 1),
        legend.justification.inside = c(0, 1),
        legend.text = element_text(size = 20),
        legend.title = element_text(size = 24),
        plot.title = element_text(size = 36, face = "bold", margin = margin(b = 10)),
        plot.caption = element_markdown(hjust = 0, vjust = 0, colour = "grey50",
                                        margin = margin(t = 20), lineheight = 1.25),
        plot.subtitle = element_markdown(hjust = 0, margin = margin(t = 3, b = 20),
                                         size = rel(1), lineheight = 1.2),
        axis.text = element_blank(),
        panel.grid = element_blank()
    ) +
    labs(
        title = "Dominant shooting time period by NYC Police Precinct",
        subtitle = "Year: {closest_state}",
        caption = paste0("<b>Data source</b>: Data: New York City Police Department (NYPD) via NYC Open Data • Shootings 2006–Present (dataset: 5ucz-vwe8)",
                         "<br>",
                         "<b>Notes</b>: Reflects reported shooting incidents (not all gun violence).",
                         "<br>",
                         "<b>Graphic</b>: The Data Decoded / @TheDataDecoded")
    )

# 3. Add animation (only colors change)
animated <- base_map +
    transition_states(year,
                      transition_length = 1,
                      state_length = 5) 

# 4. Render
animate(animated, 
        nframes = length(unique(map_data$year)) * 12, 
        fps = 10,
        width = 2400, 
        height = 2400, 
        res = 130,
        end_pause = 50,
        renderer = gifski_renderer("plots/nyc_shootings_dominant_period_stable.gif"))


##################################################################################
# 1. Get all unique years and precincts
all_years <- tibble(year = unique(shootings$year))

all_precincts <- nyc_boundaries(geography = "police") %>%
    st_set_crs(2263) %>%
    st_transform(4326) %>%
    select(precinct = police_precinct_id, geometry)   # keep only necessary columns

# 2. Create full grid (every precinct × every year)
full_grid <- all_precincts %>%
    crossing(year = all_years$year)

# 3. Calculate dominant period (only where data exists)
dominant_by_year <- shootings %>%
    filter(!is.na(period_of_day), !is.na(precinct)) %>%
    count(year, precinct, period_of_day, name = "n_shootings") %>%
    group_by(year, precinct) %>%
    slice_max(n_shootings, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    rename(dominant_period = period_of_day)

# 4. Join to full grid (NAs will remain for years with zero shootings)
map_data <- full_grid %>%
    left_join(dominant_by_year, by = c("precinct", "year")) %>%
    st_sf()   # Force sf class if needed

map_data <- map_data %>%
    mutate(
        dominant_period = as.character(dominant_period),           # Convert to character first
        dominant_period = replace_na(dominant_period, "No Shootings"),
        dominant_period = factor(dominant_period, 
                                 levels = c("Night (00:00-06:00)", "Morning (06:00-12:00)", 
                                            "Afternoon (12:00-18:00)", "Evening (18:00-00:00)",
                                            "No Shootings"))
    ) %>% 
    filter(!year == 2026)

# Calculate total shootings per year
year_totals <- shootings %>%
    filter(!year == 2026) %>% 
    count(year = year(occur_date), name = "total_shootings") %>%
    mutate(
        label = paste0("N = ", comma(total_shootings))
    )

shootings_period_facet <- ggplot(map_data) +
    geom_sf(aes(fill = dominant_period),
            color = "white", 
            linewidth = 0.2) +
    
    scale_fill_manual(
        values = c(
            "Night (00:00-06:00)"        = "#2166ac",
            "Morning (06:00-12:00)"      = "#fad510",
            "Afternoon (12:00-18:00)"    = "#e04b28",
            "Evening (18:00-00:00)"      = "#a2c8ec",
            "No Shootings" = "grey85"
        ),
        name = "",
        drop = FALSE
    ) +
    
    facet_wrap(~ year, ncol = 5) +
    
    geom_text(data = year_totals,
              aes(x = -Inf, y = 40.81, label = label),
              hjust = 0, vjust = 1.1, 
              size = 3.8, 
              color = "grey20",
              fontface = "plain",
              inherit.aes = FALSE) +
    
    labs(
        title = "Which Time of Day Had the Most Shootings in Each NYC Precinct?",
        subtitle = "By year (2006–2025)",
        caption = paste0("<b>Data source</b>: Data: New York City Police Department (NYPD) via NYC Open Data • Shootings 2006–2025 (dataset: 5ucz-vwe8)",
                         "<br>",
                         "<b>Notes</b>: Reflects reported shooting incidents (not all gun violence). Total number of shootings each year shown inside each map.",
                         "<br>",
                         "<b>Graphic</b>: The Data Decoded / @TheDataDecoded")
    ) +
    # guides(fill = guide_legend(nrow = 3, ncol = 2, theme = theme(legend.byrow = TRUE))) +
    theme_minimal(base_size = 14, base_family = font_choice) +
    theme(
        legend.position = "top",
        # legend.direction = "vertical",
        legend.justification = "left",
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.margin = margin(0, 0, 0, 0),
        strip.text = element_text(face = "bold", size = 14),
        axis.title = element_blank(),
        axis.text = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_blank(),
        plot.margin = margin(r = 28, b = 18, l = 28, t = 18, unit = "pt"),
        plot.title = element_markdown(hjust = 0, face = "bold", margin = margin(b = 5),
                                      lineheight = 1.1, size = rel(1.6)),
        plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_markdown(hjust = 0, vjust = 0, colour = "grey50",
                                        margin = margin(t = 20), lineheight = 1.25),
        plot.subtitle = element_markdown(hjust = 0, margin = margin(t = 3, b = 20),
                                         size = rel(1), lineheight = 1.2)
    )

svg_path <- file.path(project_path, "plots", "shootings_period_of_day.svg")

svg_w <- 10.85
svg_h <- 12

png_w <- 3000
png_h <- round(png_w * svg_h / svg_w)  # keep same aspect ratio

ggsave(svg_path, shootings_period_facet, width = svg_w, height = svg_h, bg = "white")

library(rsvg)

png_path <- file.path(project_path, "plots", "shootings_period_of_day.png")

rsvg_png(
    svg  = svg_path,
    file = png_path,
    width  = png_w,
    height = png_h
)


################

dominant_by_year_bar <- shootings %>%
    count(year, period_of_day, name = "n_shootings") %>% 
    rename(dominant_period = period_of_day)

shootings_period_of_day_bar <- ggplot(data = dominant_by_year_bar %>% filter(! year == 2026),
       aes(x = dominant_period, y = n_shootings, fill = dominant_period)) +
    geom_col() +
    facet_wrap(~ year, ncol = 5) +
    scale_fill_manual(
        values = c(
            "Night (00:00-06:00)"        = "#2166ac",
            "Morning (06:00-12:00)"      = "#fad510",
            "Afternoon (12:00-18:00)"    = "#e04b28",
            "Evening (18:00-00:00)"      = "#a2c8ec",
            "No Shootings" = "grey85"
        ),
        name = "",
        drop = FALSE
    ) +
    scale_y_continuous(breaks = seq(0, 700, 150)) +
    geom_text(aes(x = dominant_period, y = n_shootings + 10, label = n_shootings),
              hjust = 0.5, vjust = 0, 
              size = 3.8, 
              color = "grey20",
              fontface = "plain",
              inherit.aes = FALSE) +
    geom_text(data = year_totals,
              aes(x = 2.5, y = 750, label = label),
              hjust = 0.5, vjust = 1, 
              size = 3.8, 
              color = "grey20",
              fontface = "italic",
              inherit.aes = FALSE) +
    labs(
        title = "Which Time of Day Had the Most Shootings in NYC?",
        subtitle = "By year (2006–2025)",
        caption = paste0("<b>Data source</b>: Data: New York City Police Department (NYPD) via NYC Open Data • Shootings 2006–2025 (dataset: 5ucz-vwe8)",
                         "<br>",
                         "<b>Notes</b>: Reflects reported shooting incidents (not all gun violence). Total number of shootings each year shown inside each map.",
                         "<br>",
                         "<b>Graphic</b>: The Data Decoded / @TheDataDecoded")
    ) +
    coord_cartesian(clip = "off", ylim = c(0, 750)) +
    theme_minimal(base_size = 14, base_family = font_choice) +
    theme(
        legend.position = "top",
        # legend.direction = "vertical",
        legend.justification = "left",
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.margin = margin(0, 0, 0, 0),
        strip.text = element_text(face = "bold", size = 14),
        axis.title = element_blank(),
        axis.text = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.margin = margin(r = 28, b = 18, l = 28, t = 18, unit = "pt"),
        plot.title = element_markdown(hjust = 0, face = "bold", margin = margin(b = 5),
                                      lineheight = 1.1, size = rel(1.6)),
        plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_markdown(hjust = 0, vjust = 0, colour = "grey50",
                                        margin = margin(t = 20), lineheight = 1.25),
        plot.subtitle = element_markdown(hjust = 0, margin = margin(t = 3, b = 20),
                                         size = rel(1), lineheight = 1.2)
    )
    

svg_path <- file.path(project_path, "plots", "shootings_period_of_day_bar.svg")

svg_w <- 10.85
svg_h <- 12

png_w <- 3000
png_h <- round(png_w * svg_h / svg_w)  # keep same aspect ratio

ggsave(svg_path, shootings_period_of_day_bar, width = svg_w, height = svg_h, bg = "white")

library(rsvg)

png_path <- file.path(project_path, "plots", "shootings_period_of_day_bar.png")

rsvg_png(
    svg  = svg_path,
    file = png_path,
    width  = png_w,
    height = png_h
)

changes <- dominant_by_year_bar %>%
                filter(year %in% c(2006, 2025)) %>% 
                group_by(year) %>% 
                mutate(total_shootings = sum(n_shootings),
                       period_of_day_share = (n_shootings / total_shootings) * 100) %>% 
    group_by(dominant_period) %>%
    summarise(
        share_2006 = period_of_day_share[year == 2006],
        share_2025 = period_of_day_share[year == 2025],
        pp_change = share_2025 - share_2006,
        .groups = "drop"
    ) %>%
    mutate(pp_change_label = paste0(ifelse(pp_change >= 0, "+", ""), round(pp_change, 1), " pp")) %>%
    arrange(pp_change)


# Stacked Area Chart - Relative Shares
shootings_period_of_day_area <- ggplot(dominant_by_year_bar %>% filter(! year == 2026),
       aes(x = year, y = n_shootings, fill = dominant_period)) +
    geom_area(position = "fill", alpha = 1) +     # "fill" makes it relative (0-100%)
    
    scale_fill_manual(
        values = c(
            "Morning (06:00-12:00)"   = "#fad510",
            "Afternoon (12:00-18:00)" = "#e04b28",
            "Evening (18:00-00:00)"   = "#a2c8ec",
            "Night (00:00-06:00)"     = "#2166ac"
        ),
        name = "Time of Day"
    ) +
    
    scale_y_continuous(labels = percent_format(),
                       expand = expansion(mult = c(0.015, 0))) +
    scale_x_continuous(breaks = seq(2006, 2025, by = 2),
                       expand = expansion(mult = c(0.015, 0))) +
    
    labs(
        title = "Relative Share of Shootings by Time of Day in NYC",
        subtitle = "Proportion of total shootings per year in NYC (2006–2025)",
        x = NULL,
        y = "Share of Total Shootings",
        caption = paste0("<b>Data source</b>: Data: New York City Police Department (NYPD) via NYC Open Data • Shootings 2006–2025 (dataset: 5ucz-vwe8)",
                         "<br>",
                         "<b>Notes</b>: Reflects reported shooting incidents (not all gun violence).",
                         "<br>",
                         "<b>Graphic</b>: The Data Decoded / @TheDataDecoded")
    ) +
    coord_cartesian(clip = "off") +
    theme_minimal(base_size = 14, base_family = font_choice) +
    theme(
        legend.position = "top",
        legend.justification = c(0.47, 0.5),     # ← This is the key fix
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.margin = margin(0, 0, 0, 0),
        axis.title = element_blank(),
        # axis.text = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        plot.margin = margin(r = 155, b = 18, l = 28, t = 18, unit = "pt"),
        plot.title = element_markdown(hjust = 0, face = "bold", margin = margin(b = 5),
                                      lineheight = 1.1, size = rel(1.6)),
        plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_markdown(hjust = 0, vjust = 0, colour = "grey50",
                                        margin = margin(t = 20), lineheight = 1.25),
        plot.subtitle = element_markdown(hjust = 0, margin = margin(t = 3, b = 20),
                                         size = rel(1), lineheight = 1.2)
    ) +
    annotate("text", 
             x = 2025.4, y = 0.88, 
             label = paste0("Decreasing\nshare of NIGHT\nshootings (",  changes[str_starts(changes$dominant_period, "Night"), "pp_change_label"], ")"), 
             color = "#2166ac", size = 4.5, hjust = 0, lineheight = 0.9, vjust = 0.5,
             family = font_choice, fontface = "bold") +
    annotate("text", 
             x = 2025.4, y = 0.53, 
             label = paste0("Increasing share\nof AFTERNOON\nshootings (", changes[str_starts(changes$dominant_period, "Afternoon"), "pp_change_label"], ")"), 
             color = "#e04b28", size = 4.5, hjust = 0, lineheight = 0.9, vjust = 0.5,
             family = font_choice, fontface = "bold") +
    annotate("text", 
             x = 2025.4, y = 0.73, 
             label = paste0("Stable share of\nMORNING shootings\n", changes[str_starts(changes$dominant_period, "Morning"), "pp_change_label"]), 
             color = "#E1BF0E", size = 4.5, hjust = 0, lineheight = 0.9, vjust = 0.5,
             family = font_choice, fontface = "bold") +
    annotate("text", 
             x = 2025.4, y = 0.22, 
             label = paste0("Stable share of\nEVENING shootings\n", changes[str_starts(changes$dominant_period, "Evening"), "pp_change_label"]), 
             color = "#92B4D4", size = 4.5, hjust = 0, lineheight = 0.9, vjust = 0.5,
             family = font_choice, fontface = "bold")
    
svg_path <- file.path(project_path, "plots", "shootings_period_of_day_area.svg")

svg_w <- 10
svg_h <- 10

png_w <- 3000
png_h <- round(png_w * svg_h / svg_w)  # keep same aspect ratio

ggsave(svg_path, shootings_period_of_day_area, width = svg_w, height = svg_h, bg = "white")

library(rsvg)

png_path <- file.path(project_path, "plots", "shootings_period_of_day_area.png")

rsvg_png(
    svg  = svg_path,
    file = png_path,
    width  = png_w,
    height = png_h
)

#########################

# Calculate shooting by month for each year (multiple lines)
shootings_by_month <- shootings %>%
    count(year, YearMonth, name = "shootings") %>% 
    mutate(month = month(YearMonth, label = TRUE))

text_annotations <- shootings_by_month %>% 
    filter(year %in% c(2020, 2021, 2025) & month %in% c("Dec")) %>% 
    mutate(shootings = case_when(
        year == 2020 ~ shootings - 3.1,
        year == 2021 ~ shootings + 3.1,
        .default = shootings
    ))

shootings_year <- ggplot(shootings_by_month,
       aes(x = month, y = shootings, group = year)) +
    geom_hline(yintercept = 0, color = "grey30") +
    geom_line(data = . %>% filter(! year %in% c(2020, 2021, 2025, 2026)),
              color = "grey85") +
    geom_line(data = . %>% filter(year == 2020),
              color = "tomato4", linewidth = 1) +
    geom_line(data = . %>% filter(year == 2025),
              color = "blue3", linewidth = 1) +
    geom_line(data = . %>% filter(year == 2021),
              color = "green4", linewidth = 1) +
    geom_point(data = . %>% filter(year %in% c(2020, 2021, 2025) & month %in% c("Dec")),
               aes(x = month, y = shootings),
               color = c("tomato4", "green4", "blue3")) +
    labs(
        title = paste0("NYC shootings surged in <span style='color: tomato4;'>2020</span>-<span style='color: green4;'>2021</span> amid pandemic disruptions",
                       "<br>",
                       "and social unrest, then fell to lowest level in decades in <span style='color: blue3;'>2025</span>"),
        subtitle = "NYC shootings by month and year, 2006-2025",
        caption = paste0("<b>Data source</b>: Data: New York City Police Department (NYPD) via NYC Open Data • Shootings 2006–Present (dataset: 5ucz-vwe8)",
                         "<br>",
                         "<b>Notes</b>: Reflects reported shooting incidents (not all gun violence).",
                         "<br>",
                         "<b>Graphic</b>: The Data Decoded / @TheDataDecoded")
    ) +
    coord_cartesian(clip = "off") +
    scale_x_discrete(expand = expansion(mult = c(0.01, 0))) +
    scale_y_continuous(breaks = seq(0, 250, 50),
                       labels = comma,
                       limits = c(0, 250),
                       expand = expansion(mult = c(0.015, 0.015))) +
    scale_color_identity() +
    geom_text(data = text_annotations,
              aes(x = month, y = shootings, label = year),
              color = c("tomato4", "green4", "blue3"),
              fontface = "bold",
              size = 4.5,
              hjust = -0.2,
              inherit.aes = FALSE) +
    theme_minimal(base_size = 14, base_family = font_choice) +
    theme(
        axis.title = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.y = element_line(linetype = 2),
        panel.grid.major.x = element_blank(),
        plot.margin = margin(r = 65, b = 18, l = 18, t = 18, unit = "pt"),
        plot.title = element_markdown(hjust = 0, face = "bold", margin = margin(b = 5),
                                      lineheight = 1.1, size = rel(1.6)),
        plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_markdown(hjust = 0, vjust = 0, colour = "grey50",
                                        margin = margin(t = 20), lineheight = 1.25),
        plot.subtitle = element_markdown(hjust = 0, margin = margin(t = 3, b = 20),
                                         size = rel(1), lineheight = 1.2)
    )

svg_path <- file.path(project_path, "plots", "shootings_year.svg")

svg_w <- 10
svg_h <- 10

png_w <- 3000
png_h <- round(png_w * svg_h / svg_w)  # keep same aspect ratio

ggsave(svg_path, shootings_year, width = svg_w, height = svg_h, bg = "white")

library(rsvg)

png_path <- file.path(project_path, "plots", "shootings_year.png")

rsvg_png(
    svg  = svg_path,
    file = png_path,
    width  = png_w,
    height = png_h
)


##########################################################################################################
# 1. Daily counts
daily_counts <- shootings %>%
    count(year = year(occur_date), 
          date = occur_date, 
          name = "daily_count")

# 2. Create full daily calendar per year (bulletproof method)
full_calendar <- daily_counts %>%
    group_by(year) %>%
    summarise(
        start_date = as.Date(paste0(year[1], "-01-01")),
        end_date   = as.Date(paste0(year[1], "-12-31")),
        .groups = "drop"
    ) %>%
    rowwise() %>%
    mutate(
        date = list(seq.Date(start_date, end_date, by = "day"))
    ) %>%
    unnest(date) %>%
    select(year, date) %>% 
    filter(date <= as.Date("2026-03-31"))

# 3. Join + cumulative
cumulative_daily <- full_calendar %>%
    left_join(daily_counts, by = c("year", "date")) %>%
    mutate(daily_count = replace_na(daily_count, 0)) %>%
    group_by(year) %>%
    arrange(date) %>%
    mutate(cumulative_shootings = cumsum(daily_count)) %>%
    ungroup()

# 4. Monthly summary for plotting
cumulative_monthly <- cumulative_daily %>%
    mutate(month = month(date, label = TRUE, abbr = TRUE)) %>%
    group_by(year, month) %>%
    summarise(
        cumulative_shootings = max(cumulative_shootings),
        .groups = "drop"
    )

text_annotations <- cumulative_monthly %>% 
    filter(year %in% c(2020, 2021, 2025) & month %in% c("Dec")) %>% 
    mutate(cumulative_shootings = case_when(
               year == 2020 ~ cumulative_shootings - 10,
               year == 2021 ~ cumulative_shootings + 10,
               .default = cumulative_shootings
           ))

segment_annotations <- tibble(x = c(3, 5, 12, 12),
                              y = c(700, 1200, 320, 1725),
                              xend = c(3, 5, 12, 12),
                              yend = c(cumulative_monthly %>% filter(year == 2020 & month == "Mar") %>% pull(cumulative_shootings),
                                       cumulative_monthly %>% filter(year == 2020 & month == "May") %>% pull(cumulative_shootings),
                                       cumulative_monthly %>% filter(year == 2025 & month == "Dec") %>% pull(cumulative_shootings),
                                       cumulative_monthly %>% filter(year == 2021 & month == "Dec") %>% pull(cumulative_shootings)))

# 5. Final Plot
cum_shootings <- ggplot(cumulative_monthly, aes(x = month, y = cumulative_shootings, 
                               group = year, color = factor(year))) +
    geom_hline(yintercept = 0, color = "grey30") +
    geom_line(data = . %>% filter(! year %in% c(2020, 2025)),
              color = "grey85") +
    geom_line(data = . %>% filter(year == 2020),
              color = "tomato4", linewidth = 1) +
    geom_point(data = . %>% filter(year %in% c(2020) & month %in% c("Mar", "May")),
               aes(x = month, y = cumulative_shootings),
               color = "tomato4") +
    geom_line(data = . %>% filter(year == 2025),
              color = "blue3", linewidth = 1) +
    geom_line(data = . %>% filter(year == 2021),
              color = "green4", linewidth = 1) +
    geom_point(data = . %>% filter(year %in% c(2020, 2021, 2025) & month %in% c("Dec")),
               aes(x = month, y = cumulative_shootings),
               color = c("tomato4", "green4", "blue3")) +
    geom_segment(data = segment_annotations,
                 aes(x = x, xend = xend, y = y, yend = yend),
                 inherit.aes = FALSE, linejoin = "round", lineend = "round",
                 color = c(rep("tomato4", 2), "blue3", "green4"),
                 linewidth = 0.55, linetype = "63") +
    scale_x_discrete(expand = expansion(mult = c(0.01, 0))) +
    scale_y_continuous(breaks = seq(0, 1750, 250),
                       labels = comma,
                       limits = c(0, 1750),
                       expand = expansion(mult = c(0.015, 0.015))) +
    scale_color_identity() +
    geom_text(data = text_annotations,
              aes(x = month, y = cumulative_shootings, label = year),
              color = c("tomato4", "green4", "blue3"),
              fontface = "bold",
              size = 4.5,
              hjust = -0.2,
              inherit.aes = FALSE) +
    labs(
        title = paste0("NYC shootings surged in <span style='color: tomato4;'>2020</span>-<span style='color: green4;'>2021</span> amid pandemic disruptions",
                       "<br>",
                       "and social unrest, then fell to lowest level in decades in <span style='color: blue3;'>2025</span>"),
        subtitle = "Cumulative NYC shootings by month and year, 2006-2025",
        caption = paste0("<b>Data source</b>: Data: New York City Police Department (NYPD) via NYC Open Data • Shootings 2006–Present (dataset: 5ucz-vwe8)",
                         "<br>",
                         "<b>Notes</b>: Reflects reported shooting incidents (not all gun violence).",
                         "<br>",
                         "<b>Graphic</b>: The Data Decoded / @TheDataDecoded")
    ) +
    coord_cartesian(clip = "off") +
    theme_minimal(base_size = 14, base_family = font_choice) +
    theme(
        axis.title = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.y = element_line(linetype = 2),
        panel.grid.major.x = element_blank(),
        plot.margin = margin(r = 65, b = 18, l = 18, t = 18, unit = "pt"),
        plot.title = element_markdown(hjust = 0, face = "bold", margin = margin(b = 5),
                                      lineheight = 1.1, size = rel(1.6)),
        plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_markdown(hjust = 0, vjust = 0, colour = "grey50",
                                        margin = margin(t = 20), lineheight = 1.25),
        plot.subtitle = element_markdown(hjust = 0, margin = margin(t = 3, b = 20),
                                         size = rel(1), lineheight = 1.2)
    ) +
    annotate("text", 
               x = 3.1, y = 625, 
               label = "COVID-19\nlockdown\n(Mar 22, 2020)", 
               color = "tomato4", size = 4.5, hjust = 0, lineheight = 0.9, vjust = 0.5,
             family = font_choice) +
    
    annotate("text", 
             x = 5.1, y = 1125, 
             label = "George Floyd killed,\ntrigerring widespread\nprotests (May 25, 2020)", 
             color = "tomato4", size = 4.5, hjust = 0, lineheight = 0.9, vjust = 0.5,
             family = font_choice) +
    annotate("text", 
             x = 11.9, y = 375, 
             label = "Lowest shootings\nin decades (2025)", 
             color = "blue3", size = 4.5, hjust = 1, lineheight = 0.9, vjust = 0.5,
             family = font_choice) +
    annotate("text", 
             x = 11.9, y = 1725, 
             label = "Record number of\nshootings (2021)",
             color = "green4", size = 4.5, hjust = 1, lineheight = 0.9, vjust = 1,
             family = font_choice)

svg_path <- file.path(project_path, "plots", "cumulative_shootings_year.svg")

svg_w <- 10
svg_h <- 10

png_w <- 3000
png_h <- round(png_w * svg_h / svg_w)  # keep same aspect ratio

ggsave(svg_path, cum_shootings, width = svg_w, height = svg_h, bg = "white")

library(rsvg)

png_path <- file.path(project_path, "plots", "cumulative_shootings_year.png")

rsvg_png(
    svg  = svg_path,
    file = png_path,
    width  = png_w,
    height = png_h
)

##################################################################################

# Gini coefficient function
calculate_gini <- function(x) {
    x <- na.omit(x)
    if (length(x) < 2) return(NA_real_)
    x <- sort(x)                    # must be sorted
    n <- length(x)
    (2 * sum(x * (1:n)) / (n * sum(x))) - (n + 1) / n
}

gini_by_year <- shootings %>%
    # Count shootings per precinct per year
    count(year = year(occur_date), precinct, name = "shootings") %>%
    
    # For each year, get the vector of shootings per precinct
    group_by(year) %>%
    summarise(
        gini = calculate_gini(shootings),
        n_precincts = n(),
        total_shootings = sum(shootings),
        .groups = "drop"
    ) %>%
    arrange(year)

# View the results
print(gini_by_year, n = Inf)

ggplot(gini_by_year %>% filter(!year == 2026),
       aes(x = year, y = gini)) +
    geom_line(linewidth = 1, color = "#d73027") +
    geom_smooth() +
    scale_y_continuous(
        limits = c(0.3, 0.6),
        labels = scales::percent_format(accuracy = 1),
        breaks = seq(0.3, 0.6, by = 0.1)
    ) +
    labs(
        title = "Inequality in NYC Shootings Across Police Precincts",
        subtitle = "Gini coefficient by year (0 = perfect equality • 1 = perfect concentration)",
        x = NULL,
        y = "Gini Coefficient",
        caption = "Data: NYC Open Data • Shootings 2006–Present (dataset 5ucz-vwe8)\nHigher Gini = shootings are more concentrated in fewer precincts"
    ) +
    theme_minimal(base_size = 14) +
    theme(
        plot.title = element_text(face = "bold", size = 18),
        plot.subtitle = element_text(size = 13)
    )


###############################################################

# 1. Create Lorenz data for ALL years
lorenz_data <- shootings %>%
    count(year = year(occur_date), precinct, name = "shootings") %>%
    group_by(year) %>%
    arrange(shootings) %>%
    mutate(
        precinct_rank = row_number() / n(),                    # % of precincts
        cum_shootings = cumsum(shootings) / sum(shootings)     # % of shootings
    ) %>%
    ungroup()

# 2. Add color grouping
lorenz_data <- lorenz_data %>%
    mutate(
        highlight = case_when(
            year %in% c(2020, 2021, 2025) ~ as.character(year),
            TRUE ~ "Other Years"
        )
    )

# 3. Plot
ggplot(lorenz_data, aes(x = precinct_rank, y = cum_shootings, 
                        color = highlight, group = year)) +
    
    # All other years in light grey
    geom_line(data = . %>% filter(highlight == "Other Years"),
              linewidth = 0.65, alpha = 0.7, color = "grey70") +
    
    # Highlighted years with thicker, colored lines
    geom_line(data = . %>% filter(highlight != "Other Years"),
              linewidth = 1.25, alpha = 0.95) +
    
    geom_abline(intercept = 0, slope = 1, 
                linetype = "dashed", color = "grey40", linewidth = 0.8) +
    
    scale_color_manual(
        values = c(
            "Other Years" = "grey70",
            "2020" = "#d73027",   # Red
            "2021" = "#f46d43",   # Orange
            "2025" = "#2166ac"    # Blue
        ),
        name = "Year"
    ) +
    
    scale_x_continuous(labels = percent_format()) +
    scale_y_continuous(labels = percent_format()) +
    
    labs(
        title = "Lorenz Curves: Concentration of Shootings Across NYC Precincts",
        subtitle = "Grey lines = other years | Highlighted: 2020, 2021, and 2025",
        x = "Cumulative Share of Precincts (sorted by shootings)",
        y = "Cumulative Share of Shootings",
        caption = "Data: NYC Open Data • Shootings 2006–Present (dataset 5ucz-vwe8)"
    ) +
    theme_minimal(base_size = 14) +
    theme(
        plot.title = element_text(face = "bold", size = 18),
        plot.subtitle = element_text(size = 13),
        legend.position = "right"
    ) +
    annotate("text", x = 0.65, y = 0.22, 
             label = "Line of Perfect Equality", 
             color = "grey50", size = 4)


#################################################################################

top_share_by_year <- shootings %>%
    count(year = year(occur_date), precinct, name = "shootings") %>%
    group_by(year) %>%
    arrange(desc(shootings)) %>%
    mutate(
        total_shootings = sum(shootings),
        cum_shootings = cumsum(shootings),
        pct_of_total = cum_shootings / total_shootings,
        precinct_rank = row_number(),
        top_pct = precinct_rank / n() * 100          # cumulative % of precincts
    ) %>%
    ungroup()

top_x_share <- top_share_by_year %>%
    filter(top_pct <= 25) %>%                      # Look within top 25% of precincts
    group_by(year) %>%
    summarise(
        top_5_precincts_pct   = max(pct_of_total[precinct_rank <= 5], na.rm = TRUE),
        top_10_precincts_pct  = max(pct_of_total[precinct_rank <= 10], na.rm = TRUE),
        top_20_precincts_pct = max(pct_of_total[top_pct <= 20], na.rm = TRUE),
        top_50_precincts_pct = max(pct_of_total[top_pct <= 50], na.rm = TRUE),
        .groups = "drop"
    ) %>% 
    filter(! year == 2026)

print(top_x_share)

ggplot(top_x_share, aes(x = year)) +
    geom_line(aes(y = top_5_precincts_pct), color = "black", linewidth = 1) +
    # geom_point(aes(y = top_5_precincts_pct), color = "black", size = 3) +
    
    geom_line(aes(y = top_10_precincts_pct), color = "tomato4", linewidth = 1) +
    # geom_point(aes(y = top_10_precincts_pct), color = "tomato4", size = 3) +
    
    geom_line(aes(y = top_20_precincts_pct), color = "#d73027", linewidth = 1) +
    # geom_point(aes(y = top_20_precincts_pct), color = "#d73027", size = 3) +
    
    geom_line(aes(y = top_50_precincts_pct), color = "#f46d43", linewidth = 1, alpha = 0.9) +
    # geom_point(aes(y = top_50_precincts_pct), color = "#f46d43", size = 2.5) +
    
    scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0.2, 0.8)) +
    labs(
        title = "Concentration of NYC Shootings in Top Precincts",
        subtitle = "Share of total annual shootings held by the Top 10 and Top 20% of precincts",
        x = NULL,
        y = "% of All Shootings",
        caption = "Data: NYC Open Data • Shootings 2006–Present (dataset 5ucz-vwe8)"
    ) +
    theme_minimal(base_size = 14) +
    theme(
        plot.title = element_text(face = "bold", size = 18),
        legend.position = "top"
    ) +
    annotate("text", x = 2018, y = 0.62, label = "Top 10 Precincts", color = "#d73027", size = 4.5, fontface = "bold") +
    annotate("text", x = 2018, y = 0.48, label = "Top 20% of Precincts", color = "#f46d43", size = 4, fontface = "bold")


#################################################################################


# 1. Create reverse cumulative distribution (highest to lowest)
reverse_cum_dist <- shootings %>%
    count(precinct, name = "shootings") %>%
    arrange(desc(shootings)) %>%                    # ← Sort from highest to lowest
    mutate(
        precinct_rank = row_number() / n(),           # Cumulative % of precincts
        cum_shootings = cumsum(shootings) / sum(shootings)  # Cumulative % of shootings
    )

red_segments <- tibble(x = c(0.1, 0.2, 0.3, 0.1, 0.2, 0.3),
                       y = c(0, 0, 0, 0.33, 0.548, 0.697),
                       xend = c(0.1, 0.2, 0.3, 0, 0, 0),
                       yend = rep(c(0.33, 0.548, 0.697), 2))

# 2. Plot
cum_shootings_district <- ggplot(reverse_cum_dist, aes(x = precinct_rank, y = cum_shootings)) +
    annotate("segment", x = 0, y = 0, xend = 1, yend = 1, color = "grey30", linetype = 1) +
    geom_line(color = "#a22623", linewidth = 1.2) +
    geom_vline(xintercept = 0, color = "grey30") +
    geom_hline(yintercept = 0, color = "grey30") +
    # annotate("rect", xmin = 0, xmax = 0.1, ymin = 0, ymax = 0.33, fill = alpha("#a22623", 0.15)) +
    # annotate("rect", xmin = 0, xmax = 0.2, ymin = 0, ymax = 0.548, fill = alpha("#a22623", 0.15)) +
    annotate("rect", xmin = 0, xmax = 0.3, ymin = 0, ymax = 0.697, fill = alpha("#a22623", 0.15)) +
    geom_segment(data = red_segments,
                 aes(x = x, y = y, xend = xend, yend = yend), color = "#a22623", linetype = 2) +
    # Key highlight points
    # geom_point(data = reverse_cum_dist %>% filter(abs(precinct_rank - 0.10) == min(abs(precinct_rank - 0.10))),
    #            color = "#a22623", size = 2.5) +
    # geom_point(data = reverse_cum_dist %>% filter(abs(precinct_rank - 0.20) == min(abs(precinct_rank - 0.20))),
    #            color = "#a22623", size = 2.5) +
    
    geom_point(data = tibble(x = 0.1, y = 0.33), aes(x = x, y = y),
               color = "#a22623", size = 2.5, inherit.aes = FALSE) +
    geom_point(data = tibble(x = 0.2, y = 0.548), aes(x = x, y = y),
               color = "#a22623", size = 2.5) +
    geom_point(data = tibble(x = 0.3, y = 0.697), aes(x = x, y = y),
               color = "#a22623", size = 2.5) +
    
    # Annotations
    annotate("text", x = 0.12, y = 0.33, 
             label = "Top 10% of precincts\naccount for ~33% of\nshootings", 
             hjust = 0, size = 4.2, lineheight = 0.95, color = "grey20") +
    
    annotate("text", x = 0.22, y = 0.548, 
             label = "Top 20% of precincts\naccount for ~55% of\nshootings", 
             hjust = 0, size = 4.2, lineheight = 0.95, color = "grey20") +
    annotate("text", x = 0.32, y = 0.697, 
             label = "Top 30% of precincts\naccount for ~70% of\nshootings", 
             hjust = 0, size = 4.2, lineheight = 0.95, color = "grey20") +
    
    scale_x_continuous(labels = percent_format(),
                       limits = c(0, 1),
                       breaks = seq(0, 1, 0.1),
                       expand = expansion(mult = c(0.02, 0.005))) +
    scale_y_continuous(labels = percent_format(),
                       limits = c(0, 1),
                       breaks = seq(0, 1, 0.1),
                       expand = expansion(mult = c(0.02, 0.005))) +
    
    labs(
        title = "30% of NYC precincts account for 70% of shootings",
        subtitle = "Cumulative share starting from the precincts with the highest number of shootings",
        x = "Top X% of precincts (ranked from highest to lowest shootings)",
        y = "Cumulative share of all shootings",
        caption = paste0("<b>Data source</b>: Data: New York City Police Department (NYPD) via NYC Open Data • Shootings 2006–Present (dataset: 5ucz-vwe8)",
                         "<br>",
                         "<b>Notes</b>: Reflects reported shooting incidents (not all gun violence).",
                         "<br>",
                         "<b>Graphic</b>: The Data Decoded / @TheDataDecoded")
    ) +
    theme_minimal(base_size = 14, base_family = font_choice) +
    theme(
        # axis.title = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(linetype = 1),
        plot.margin = margin(r = 65, b = 18, l = 18, t = 18, unit = "pt"),
        plot.title = element_markdown(hjust = 0, face = "bold", margin = margin(b = 5),
                                      lineheight = 1.1, size = rel(1.6)),
        plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.caption = element_markdown(hjust = 0, vjust = 0, colour = "grey50",
                                        margin = margin(t = 20), lineheight = 1.25),
        plot.subtitle = element_markdown(hjust = 0, margin = margin(t = 3, b = 20),
                                         size = rel(1), lineheight = 1.2)
    )


svg_path <- file.path(project_path, "plots", "cumulative_shootings_district.svg")

svg_w <- 10
svg_h <- 10

png_w <- 3000
png_h <- round(png_w * svg_h / svg_w)  # keep same aspect ratio

ggsave(svg_path, cum_shootings_district, width = svg_w, height = svg_h, bg = "white")

library(rsvg)

png_path <- file.path(project_path, "plots", "cumulative_shootings_district.png")

rsvg_png(
    svg  = svg_path,
    file = png_path,
    width  = png_w,
    height = png_h
)