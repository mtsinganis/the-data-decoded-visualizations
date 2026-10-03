---
title: "NYC shootings surged in 2020–2021, then fell to a record low in 2025"
slug: "nyc-shootings"
date: "2026-10-02"
topics:
  - New York City
  - Public safety
  - Shooting incidents
description: "Two views of reported NYC shooting incidents: monthly counts and within-year cumulative totals, 2006–2025, with 2026 through June 30."
status: published
featured: false
charts:
  - file: plots/cumulative.png
    alt: "Cumulative reported shooting incidents by month for each year from 2006 through 2025, with 2026 ending at June 30. Annual lines restart in January. 2020 and 2021 have the highest endpoints; 2025 is the lowest complete-year endpoint since 2006 in this dataset. 2025 totals 688 incidents, 56 percent below 2021's 1,562."
  - file: plots/monthly.png
    alt: "Monthly reported shooting incidents in New York City, 2006 through 2025, with 2026 through June 30. Thin gray lines show other years; 2020, 2021, 2025, and 2026 are highlighted. July 2020 has 243 incidents, the highest monthly count in the saved coverage since 2006; December 2025 has 35, the lowest month in this dataset."
---

Reported shooting incidents surged in 2020–2021, then fell to 688 in 2025: the lowest annual total in this dataset since 2006. The cumulative chart shows 2025 ending at 688 incidents, less than half the 1,562 recorded in 2021: a decline of 56%. These records describe incidents, not the number of people shot, and they do not represent all gun violence.

The monthly chart highlights July 2020's 243 incidents, the highest monthly count in the saved data since 2006. December 2025's 35 incidents is the lowest. These comparisons describe the timing and magnitude of the changes, not their causes.

The 2026 lines stop at June 30. January–June totals 322 incidents, compared with 337 in the same months of 2025; the charts do not project a full-year total.

## Sources and methodology

### Source and unit

The source is the New York City Police Department's [Shootings (2006–Present) dataset](https://data.cityofnewyork.us/Public-Safety/Shootings-2006-Present-/5ucz-vwe8), dataset ID `5ucz-vwe8`. Its definition says it identifies every shooting incident in NYC since 2006. `INCIDENT_KEY` is described as a persistent ID for each incident; `OCCUR_DATE` is the exact occurrence date. The dataset is distinct from NYPD's related victim-level data. Each incident is counted once by distinct `INCIDENT_KEY`.

The reproducible input snapshot was downloaded on October 2, 2026 and is saved at `data/shootings_snapshot.csv`. It contains 24,310 rows and unique incident IDs, covers January 1, 2006 through June 30, 2026, has no missing IDs or dates, and has no duplicate IDs. Dataset metadata lists weekly data-change frequency. The saved analysis runs only against the snapshot; it does not download data automatically. Running the analysis recreates quality checks and month/year tables in `data/`; these derived files are not committed.

### Coverage and calculations

The original script dropped `INCIDENT_KEY` before analysis and counted rows. Its totals happen to match this snapshot because it has no duplicate IDs, but dropping the key prevents an explicit incident-level check. The revised analysis deduplicates by `INCIDENT_KEY` before counting. The original 2026 calendar also stopped at March 31; this version uses the independently confirmed June 30 cutoff. The 2006–2025 annual totals are complete calendar years: the saved data contains incident records in all 12 months of each year. There are no months with zero incidents in this interval, so no plotted historical zero is inferred from a missing month. Annual counts are the sum of distinct incident IDs by occurrence year. Monthly counts are distinct incident IDs by occurrence year and month. The cumulative series restarts at January for each year.

The snapshot's 2026 records stop on June 30. The NYPD's July 2, 2026 [first-half announcement](https://www.nyc.gov/site/nypd/news/PR011/nypd-fewest-shooting-incidents-shooting-victims-murders-recorded-history-for) reports 322 shooting incidents from January 1 through June 30, matching the snapshot's 322. That supports the explicit June 30 cutoff; 2026 is not extended beyond June and is not presented as a full-year total. The NYPD notes its statistics are preliminary and may be revised.

Jan–June 2026 has 322 incidents versus 337 in Jan–June 2025, 15 fewer (4.5%). Across complete years, 2025 has 688 incidents versus 1,562 in 2021, 874 fewer (56.0%). At 688, 2025 is the lowest annual total among complete years from 2006 through 2025 in this dataset. July 2020 has 243 incidents, the highest single-month count in the saved coverage since 2006, and December 2025 has 35, the lowest single-month count in the saved 2006–2026 coverage.

### NYPD year-end figure check

The dataset contains 688 unique incident IDs for 2025, matching the 688 in the NYPD's January 6, 2026 [year-end announcement prose](https://www.nyc.gov/site/nypd/news/PR001/nypd-safest-year-ever-gun-violence-fewest-shooting-incidents-and-shooting). That same release's detailed EOY table lists 687. The one-incident conflict is within the published release; the available source does not explain it. The chart uses the reproducible dataset count of 688 and does not alter it to match the table.
