#!/usr/bin/env Rscript
# Check rendered PNG pixels as a complement to the SVG placement check.
if (!requireNamespace("png", quietly = TRUE) || !requireNamespace("rsvg", quietly = TRUE)) {
  stop("Verification needs the png and rsvg packages")
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

for (name in c("ranked-short", "ranked-long", "ranked-landscape", "series-vermilion",
               "series-crimson", "sequential-heatmap", "multipanel", "annotated-tall",
               "composition-vermilion", "composition-crimson")) {
  image <- png::readPNG(file.path(here, "exports", paste0(name, ".png")))
  height <- dim(image)[1]
  footer <- image[(height - 240):height, , 1:3]
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
