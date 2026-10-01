#!/usr/bin/env Rscript
# Check rendered PNG pixels as a complement to the SVG placement check.
if (!requireNamespace("png", quietly = TRUE) || !requireNamespace("rsvg", quietly = TRUE) ||
    !requireNamespace("base64enc", quietly = TRUE)) {
  stop("Verification needs the png, rsvg, and base64enc packages")
}
file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
if (length(file_arg) != 1) stop("Run with Rscript brand-exploration/r-prototypes/verify.R")
here <- dirname(normalizePath(sub("^--file=", "", file_arg)))
mark <- paste(readLines(file.path(here, "..", "pterosaur-simplified.svg"), warn = FALSE), collapse = "\n")
source <- png::readPNG(rsvg::rsvg_png(charToRaw(mark), width = 366, height = 270))
source_pixels <- which(source[, , 4] > 0.5, arr.ind = TRUE)
bbox_ratio <- function(pixels) {
  (diff(range(pixels[, 2])) + 1) / (diff(range(pixels[, 1])) + 1)
}
source_ratio <- bbox_ratio(source_pixels)
brand_blue <- c(0x24, 0x55, 0xFF) / 255
has_brand_blue <- function(image) {
  sum(abs(image[, , 1] - brand_blue[[1]]) < .005 &
    abs(image[, , 2] - brand_blue[[2]]) < .005 &
    abs(image[, , 3] - brand_blue[[3]]) < .005)
}
if (has_brand_blue(source) < 1000) stop("Simplified source SVG does not rasterize in #2455FF")

for (name in c("ranked-short", "ranked-long-before", "ranked-long-after",
               "ranked-landscape", "series-A", "series-B", "sequential-heatmap",
               "multipanel", "annotated-tall", "composition-A", "composition-B")) {
  image <- png::readPNG(file.path(here, "exports", paste0(name, ".png")))
  height <- dim(image)[1]
  footer <- image[(height - 240):height, , 1:3]
  if (has_brand_blue(footer) < 100) stop(name, ": PNG footer mark does not use #2455FF")
  svg <- paste(readLines(file.path(here, "exports", paste0(name, ".svg")), warn = FALSE), collapse = "\n")
  image_tags <- regmatches(svg, gregexpr("<image [^>]+>", svg, perl = TRUE))[[1]]
  logo_tags <- image_tags[grepl("width='43.20' height='31.87'", image_tags, fixed = TRUE)]
  if (length(logo_tags) != 1) stop(name, ": SVG footer mark placement is missing")
  embedded <- regmatches(logo_tags[[1]], regexec("xlink:href='data:image/png;base64,([^']+)'", logo_tags[[1]]))[[1]]
  if (length(embedded) != 2) stop(name, ": SVG footer mark raster is missing")
  svg_logo <- png::readPNG(base64enc::base64decode(embedded[[2]]))
  if (has_brand_blue(svg_logo) < 1000) stop(name, ": SVG footer mark does not use #2455FF")
  blue_pixels <- which(footer[, , 1] < 0.25 & footer[, , 2] > 0.20 &
    footer[, , 2] < 0.50 & footer[, , 3] > 0.90, arr.ind = TRUE)
  if (nrow(blue_pixels) < 100) stop(name, ": footer logo blue pixels missing")
  output_ratio <- bbox_ratio(blue_pixels)
  if (abs(output_ratio - source_ratio) > 0.04) {
    stop(name, ": rendered logo bounds differ from source ratio: ", output_ratio, " vs ", source_ratio)
  }
  cat(name, ": PNG footer mark bounds ", round(output_ratio, 3),
    " vs source ", round(source_ratio, 3), "\n", sep = "")
  if (startsWith(name, "ranked-") || name == "annotated-tall") {
    light <- c(0xA6, 0xB0, 0xBD) / 255
    context_pixels <- abs(image[, , 1] - light[[1]]) < 0.005 &
      abs(image[, , 2] - light[[2]]) < 0.005 &
      abs(image[, , 3] - light[[3]]) < 0.005
    if (sum(context_pixels) < 1000) stop(name, ": light context fill missing")
  }
}
