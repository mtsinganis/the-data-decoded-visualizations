#!/usr/bin/env Rscript
# Local synthetic chart-frame exploration. No project analysis or historical export is read.
required <- c("ggplot2", "ragg", "svglite", "systemfonts", "jsonlite", "base64enc", "rsvg", "png")
missing_packages <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages)) stop("Missing R packages: ", paste(missing_packages, collapse = ", "))

file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
if (length(file_arg) != 1) stop("Run with Rscript brand-exploration/r-prototypes/render.R")
here <- dirname(normalizePath(sub("^--file=", "", file_arg)))
study <- normalizePath(file.path(here, ".."))
font_dir <- Sys.getenv("TDD_FONT_DIR", unset = file.path(study, "fonts"))
font_files <- file.path(font_dir, paste0("WorkSans-", c("Regular", "Medium", "Bold"), ".ttf"))
if (any(!file.exists(font_files))) stop("Required pinned Work Sans font file is missing: ", paste(font_files[!file.exists(font_files)], collapse = ", "))
font_info <- lapply(font_files, function(path) systemfonts::font_info(path = path))
for (i in seq_along(font_info)) {
  if (font_info[[i]]$family[[1]] != "Work Sans") stop("Unexpected font family in ", font_files[[i]])
}
systemfonts::register_font("TDD Work Sans", plain = font_files[[1]], bold = font_files[[3]])
systemfonts::register_font("TDD Work Sans Medium", plain = font_files[[2]])
expected <- normalizePath(font_files)
resolved <- c(
  systemfonts::match_fonts("TDD Work Sans")$path[[1]],
  systemfonts::match_fonts("TDD Work Sans Medium")$path[[1]],
  systemfonts::match_fonts("TDD Work Sans", weight = "bold")$path[[1]]
)
if (!identical(normalizePath(resolved), expected)) stop("Work Sans registration resolved to a substitute font")

pal <- jsonlite::fromJSON(file.path(study, "palette.json"))
if (!identical(pal$brandBlue, "#2455FF")) stop("Unexpected brand blue")
categorical <- function(choice) {
  if (choice == "A") {
    values <- pal$categoricalBase
    values[[4]] <- pal$warmAccentCandidates$crimson
  } else if (choice == "B") {
    values <- pal$categoricalB
  } else stop("Unknown categorical choice: ", choice)
  unname(values)
}
if (!identical(pal$recommendedAccent, "crimson")) stop("Unexpected recommended categorical accent")
if (!identical(pal$recommendedCategorical, "B")) stop("Unexpected recommended categorical choice")

paper <- pal$paper
ink <- pal$ink
blue <- pal$brandBlue
regular <- "TDD Work Sans"
medium <- "TDD Work Sans Medium"
relative_luminance <- function(hex) {
  channel <- grDevices::col2rgb(hex)[, 1] / 255
  linear <- ifelse(channel <= .04045, channel / 12.92, ((channel + .055) / 1.055)^2.4)
  sum(linear * c(.2126, .7152, .0722))
}
contrast <- function(a, b) {
  values <- sort(c(relative_luminance(a), relative_luminance(b)), decreasing = TRUE)
  (values[[1]] + .05) / (values[[2]] + .05)
}
label_color <- function(fill) {
  scores <- c(ink = contrast(fill, ink), white = contrast(fill, "#FFFFFF"))
  if (max(scores) < 4.5) return(NA_character_)
  if (which.max(scores) == 1) ink else "#FFFFFF"
}

# The small chart signature uses the lightly simplified mark. It is rasterized
# inside the R devices; all plotted geometry and text remain SVG vectors.
logo_source <- paste(readLines(file.path(study, "pterosaur-simplified.svg"), warn = FALSE), collapse = "\n")
viewbox <- regmatches(logo_source, regexec('viewBox="[0-9.]+ [0-9.]+ ([0-9.]+) ([0-9.]+)"', logo_source))[[1]]
if (length(viewbox) != 3) stop("Could not read simplified logo viewBox")
logo_ratio <- as.numeric(viewbox[[2]]) / as.numeric(viewbox[[3]])
logo_width <- grid::unit(0.60, "in")
logo_height <- grid::unit(0.60 / logo_ratio, "in")
raster_width <- 366L
logo_png <- rsvg::rsvg_png(charToRaw(logo_source), width = raster_width,
  height = as.integer(round(raster_width / logo_ratio)))
logo_raster <- png::readPNG(logo_png, native = TRUE)

base_plot <- function() {
  ggplot2::theme_minimal(base_family = regular, base_size = 15) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = paper, colour = NA),
      panel.background = ggplot2::element_rect(fill = paper, colour = NA),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "#D7D9D7", linewidth = 0.25),
      text = ggplot2::element_text(family = regular, colour = ink),
      axis.text = ggplot2::element_text(family = regular, colour = ink, size = 14),
      axis.title = ggplot2::element_text(family = regular, colour = ink, size = 14),
      legend.position = "none",
      plot.margin = ggplot2::margin(12, 15, 12, 10)
    )
}

regions <- data.frame(
  region = factor(paste("Region", LETTERS[1:5]), levels = rev(paste("Region", LETTERS[1:5]))),
  change = c(28, 24, 19, 13, 8),
  focus = c(TRUE, rep(FALSE, 4))
)
ranked <- ggplot2::ggplot(regions, ggplot2::aes(x = change, y = region)) +
  ggplot2::geom_col(ggplot2::aes(fill = focus), width = 0.56, show.legend = FALSE) +
  ggplot2::geom_text(ggplot2::aes(label = change), hjust = -0.35, family = medium,
    colour = ink, size = 5.4) +
  ggplot2::scale_fill_manual(values = c("TRUE" = blue, "FALSE" = pal$context[[2]])) +
  ggplot2::scale_x_continuous(limits = c(0, 33), breaks = c(0, 10, 20, 30), expand = c(0, 0)) +
  ggplot2::labs(x = "Index-point change", y = NULL) + base_plot()

series <- expand.grid(period = 1:6, group = paste0("S", 1:8), KEEP.OUT.ATTRS = FALSE)
series$group <- factor(series$group, levels = paste0("S", 1:8))
series$id <- as.integer(series$group)
series$value <- 6 + series$id * 8 + c(0, 3, -1, 5, 4, 9)[series$period] + (series$id %% 3) * series$period * 0.35
end_labels <- subset(series, period == 6)
make_series <- function(choice) {
  ggplot2::ggplot(series, ggplot2::aes(x = period, y = value, group = group, colour = group, linetype = group)) +
    ggplot2::geom_line(linewidth = 1.05) +
    ggplot2::geom_text(data = end_labels, ggplot2::aes(label = group), x = 6.28,
      hjust = 0, family = medium, colour = ink, size = 4.2, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = categorical(choice)) +
    ggplot2::scale_linetype_manual(values = c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash", "solid", "dashed")) +
    ggplot2::scale_x_continuous(limits = c(1, 6.85), breaks = 1:6, expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(10, 90), breaks = c(20, 40, 60, 80)) +
    ggplot2::labs(x = "Sample period", y = "Synthetic index") + base_plot()
}

heat <- expand.grid(column = LETTERS[1:5], row = paste0("R", 1:6), KEEP.OUT.ATTRS = FALSE)
heat$value <- c(5, 12, 0, 8, 20, 28, 18, 32, 35, 42, 51, 57, 60, 68, 74,
  71, 80, 75, 86, 89, 77, 86, 75, 88, 93, 91, 95, 97, 100, 99)
heat$row <- factor(heat$row, levels = rev(paste0("R", 1:6)))
heat$fill_hex <- scales::gradient_n_pal(pal$sequential)(heat$value / 100)
heat$label_colour <- vapply(heat$fill_hex, label_color, character(1))
if (anyNA(heat$label_colour)) stop("Heatmap cell needs an adjusted fill or an outside label")
heatmap_plot <- ggplot2::ggplot(heat, ggplot2::aes(x = column, y = row, fill = value)) +
  ggplot2::geom_tile(colour = paper, linewidth = 1.5) +
  ggplot2::geom_text(ggplot2::aes(label = value, colour = label_colour), family = medium, size = 5.1) +
  ggplot2::scale_colour_identity() +
  ggplot2::scale_fill_gradientn(colours = pal$sequential, limits = c(0, 100),
    breaks = c(0, 25, 50, 75, 100),
    guide = ggplot2::guide_colourbar(title = "Synthetic intensity", direction = "horizontal",
      barwidth = grid::unit(3.3, "in"), barheight = grid::unit(0.16, "in"))) +
  ggplot2::labs(x = "Sample column", y = NULL) +
  ggplot2::coord_equal() + base_plot() +
  ggplot2::theme(panel.grid = ggplot2::element_blank(), legend.position = "bottom",
    legend.title = ggplot2::element_text(family = regular, colour = ink, size = 13),
    legend.text = ggplot2::element_text(family = regular, colour = ink, size = 12))

# All values below are synthetic; these plots exercise the single adaptive frame.
facets <- expand.grid(step = 1:6, series = paste0("S", 1:4), panel = paste("Panel", LETTERS[1:4]),
  KEEP.OUT.ATTRS = FALSE)
facets$series <- factor(facets$series, levels = paste0("S", 1:4))
facets$value <- 8 + as.integer(facets$series) * 5 + facets$step * (1 + as.integer(factor(facets$panel)) * 0.4) +
  c(0, 2, -1, 3, 1, 4)[facets$step]
multi_plot <- ggplot2::ggplot(facets, ggplot2::aes(step, value,
  group = series, colour = series, linetype = series)) +
  ggplot2::geom_line(linewidth = 0.9) +
  ggplot2::facet_wrap(~panel, ncol = 2) +
  ggplot2::scale_colour_manual(values = categorical(pal$recommendedCategorical)[1:4]) +
  ggplot2::scale_linetype_manual(values = c("solid", "dashed", "dotted", "dotdash")) +
  ggplot2::scale_x_continuous(breaks = 1:6) +
  ggplot2::labs(x = "Synthetic period", y = "Synthetic index") + base_plot() +
  ggplot2::theme(legend.position = "bottom", legend.title = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(family = medium, colour = ink, size = 14),
    legend.text = ggplot2::element_text(family = regular, colour = ink, size = 12))

tall_data <- data.frame(region = factor(paste("Region", LETTERS[1:10]),
  levels = rev(paste("Region", LETTERS[1:10]))),
  value = c(31, 28, 26, 23, 21, 18, 16, 13, 11, 8))
tall_data$focus <- tall_data$region %in% c("Region A", "Region D")
tall_plot <- ggplot2::ggplot(tall_data, ggplot2::aes(value, region)) +
  ggplot2::geom_col(ggplot2::aes(fill = focus), width = .63, show.legend = FALSE) +
  ggplot2::geom_text(ggplot2::aes(label = value), hjust = -0.32,
    family = medium, colour = ink, size = 4.7) +
  ggplot2::annotate("text", x = 37, y = 10, label = "Focus A:\nillustrative peak",
    hjust = 0, family = regular, colour = ink, size = 4.3, lineheight = 1.1) +
  ggplot2::annotate("text", x = 37, y = 7, label = "Focus D:\ncomparison",
    hjust = 0, family = regular, colour = ink, size = 4.3, lineheight = 1.1) +
  ggplot2::scale_fill_manual(values = c("TRUE" = blue, "FALSE" = pal$context[[2]])) +
  ggplot2::scale_x_continuous(limits = c(0, 61), breaks = c(0, 15, 30, 45, 60), expand = c(0, 0)) +
  ggplot2::labs(x = "Illustrative score", y = NULL) + base_plot()

composition <- expand.grid(period = paste0("P", 1:5), category = paste0("C", 1:8),
  KEEP.OUT.ATTRS = FALSE)
composition$category <- factor(composition$category, levels = paste0("C", 1:8))
composition$raw <- 9 + as.integer(composition$category) * 1.2 +
  as.integer(factor(composition$period)) * (as.integer(composition$category) %% 3)
composition$share <- ave(composition$raw, composition$period, FUN = function(x) 100 * x / sum(x))
outside_categories <- c("C2", "C3") # A cannot meet 4.5:1 on these fills; keep A/B placement identical.
p5 <- subset(composition, period == "P5")
outside_positions <- data.frame(category = outside_categories,
  center = vapply(outside_categories, function(category) {
    index <- match(category, as.character(p5$category))
    sum(p5$share[seq_along(p5$share) > index]) + p5$share[[index]] / 2
  }, numeric(1)))
make_composition <- function(choice) {
  colors <- categorical(choice)
  labels <- vapply(colors, label_color, character(1))
  if (anyNA(labels[!paste0("C", 1:8) %in% outside_categories])) {
    stop("An inside composition label cannot meet 4.5:1: ", choice)
  }
  plot_data <- composition
  plot_data$label_colour <- labels[as.integer(plot_data$category)]
  plot_data$center <- vapply(seq_len(nrow(plot_data)), function(i) {
    peers <- subset(plot_data, period == plot_data$period[[i]])
    sum(peers$share[as.integer(peers$category) > as.integer(plot_data$category[[i]])]) +
      plot_data$share[[i]] / 2
  }, numeric(1))
  inside_data <- subset(plot_data, !as.character(category) %in% outside_categories)
  ggplot2::ggplot(composition, ggplot2::aes(period, share, fill = category)) +
    ggplot2::geom_col(width = .76, colour = paper, linewidth = .7) +
    ggplot2::geom_text(data = inside_data, ggplot2::aes(y = center, label = category,
      colour = label_colour), family = medium, size = 4.0) +
    ggplot2::geom_segment(data = outside_positions,
      ggplot2::aes(x = 5.38, xend = 5.53, y = center, yend = center),
      inherit.aes = FALSE, colour = ink, linewidth = .35) +
    ggplot2::geom_text(data = outside_positions,
      ggplot2::aes(x = 5.57, y = center, label = category),
      inherit.aes = FALSE, hjust = 0, family = medium, colour = ink, size = 4.0) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_fill_manual(values = colors) +
    ggplot2::scale_x_discrete(expand = ggplot2::expansion(add = c(.4, 1.05))) +
    ggplot2::scale_y_continuous(breaks = c(0, 25, 50, 75, 100),
      labels = function(x) paste0(x, "%"), expand = c(0, 0)) +
    ggplot2::labs(x = "Synthetic period", y = "Composition") + base_plot()
}

measure_block <- function(value, width_in, fontsize, face = "plain", lineheight = 1.12) {
  if (is.null(value) || !length(value) || !nzchar(paste(value, collapse = ""))) return(NULL)
  paragraphs <- strsplit(paste(value, collapse = "\n"), "\n", fixed = TRUE)[[1]]
  grid::pushViewport(grid::viewport(gp = grid::gpar(fontfamily = regular,
    fontface = face, fontsize = fontsize)))
  on.exit(grid::popViewport())
  lines <- character()
  for (paragraph in paragraphs) {
    words <- strsplit(trimws(paragraph), "\\s+")[[1]]
    current <- ""
    for (word in words) {
      candidate <- if (nzchar(current)) paste(current, word) else word
      candidate_width <- grid::convertWidth(grid::stringWidth(candidate), "in", valueOnly = TRUE)
      if (candidate_width <= width_in) {
        current <- candidate
      } else {
        if (!nzchar(current)) stop("A word exceeds the available frame width: ", word)
        lines <- c(lines, current)
        current <- word
        if (grid::convertWidth(grid::stringWidth(word), "in", valueOnly = TRUE) > width_in) {
          stop("A word exceeds the available frame width: ", word)
        }
      }
    }
    lines <- c(lines, current)
  }
  gp <- grid::gpar(fontfamily = regular, fontface = face, fontsize = fontsize,
    col = ink, lineheight = lineheight)
  grob <- grid::textGrob(paste(lines, collapse = "\n"), gp = gp)
  list(text = paste(lines, collapse = "\n"), lines = length(lines),
    height = grid::convertHeight(grid::grobHeight(grob), "in", valueOnly = TRUE), gp = gp)
}

draw_frame <- function(plot, title, subtitle = NULL, source, note = NULL,
                       landscape = FALSE, plot_aspect = NULL, title_mode = "adaptive") {
  grid::grid.newpage()
  grid::grid.rect(gp = grid::gpar(fill = paper, col = NA))
  canvas_width <- grid::convertWidth(grid::unit(1, "npc"), "in", valueOnly = TRUE)
  canvas_height <- grid::convertHeight(grid::unit(1, "npc"), "in", valueOnly = TRUE)
  left <- if (landscape) 0.68 else 0.50
  right <- left
  content_width <- canvas_width - left - right
  title_max <- if (landscape) 30 else 35
  title_min <- if (landscape) 27 else 31
  title_size <- title_max
  title_block <- measure_block(title, content_width, title_size, "bold", 1.06)
  if (title_mode == "adaptive" && title_block$lines > 2) {
    initial_lines <- title_block$lines
    for (candidate in seq(title_max - 1, title_min, by = -1)) {
      measured <- measure_block(title, content_width, candidate, "bold", 1.06)
      title_size <- candidate
      title_block <- measured
      if (measured$lines < initial_lines) break
    }
  } else if (title_mode != "fixed-max" && title_mode != "adaptive") stop("Unknown title mode")
  subtitle_block <- measure_block(subtitle, content_width, 18)
  source_block <- measure_block(source, content_width, 16)
  note_block <- measure_block(note, content_width, 16)
  if (is.null(title_block) || is.null(source_block)) stop("A frame needs a title and source")

  top <- canvas_height - 0.42
  grid::grid.text(title_block$text, x = grid::unit(left, "in"), y = grid::unit(top, "in"),
    just = c("left", "top"), gp = title_block$gp)
  header_bottom <- top - title_block$height
  if (!is.null(subtitle_block)) {
    subtitle_top <- header_bottom - 0.15
    grid::grid.text(subtitle_block$text, x = grid::unit(left, "in"),
      y = grid::unit(subtitle_top, "in"), just = c("left", "top"), gp = subtitle_block$gp)
    header_bottom <- subtitle_top - subtitle_block$height
  }
  plot_top <- header_bottom - 0.29

  logo_height_in <- grid::convertHeight(logo_height, "in", valueOnly = TRUE)
  signature_bottom <- 0.40
  signature_center <- signature_bottom + logo_height_in / 2
  divider_y <- signature_bottom + logo_height_in + 0.28
  note_bottom <- divider_y + 0.25
  if (!is.null(note_block)) {
    note_top <- note_bottom + note_block$height
    source_bottom <- note_top + 0.12
    grid::grid.text(note_block$text, x = grid::unit(left, "in"),
      y = grid::unit(note_top, "in"), just = c("left", "top"), gp = note_block$gp)
  } else {
    source_bottom <- note_bottom
  }
  source_top <- source_bottom + source_block$height
  grid::grid.text(source_block$text, x = grid::unit(left, "in"),
    y = grid::unit(source_top, "in"), just = c("left", "top"), gp = source_block$gp)
  plot_bottom <- source_top + 0.25
  available_height <- plot_top - plot_bottom
  if (available_height < 2.1) stop("Text leaves too little height for the plot; use a larger canvas")
  if (is.null(plot_aspect)) {
    plot_width <- content_width
    plot_height <- available_height
  } else {
    plot_width <- min(content_width, available_height * plot_aspect)
    plot_height <- plot_width / plot_aspect
  }
  plot_left <- left + (content_width - plot_width) / 2
  plot_lower <- plot_bottom + (available_height - plot_height) / 2
  print(plot, vp = grid::viewport(
    x = grid::unit(plot_left + plot_width / 2, "in"),
    y = grid::unit(plot_lower + plot_height / 2, "in"),
    width = grid::unit(plot_width, "in"), height = grid::unit(plot_height, "in")))

  grid::grid.lines(x = grid::unit(c(left, canvas_width - right), "in"),
    y = grid::unit(divider_y, "in"), gp = grid::gpar(col = "#D7D9D7", lwd = 0.8))
  logo_x <- left + 0.30
  grid::grid.raster(logo_raster, x = grid::unit(logo_x, "in"),
    y = grid::unit(signature_center, "in"), width = logo_width, height = logo_height)
  grid::grid.text("THE DATA DECODED", x = grid::unit(left + 0.72, "in"),
    y = grid::unit(signature_center, "in"), just = "left",
    gp = grid::gpar(fontfamily = medium, fontsize = 15, col = ink))
  placed_ratio <- grid::convertWidth(logo_width, "in", valueOnly = TRUE) / logo_height_in
  if (abs(placed_ratio - logo_ratio) > 0.001) stop("Footer logo placement changed intrinsic ratio")
  list(canvas_width = canvas_width, canvas_height = canvas_height, left = left,
    title_lines = title_block$lines, title_size = title_size,
    subtitle_lines = if (is.null(subtitle_block)) 0 else subtitle_block$lines,
    source_lines = source_block$lines, note_lines = if (is.null(note_block)) 0 else note_block$lines,
    plot_left = plot_left, plot_bottom = plot_lower, plot_width = plot_width,
    plot_height = plot_height, available_height = available_height,
    plot_top_limit = plot_top, plot_bottom_limit = plot_bottom,
    source_top = source_top, divider_y = divider_y, signature_x = left,
    logo_ratio = placed_ratio)
}

out <- file.path(here, "exports")
dir.create(out, showWarnings = FALSE, recursive = TRUE)
cases <- list(
  list(key = "ranked-short", plot = ranked, title = "Where did it rise most?",
    subtitle = "Five invented regions, ranked by change", source = "Source: synthetic demonstration data",
    note = "Note: illustrative values.", aspect = 0.72),
  list(key = "ranked-long-before", plot = ranked, title = "Where did the index rise most across six sample years?",
    subtitle = "Five invented regions, ranked by change", source = "Source: synthetic demonstration data",
    note = "Note: illustrative values.", aspect = 0.72, title_mode = "fixed-max"),
  list(key = "ranked-long-after", plot = ranked, title = "Where did the index rise most across six sample years?",
    subtitle = "Five invented regions, ranked by change", source = "Source: synthetic demonstration data",
    note = "Note: illustrative values.", aspect = 0.72),
  list(key = "ranked-landscape", plot = ranked, title = "Where did it rise most?",
    subtitle = "Five invented regions, ranked by change", source = "Source: synthetic demonstration data",
    note = "Note: values are illustrative, not observed.", landscape = TRUE, aspect = 2.6),
  list(key = "series-A", plot = make_series("A"), title = "Eight synthetic trajectories",
    subtitle = NULL, source = "Source: synthetic demonstration data",
    note = "Note: direct labels and line patterns carry identity.", aspect = 0.76),
  list(key = "series-B", plot = make_series("B"), title = "Eight synthetic trajectories",
    subtitle = NULL, source = "Source: synthetic demonstration data",
    note = "Note: direct labels and line patterns carry identity.", aspect = 0.76),
  list(key = "sequential-heatmap", plot = heatmap_plot, title = "How does intensity vary?",
    subtitle = "Ordered synthetic values from zero to 100", source = "Source: synthetic demonstration data",
    note = "Note: every cell carries its value; the legend shows the continuous scale.", aspect = 0.87),
  list(key = "multipanel", plot = multi_plot,
    title = "How do four illustrative panels compare across a shared set of series?",
    source = "Source: synthetic demonstration data. Four panels use invented values over six periods.",
    note = "Method: identical calculations and scales in all panels.\nNote: line patterns and the shared legend supplement color; no observed trend is implied.",
    aspect = 0.86),
  list(key = "annotated-tall", plot = tall_plot,
    title = "Which invented regions lead this deliberately annotated ranking?",
    subtitle = "Ten synthetic values and two callouts",
    source = "Source: synthetic demonstration data. No real geography or measurement is represented.",
    note = "Method: values are ordered from largest to smallest; two focus regions use brand blue.\nNote: callouts describe the drawing only and are not analytical findings.",
    aspect = 0.68),
  list(key = "composition-A", plot = make_composition("A"),
    title = "How does a synthetic eight-part composition change?",
    subtitle = "Eight illustrative shares sum to 100%",
    source = "Source: synthetic demonstration data. Five periods and eight invented components.",
    note = "Note: shares total 100% in each period.",
    landscape = TRUE, aspect = 2.8),
  list(key = "composition-B", plot = make_composition("B"),
    title = "How does a synthetic eight-part composition change?",
    subtitle = "Eight illustrative shares sum to 100%",
    source = "Source: synthetic demonstration data. Five periods and eight invented components.",
    note = "Note: shares total 100% in each period.",
    landscape = TRUE, aspect = 2.8)
)

font_css <- paste0(
  "<metadata>Work Sans copyright 2019 The Work Sans Project Authors; SIL Open Font License 1.1. See ../fonts/OFL.txt in the source repository.</metadata>",
  "<style type=\"text/css\"><![CDATA[",
  "@font-face{font-family:'Work Sans';font-weight:400;src:url(data:font/ttf;base64,", base64enc::base64encode(font_files[[1]], linewidth = 0), ") format('truetype');}",
  "@font-face{font-family:'Work Sans';font-weight:700;src:url(data:font/ttf;base64,", base64enc::base64encode(font_files[[3]], linewidth = 0), ") format('truetype');}",
  "@font-face{font-family:'Work Sans';font-weight:500;src:url(data:font/ttf;base64,", base64enc::base64encode(font_files[[2]], linewidth = 0), ") format('truetype');}",
  "]]></style>"
)

layout_manifest <- list()
retry_file_io <- function(operation) {
  for (attempt in seq_len(5)) {
    result <- try(operation(), silent = TRUE)
    if (!inherits(result, "try-error")) return(result)
    Sys.sleep(0.25) # Windows indexing can briefly hold a just-written SVG.
  }
  stop(result)
}
for (item in cases) {
  png_file <- file.path(out, paste0(item$key, ".png"))
  svg_file <- file.path(out, paste0(item$key, ".svg"))
  landscape <- isTRUE(item$landscape)
  ragg::agg_png(png_file, width = if (landscape) 1920 else 1080,
    height = if (landscape) 1080 else 1920, units = "px", res = 144, background = paper)
  layout_png <- draw_frame(item$plot, item$title, item$subtitle, item$source, item$note,
    landscape, item$aspect, if (is.null(item$title_mode)) "adaptive" else item$title_mode)
  grDevices::dev.off()
  retry_file_io(function() svglite::svglite(svg_file,
    width = if (landscape) 13.333333 else 7.5,
    height = if (landscape) 7.5 else 13.333333, bg = paper))
  layout_svg <- draw_frame(item$plot, item$title, item$subtitle, item$source, item$note,
    landscape, item$aspect, if (is.null(item$title_mode)) "adaptive" else item$title_mode)
  grDevices::dev.off()
  layout_delta <- abs(unlist(layout_png) - unlist(layout_svg))
  if (max(layout_delta) > 0.03) {
    stop("PNG and SVG frame measurements disagree: ", item$key, " ",
      names(which.max(layout_delta)), " = ", max(layout_delta))
  }
  layout_manifest[[item$key]] <- layout_png
  svg <- paste(retry_file_io(function() readLines(svg_file, warn = FALSE,
    encoding = "UTF-8")), collapse = "\n")
  if (!grepl('font-family: "Work Sans"', svg, fixed = TRUE)) stop("SVG missing Work Sans family: ", item$key)
  svg <- gsub("preserveAspectRatio='none'", "preserveAspectRatio='xMidYMid meet'", svg, fixed = TRUE)
  svg <- sub("(<svg[^>]*>)", paste0("\\1\n<title>", paste(item$title, collapse = " "), "</title>", font_css), svg, perl = TRUE)
  retry_file_io(function() writeLines(svg, svg_file, useBytes = TRUE))
  cat("Exported ", item$key, ": PNG + self-contained SVG\n", sep = "")
}
jsonlite::write_json(layout_manifest, file.path(out, "layout.json"), auto_unbox = TRUE,
  pretty = TRUE, digits = 6)

# Approximate full-severity color-vision views of the *actual exported PNGs*.
# Machado et al. matrices act on linear-light RGB; these are diagnostic images.
vision_matrices <- list(
  protan = matrix(c(.152286, 1.052583, -.204868, .114503, .786281, .099216,
    -.003882, -.048116, 1.051998), nrow = 3, byrow = TRUE),
  deutan = matrix(c(.367322, .860646, -.227968, .280085, .672501, .047413,
    -.011820, .042940, .968881), nrow = 3, byrow = TRUE),
  tritan = matrix(c(1.255528, -.076749, -.178779, -.078411, .930809, .147602,
    .004733, .691367, .303900), nrow = 3, byrow = TRUE)
)
to_linear <- function(x) ifelse(x <= .04045, x / 12.92, ((x + .055) / 1.055)^2.4)
to_srgb <- function(x) ifelse(x <= .0031308, 12.92 * x, 1.055 * x^(1 / 2.4) - .055)
simulate_image <- function(image, mode) {
  shape <- dim(image)
  pixels <- matrix(image[, , 1:3], ncol = 3)
  linear <- to_linear(pixels)
  if (mode == "gray") {
    gray <- as.vector(linear %*% c(.2126, .7152, .0722))
    transformed <- cbind(gray, gray, gray)
  } else {
    transformed <- linear %*% t(vision_matrices[[mode]])
  }
  transformed <- pmin(1, pmax(0, transformed))
  array(to_srgb(transformed), dim = c(shape[[1]], shape[[2]], 3))
}
sim_dir <- file.path(here, "simulations")
dir.create(sim_dir, showWarnings = FALSE)
for (key in c("series-A", "series-B", "multipanel", "sequential-heatmap",
              "composition-A", "composition-B")) {
  image <- png::readPNG(file.path(out, paste0(key, ".png")))
  image <- image[seq(1, dim(image)[1], by = 2), seq(1, dim(image)[2], by = 2), , drop = FALSE]
  for (mode in c(names(vision_matrices), "gray")) {
    png::writePNG(simulate_image(image, mode), file.path(sim_dir, paste0(key, "-", mode, ".png")))
  }
}
