# Generate the German companion using the same data, layout and rendering code.
script <- paste(readLines("visuals/2026-10-switzerland-net-migration/analysis.R", warn=FALSE, encoding="UTF-8"), collapse="\n")
old <- "Net: \\u221257,847"; new <- "Saldo: \\u221257'847"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Net: +98,167"; new <- "Saldo: +98'167"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Net: +139,118"; new <- "Saldo: +139'118"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Net: +70,432"; new <- "Saldo: +70'432"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Oil-crisis\\nrecession"; new <- "Rezession nach der\\n\u00d6lkrise"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "EU-17/EFTA quotas\\nlifted in 2007\\nStrong labour demand"; new <- "EU-17/EFTA: Kontingente\\n2007 aufgehoben\\nHoher Arbeitskr\u00e4ftebedarf"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "2022 Ukrainian arrivals\\ncounted in 2023"; new <- "Ukraine-Gefl\u00fcchtete:\\n2022 eingereist,\\n2023 mitgez\u00e4hlt"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "People, thousands"; new <- "Personen (in Tausend)"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "paste(\"Source:\",source)"; new <- "paste(\"Quelle:\",source)"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "paste(\"Notes:\",note)"; new <- "paste(\"Hinweise:\",note)"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "field(\"Source:\",source_lines"; new <- "field(\"Quelle:\",source_lines"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "field(\"Notes:\",note_lines"; new <- "field(\"Hinweise:\",note_lines"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Switzerland's Net Migration, 1971\\u20132025"; new <- "Wanderungssaldo der Schweiz, 1971\u20132025"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Annual net migration (immigration minus emigration), permanent resident population"; new <- "J\u00e4hrlicher Wanderungssaldo (Einwanderung minus Auswanderung), st\u00e4ndige Wohnbev\u00f6lkerung"
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "\"switzerland-net-migration\","; new <- "\"switzerland-net-migration-de\","
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Swiss Federal Statistical Office (FSO), Demographic Balance, August 2026."; new <- "Bundesamt f\u00fcr Statistik (BFS), Demografische Bilanz, August 2026."
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
old <- "Net migration includes changes into permanent-resident status. ESPOP (1971\\u20132010) and STATPOP (2011\\u20132025) use different population definitions."; new <- "Der Wanderungssaldo umfasst auch \u00dcbertritte von der nichtst\u00e4ndigen in die st\u00e4ndige Wohnbev\u00f6lkerung. Mit dem Wechsel von ESPOP zu STATPOP im Jahr 2011 wurde die Bev\u00f6lkerungsdefinition erweitert."
if (!grepl(old, script, fixed=TRUE)) stop("German translation target missing: ", old)
script <- gsub(old, new, script, fixed=TRUE)
eval(parse(text=script, encoding="UTF-8"))
