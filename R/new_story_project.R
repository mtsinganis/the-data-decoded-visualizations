# Create a draft project for the Astro workflow without changing the legacy initializer.
new_story_project <- function(folder, title, date = Sys.Date()) {
  stopifnot(is.character(folder), length(folder) == 1L,
            grepl("^[0-9]{4}-[0-9]{2}(-[0-9]{2})?-[a-z0-9]+(-[a-z0-9]+)*$", folder),
            is.character(title), length(title) == 1L, nzchar(title))
  if (!dir.exists("visuals") || !dir.exists("R")) {
    stop("Run this function from the repository root.")
  }
  project <- file.path("visuals", folder)
  if (file.exists(project)) stop("Project path already exists: ", project)
  dir.create(file.path(project, "data"), recursive = TRUE)
  dir.create(file.path(project, "plots"))
  file.create(file.path(project, "data", ".gitkeep"))
  file.create(file.path(project, "plots", ".gitkeep"))
  yaml_title <- encodeString(title, quote = '"')
  writeLines(c(
    "---", paste0("title: ", yaml_title),
    paste0('slug: "', sub("^[0-9]{4}-[0-9]{2}(-[0-9]{2})?-", "", folder), '"'),
    paste0('date: "', format(as.Date(date), "%Y-%m-%d"), '"'),
    "topics: []", 'description: ""', "status: draft", "featured: false",
    "charts: []", "---", "", "[Write the reader-facing story here.]", "",
    "## Sources and methodology", "", "[Document data sources and calculations.]"
  ), file.path(project, "story.md"), useBytes = TRUE)
  writeLines(c("# X post draft", "", "Status: starter only.", "", "[Draft checked copy here.]"),
             file.path(project, "post.md"), useBytes = TRUE)
  writeLines(c("# Run from the repository root.",
               "# Read data from this project's data/ folder, build ggplot charts,",
               "# and save finished exports to its plots/ folder."),
             file.path(project, "analysis.R"), useBytes = TRUE)
  invisible(project)
}
