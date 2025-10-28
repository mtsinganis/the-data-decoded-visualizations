library(ggplot2)

theme_data_decoded <- function() {
    theme_minimal(base_size = 12) +
        theme(
            plot.title = element_text(face = "bold"),
            plot.subtitle = element_text(margin = margin(b = 6)),
            plot.caption = element_text(size = 9, margin = margin(t = 6)),
            panel.grid.minor = element_blank()
        )
}
