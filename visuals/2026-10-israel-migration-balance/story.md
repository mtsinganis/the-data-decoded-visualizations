---
title: "Israel is still growing as migration subtracts from its population"
slug: "israel-migration-balance"
date: "2026-10-08"
topics:
  - Israel
  - International migration
  - Population growth
description: "How migration became a drag on population growth: annual balances, the latest arrivals and departures, and why births minus deaths kept growth positive."
status: draft
featured: false
charts:
  - file: plots/02-annual-migration-balance.png
    alt: "Annual CBS total international net migration for the Israeli population: plus 27,600 in 2023, minus 18,600 in 2024 and minus 20,900 in 2025. Three calendar-year bars span the plot, with a blue positive bar and two red negative bars. Faint horizontal gridlines and a darker zero line aid comparison. Full values appear directly above or below each bar. Annual figures may be revised."
  - file: plots/01-migration-components.png
    alt: "Waterfall of provisional CBS estimates for approximately September 2025–September 2026, about 11½ months. Approximately 24,000 new immigrants, 4,000 family reunification arrivals and 21,000 returning Israelis add 49,000 people. About 57,000 Israelis moving abroad leave net migration of minus 8,000. A blue bracket groups the three arrivals as 49,000 people, not an extra flow. Departures are red; a filled neutral grey result bar starts at zero, with a charcoal minus 8,000 label. Figures are rounded. This is not calendar year 2026."
  - file: plots/03-population-growth.png
    alt: "Population-growth waterfall for approximately September 2025–September 2026, about 11½ months. Approximately 182,000 births minus 50,000 deaths yield plus 132,000. A red step labeled minus 8,000 represents net migration and reduces the result to plus 124,000 total population growth. The negative label describes the change, not its height on the axis. Figures are provisional and rounded; the separately reported foreign population is excluded."
---

International migration became a drag on Israel's population growth: the balance was positive in 2023, then negative in 2024 and 2025. The charts trace that shift, explain the latest deficit, and show why the population continued to grow.

## Interpretation

**1. Net migration turned negative.** For calendar years 2023–2025, CBS reports +27,600, −18,600 and −20,900 respectively. These are total international net migration balances, including new immigrants and other relevant arrivals alongside returning Israelis and Israeli emigrants. Annual figures may be revised.

**2. The latest deficit reflects more departures than arrivals.** In the separate provisional reporting period spanning late September 2025 to early September 2026—approximately 11.6 months—about 24,000 new immigrants, 4,000 family reunification arrivals and 21,000 returning Israelis added 49,000 people. About 57,000 Israelis moving abroad left net migration of approximately −8,000. This period overlaps the calendar-year bars; the smaller deficit cannot be read as a directly comparable annual improvement over 2025.

**3. Births minus deaths kept population growth positive.** In that same reporting period, about 182,000 births minus 50,000 deaths added 132,000 people. This offset the migration deficit and left population growth of approximately 124,000, excluding the separately reported foreign population. Negative net migration therefore did not mean the total population declined.

These figures describe population accounting. They do not establish why people moved or the causes of the migration shift.

## Sources and methodology

### Sources and data vintage

- Israel Central Bureau of Statistics (CBS), [Israel in Figures — Rosh Hashana: Selected Annual Data 2026](https://www.cbs.gov.il/he/mediarelease/DocLib/2026/282/11_26_282b.pdf), release 282/2026, September 9, 2026, page 1. This controls charts 2 and 3.
- CBS, [annual table 2.8: Sources of Israelis' Population Growth, by Population Group and Religion](https://www.cbs.gov.il/he/publications/DocLib/2025/2.ShnatonPopulation/st02_08.xlsx), published December 24, 2025; [PDF counterpart](https://www.cbs.gov.il/he/publications/DocLib/2025/2.ShnatonPopulation/st02_08.pdf). The 2023 and 2024 values come from the TOTAL POPULATION section, sheet ST02-08a, column H (“Migration balance — Total”).
- CBS, [annual table 2.9: Sources of Israelis' Population Growth, by District, Population Group and Religion](https://www.cbs.gov.il/he/publications/DocLib/2026/2.ShnatonPopulation/st02_09.xlsx), published October 8, 2026. The 2025 balance comes from sheet ST02-09a, GRAND TOTAL row, column G. Internal migration is zero for the national total.
- CBS, [Table E/4, February 2026](https://www.cbs.gov.il/he/publications/DocLib/2026/yarhon0226/e4.pdf), supplies the Israeli-only migration definitions, revised annual estimates, and timing caveats. Its figures are preserved for audit, not plotted as total migration.
- CBS, Eilat Cohen-Kastro, [A New Methodology for Estimation of Israelis' International Migration](https://www.cbs.gov.il/he/Documents/A%20New%20Methodology%20for%20Estimation%20of%20Israelis%27%20International%20Migration_Eilat%20Cohen%20Kastro.pdf), October 29, 2024, explains the methodology.

The originals were retrieved October 8, 2026 and retained in this project's data folder, with download URLs, source checksums, PDF text extractions, spreadsheet cell provenance, and calculation checks. Running analysis.R regenerates the extracted data and all three PNG/SVG pairs without a website build running R.

### What “net migration” means

The **international migration balance of Israelis** in E/4 is returning Israelis minus Israeli emigrants. The **total international migration balance** also includes new arrivals such as immigrants and family reunification arrivals. E/4 alone cannot provide that total. Chart 1 uses the total balance reported directly in population-growth tables; it does not add immigration to E/4 or infer migration by subtracting natural increase from population stocks.

These charts concern CBS's Israeli population, including citizens and relevant residents and Israeli localities in the Judea and Samaria Area. The separately reported foreign population is excluded from the growth accounting. The annual tables' immigration subcategory also includes immigrating citizens, as their footnotes specify; the plotted variable is the broader total balance.

### Periods, precision and reconciliation

Charts 2 and 3 cover the **11.63 months since the previous Rosh Hashana**, as CBS specifies. The reader-facing approximate calendar window is September 2025–September 2026. Chart 2 describes this as late September 2025 to early September 2026: the former holiday began September 22, and the release was published September 9 ahead of the September 11 holiday. This wording describes an approximate window, not exact statistical boundaries. The 11.63-month duration remains the controlling CBS definition. CBS does not supply exact calendar boundaries in this passage: the September 9 publication date is not treated as an endpoint. [Hebcal’s Israel calendar](https://www.hebcal.com/holidays/rosh-hashana-2025?i=on) places the holiday beginnings on September 22, 2025 and September 11, 2026. These establish the approximate month window, not precise statistical observation dates. This is not calendar year 2026 and is not annualized. The release describes its population estimates as provisional and reports the component figures approximately, in thousands. No more precise holiday-period figures were available in the controlling release; the charts retain that published precision.

At that precision, both checks have a zero residual: 24 + 4 + 21 − 57 = −8 thousand, and 182 − 50 − 8 = +124 thousand. Natural increase, 132,000, is calculated as births minus deaths. The total bars are reported outcomes, not extra components.

The annual bars cover complete calendar years 2023–2025 and retain the published precision of 100 people. The two population-growth tables use the same post-2023 migration methodology and 2022 Census population basis. Different release dates do not demonstrate a methodological break between 2024 and 2025, so no separator is drawn. Revisions can change magnitudes; this article does not interpret the small 2024-to-2025 difference as a precisely measured deterioration. The 2026 table 2.9 does not restate earlier national years. The corresponding 2026 historical table 2.8 URL returned an HTML error page and was absent from the checked file inventory, so a single newest vintage could not be obtained.

### Historical reconstruction investigation

CBS retrospectively revised E/4’s Israeli emigration and return series for 2010–2023. This makes a longer history worth investigating; the 2023 population-method change alone is not a sufficient reason to exclude earlier years.

We matched the revised 2010–2025 E/4 balances to [February 2026 table E/1](https://www.cbs.gov.il/he/publications/DocLib/2026/yarhon0226/e1.pdf), using its broadest arrivals column, immigrants plus immigrating citizens. E/1 includes permanent-stay permits under the Law of Entry as well as Law of Return immigrants. It does not establish a complete, separately aligned family-reunification and other-arrivals series for the population-growth accounting. Its footnotes also describe population-register flow changes from 2016, while E/4 uses the year in which duration-based migrant status is determined. A further search found CBS's [2021 International Migrants Day release](https://www.cbs.gov.il/he/mediarelease/DocLib/2021/418/11_21_418b.pdf), which separately identifies family reunification and new registration among arrivals (about 5,300 and 1,000 respectively in 2020). This confirms additional categories need explicit coverage; it supplies an older snapshot rather than a harmonized annual series through 2025.

The candidate sums fail the direct-total check: +17,731 versus +27,600 in 2023; −26,275 versus −18,600 in 2024; −26,061 versus −20,900 in 2025. The differences are 9,869, 7,675 and 5,161 people, far beyond rounding. These differences are not assigned to family reunification or any other category without evidence. They show that combining these two tables alone does not reproduce the required total with verified coverage and timing. The full 2010–2025 comparison is saved in `data/historical_reconstruction_audit.csv`.

Accordingly, chart 1 retains the directly reported recent total balances for 2023–2025. A longer comparable total series remains unverified because the required other arrivals and aligned accounting definitions have not been established, rather than because revised Israeli-only history does not exist. Earlier published totals are retained in an audit and are not spliced into this chart.

### When a person counts as a migrant

Under E/4's definitions, an emigrant spends at least nine months cumulatively abroad in the year after departure, including the first three months continuously. A returning Israeli meets the corresponding stay criteria in Israel after arrival. Status is determined one year after the initial departure or arrival; E/4's annual rows use that determination year. These duration-based classifications do not count ordinary travel and do not imply an irreversible permanent move. The methodological paper is background; E/4's updated footnotes govern the revised audit series.
