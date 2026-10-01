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
categorical <- function(accent) {
  values <- pal$categoricalBase
  values[[4]] <- pal$warmAccentCandidates[[accent]]
  unname(values)
}

paper <- pal$paper
ink <- pal$ink
blue <- pal$brandBlue
regular <- "TDD Work Sans"
medium <- "TDD Work Sans Medium"

# The small chart signature uses the lightly simplified mark. It is rasterized
# inside the R devices; all plotted geometry and text remain SVG vectors.
logo_source <- paste(readLines(file.path(study, "pterosaur-simplified.svg"), warn = FALSE), collapse = "\n")
logo_source <- gsub("#0062DF", blue, logo_source, fixed = TRUE)
logo_png <- rsvg::rsvg_png(charToRaw(logo_source), width = 180, height = 133)
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
  ggplot2::geom_text(ggplot2::aes(label = change), hjust = -0.35, family = medium, size = 5.4) +
  ggplot2::scale_fill_manual(values = c("TRUE" = blue, "FALSE" = pal$context[[3]])) +
  ggplot2::scale_x_continuous(limits = c(0, 33), breaks = c(0, 10, 20, 30), expand = c(0, 0)) +
  ggplot2::labs(x = "Index-point change", y = NULL) + base_plot()

series <- expand.grid(period = 1:6, group = paste0("S", 1:8), KEEP.OUT.ATTRS = FALSE)
series$group <- factor(series$group, levels = paste0("S", 1:8))
series$id <- as.integer(series$group)
series$value <- 6 + series$id * 8 + c(0, 3, -1, 5, 4, 9)[series$period] + (series$id %% 3) * series$period * 0.35
end_labels <- subset(series, period == 6)
make_series <- function(accent) {
  ggplot2::ggplot(series, ggplot2::aes(x = period, y = value, group = group, colour = group, linetype = group)) +
    ggplot2::geom_line(linewidth = 1.05) +
    ggplot2::geom_text(data = end_labels, ggplot2::aes(label = group), x = 6.28,
      hjust = 0, family = medium, size = 4.2, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = categorical(accent)) +
    ggplot2::scale_linetype_manual(values = c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash", "solid", "dashed")) +
    ggplot2::scale_x_continuous(limits = c(1, 6.85), breaks = 1:6, expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(10, 90), breaks = c(20, 40, 60, 80)) +
    ggplot2::labs(x = "Sample period", y = "Synthetic index") + base_plot()
}

heat <- expand.grid(column = LETTERS[1:5], row = paste0("R", 1:4), KEEP.OUT.ATTRS = FALSE)
heat$value <- c(5, 12, 0, 8, 20, 28, 18, 32, 35, 42, 51, 57, 60, 68, 74, 71, 90, 85, 100, 93)
heat$row <- factor(heat$row, levels = rev(paste0("R", 1:4)))
heat$label_colour <- ifelse(heat$value > 62, "white", ink)
heatmap_plot <- ggplot2::ggplot(heat, ggplot2::aes(x = column, y = row, fill = value)) +
  ggplot2::geom_tile(colour = paper, linewidth = 1.5) +
  ggplot2::geom_text(ggplot2::aes(label = value, colour = label_colour), family = medium, size = 5.1) +
  ggplot2::scale_colour_identity() +
  ggplot2::scale_fill_gradientn(colours = pal$sequential, limits = c(0, 100)) +
  ggplot2::labs(x = "Sample column", y = NULL) +
  ggplot2::coord_equal() + base_plot() +
  ggplot2::theme(panel.grid = ggplot2::element_blank())

draw_frame <- function(plot, title_lines, subtitle = NULL, source, note) {
  grid::grid.newpage()
  grid::grid.rect(gp = grid::gpar(fill = paper, col = NA))
  grid::grid.text(paste(title_lines, collapse = "\n"), x = 0.065, y = 0.955,
    just = c("left", "top"), gp = grid::gpar(fontfamily = regular, fontface = "bold", fontsize = 36,
      col = ink, lineheight = 1.06))
  if (!is.null(subtitle)) grid::grid.text(subtitle, x = 0.065, y = 0.815,
    just = c("left", "center"), gp = grid::gpar(fontfamily = regular, fontsize = 18, col = ink))
  divider_y <- if (is.null(subtitle)) 0.865 else 0.777
  grid::grid.lines(x = c(0.065, 0.935), y = c(divider_y, divider_y), gp = grid::gpar(col = "#D7D9D7", lwd = 0.8))
  print(plot, vp = grid::viewport(x = 0.50, y = if (is.null(subtitle)) 0.535 else 0.49,
    width = 0.89, height = if (is.null(subtitle)) 0.60 else 0.53))
  grid::grid.text(source, x = 0.065, y = 0.184, just = "left",
    gp = grid::gpar(fontfamily = regular, fontsize = 16, col = ink))
  grid::grid.text(note, x = 0.065, y = 0.155, just = "left",
    gp = grid::gpar(fontfamily = regular, fontsize = 16, col = ink))
  grid::grid.lines(x = c(0.065, 0.935), y = c(0.103, 0.103), gp = grid::gpar(col = "#D7D9D7", lwd = 0.8))
  grid::grid.text("SYNTHETIC DATA", x = 0.065, y = 0.069, just = "left",
    gp = grid::gpar(fontfamily = medium, fontsize = 13, col = ink))
  grid::grid.raster(logo_raster, x = 0.565, y = 0.069, width = 0.080, height = 0.056)
  grid::grid.text("THE DATA DECODED", x = 0.628, y = 0.069, just = "left",
    gp = grid::gpar(fontfamily = medium, fontsize = 13, col = ink))
}

out <- file.path(here, "exports")
dir.create(out, showWarnings = FALSE, recursive = TRUE)
cases <- list(
  list(key = "ranked-short", plot = ranked, title = "Where did it rise most?",
    subtitle = "Five invented regions, ranked by change", source = "Source: synthetic demonstration data",
    note = "Note: values are illustrative, not observed."),
  list(key = "ranked-long", plot = ranked, title = c("Where did the index rise", "most across six sample", "years?"),
    subtitle = "Five invented regions, ranked by change", source = "Source: synthetic demonstration data",
    note = "Note: values are illustrative, not observed."),
  list(key = "series-vermilion", plot = make_series("vermilion"), title = "Eight synthetic trajectories",
    subtitle = NULL, source = "Source: synthetic demonstration data",
    note = "Note: direct labels and line patterns carry identity."),
  list(key = "series-crimson", plot = make_series("crimson"), title = "Eight synthetic trajectories",
    subtitle = NULL, source = "Source: synthetic demonstration data",
    note = "Note: direct labels and line patterns carry identity."),
  list(key = "sequential-heatmap", plot = heatmap_plot, title = "How does intensity vary?",
    subtitle = "Ordered synthetic values from zero to 100", source = "Source: synthetic demonstration data",
    note = "Note: every cell carries its value.")
)

font_css <- paste0(
  "<metadata>Work Sans copyright 2019 The Work Sans Project Authors; SIL Open Font License 1.1. See ../fonts/OFL.txt in the source repository.</metadata>",
  "<style type=\"text/css\"><![CDATA[",
  "@font-face{font-family:'Work Sans';font-weight:400;src:url(data:font/ttf;base64,", base64enc::base64encode(font_files[[1]], linewidth = 0), ") format('truetype');}",
  "@font-face{font-family:'Work Sans';font-weight:700;src:url(data:font/ttf;base64,", base64enc::base64encode(font_files[[3]], linewidth = 0), ") format('truetype');}",
  "@font-face{font-family:'Work Sans';font-weight:500;src:url(data:font/ttf;base64,", base64enc::base64encode(font_files[[2]], linewidth = 0), ") format('truetype');}",
  "]]></style>"
)

for (item in cases) {
  png_file <- file.path(out, paste0(item$key, ".png"))
  svg_file <- file.path(out, paste0(item$key, ".svg"))
  ragg::agg_png(png_file, width = 1080, height = 1920, units = "px", res = 144, background = paper)
  draw_frame(item$plot, item$title, item$subtitle, item$source, item$note)
  grDevices::dev.off()
  svglite::svglite(svg_file, width = 7.5, height = 13.333333, bg = paper)
  draw_frame(item$plot, item$title, item$subtitle, item$source, item$note)
  grDevices::dev.off()
  svg <- paste(readLines(svg_file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  if (!grepl('font-family: "Work Sans"', svg, fixed = TRUE)) stop("SVG missing Work Sans family: ", item$key)
  svg <- sub("(<svg[^>]*>)", paste0("\\1\n<title>", paste(item$title, collapse = " "), "</title>", font_css), svg, perl = TRUE)
  writeLines(svg, svg_file, useBytes = TRUE)
  cat("Exported ", item$key, ": PNG + self-contained SVG\n", sep = "")
}
