# Generate German exports from the same validated data and chart code.
script <- paste(readLines("visuals/2026-10-switzerland-population-growth/analysis.R", warn=FALSE, encoding="UTF-8"), collapse="\n")
old <- "Natural increase is births minus deaths. Net migration includes changes into permanent-resident status, not just physical arrivals and departures. The transition from ESPOP to STATPOP in 2011 changed the population definition, affecting historical comparability. Statistical adjustments are excluded, so the two components may not sum exactly to the officially reported population change."; new <- "Der Geburten\u00fcberschuss entspricht der Differenz zwischen Geburten und Todesf\u00e4llen. Der Wanderungssaldo umfasst auch \u00dcbertritte von der nichtst\u00e4ndigen zur st\u00e4ndigen Wohnbev\u00f6lkerung. Mit der Einf\u00fchrung von STATPOP im Jahr 2011 wurde die Bev\u00f6lkerungsdefinition erweitert, was die historische Vergleichbarkeit einschr\u00e4nkt. Bestandesbereinigungen sind nicht dargestellt; daher kann die Summe der beiden Komponenten von der offiziell ausgewiesenen Bev\u00f6lkerungsver\u00e4nderung abweichen."
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Swiss Federal Statistical Office (FSO), Demographic Balance, August 2026."; new <- "Bundesamt f\u00fcr Statistik (BFS), Demografische Bilanz, August 2026."
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Natural increase and net migration, 1971\\u20132025"; new <- "Geburten\\u00fcberschuss und Wanderungssaldo, 1971\\u20132025"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Some 2022 Ukrainian arrivals\\ncounted as permanent residents\\nin 2023"; new <- "2022 eingereiste Ukraine-Gefl\u00fcchtete\\nteils erst 2023 zur st\u00e4ndigen\\nWohnbev\u00f6lkerung gez\u00e4hlt"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "What Drives Switzerland's Population Growth?"; new <- "Was treibt das Bev\u00f6lkerungswachstum der Schweiz?"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "\"switzerland-population-growth\","; new <- "\"switzerland-population-growth-de\","
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Net migration (\\u2212)"; new <- "Wanderungssaldo (\\u2212)"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Oil-crisis\\nrecession"; new <- "\u00d6lkrise:\\nRezession"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Net: \\u221257,847"; new <- "Saldo: \\u221257'847"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Net migration (+)"; new <- "Wanderungssaldo (+)"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "People, thousands"; new <- "Personen (in Tausend)"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Natural increase"; new <- "Geburten\u00fcberschuss"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Natural: +6,249"; new <- "Geburten-\\n\u00fcberschuss: +6'249"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Net: +139,118"; new <- "Saldo: +139'118"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Net: +70,432"; new <- "Saldo: +70'432"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Source:"; new <- "Quelle:"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Notes:"; new <- "Hinweise:"
if (!grepl(old, script, fixed=TRUE)) stop("Translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- 'x=2025,y=91,label='; new <- 'x=2025,y=108,label='
if (!grepl(old, script, fixed=TRUE)) stop("2025 annotation target missing")
script <- gsub(old, new, script, fixed=TRUE)
eval(parse(text=script, encoding="UTF-8"))
