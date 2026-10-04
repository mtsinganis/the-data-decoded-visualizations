# Interior-apprehension scope audit — October 4, 2026

## Finding

The exact month when At Large apprehensions **began** to be included is not established. **October 2023 is the earliest month for which inclusion can be directly quantified from the verified CBP split tables.** It is not an identified counting-rule introduction date. The original October 2025 chart boundary was incomplete evidence coverage and is superseded.

Every month October 2023–August 2026 in the project's preferred AOR releases includes At Large: the CSV total exactly equals the published southwest At Entry + At Large. Historical southwest encounters did not exclude At Large for at least those 35 months. January 2017–September 2023 remains unresolved, not presumed free of interior events and not assigned an invented zero difference.

## Source-to-claim evidence

| Evidence inspected | Location | Finding and limit |
| --- | --- | --- |
| CBP Nationwide Encounters dictionary, September 2023 | data/raw/data-dictionary.pdf, pp. 1–2; [original](https://www.cbp.gov/sites/default/files/assets/documents/2023-Sep/nationwide-encounters-data-dictionary.pdf) | Region is component-defined; AOR is sector/field office; USBP Title 8 encounter type is Apprehensions. No entry/large dimension, interior-exclusion filter or month of rule change is specified. |
| Current download listing | data/raw/official-listing.html and official-listing-2026-10-04.html; [original](https://www.cbp.gov/document/stats/nationwide-encounters) | Still links that 2023 dictionary. A current linked dictionary is not a version history establishing the rule for every earlier month. |
| FY2024 monthly table | data/raw/nationwide-fy2024.html; [original](https://www.cbp.gov/newsroom/stats/nationwide-encounters-fy2024) | Provides southwest Total, At Large and At Entry for Oct 2023–Sep 2024. October: 188,749 = 186,062 + 2,687. All 12 months match the final FY2021–FY2024 AOR CSV and current release. |
| FY2025 monthly table | data/raw/nationwide-fy2025.html; [original](https://www.cbp.gov/newsroom/stats/nationwide-encounters-fy2025) | Provides the same split for Oct 2024–Sep 2025. August: 6,317 = 5,283 + 1,034. All 12 months match final FY2022–FY2025 and current AOR releases. |
| FY2026 monthly table | data/raw/nationwide.html; [original](https://www.cbp.gov/newsroom/stats/nationwide-encounters) | All 11 available months Oct 2025–Aug 2026 reconcile exactly. August: 8,870 = 7,624 + 1,246. |
| Final FY2021–FY2024 release, October 2024 | data/raw/fy21-fy24-aor.csv; [original](https://www.cbp.gov/sites/default/files/2024-10/nationwide-encounters-fy21-fy24-aor.csv) | Historical file already contains the total rather than At Entry alone in all 12 FY2024 months. This rules out a newly introduced FY2026 addition for these observations. |
| Early FY2024 release, January 2024, through December 2023 | data/raw/fy21-fy24-dec2023-aor.csv; [original](https://www.cbp.gov/sites/default/files/assets/documents/2024-Jan/nationwide-encounters-fy21-fy24-dec-aor.csv) | October/November/December totals are 188,778 / 191,112 / 249,785. Later totals are lower by 29 / 6 / 45, respectively. These are release differences, not evidence of a new inclusion rule. No contemporary entry/large split accompanies this raw file. |
| FY2020–FY2023 AOR and FY2017–FY2020 tables / FY2017–FY2018 PDF | Previously saved raw files and manifest URLs | Totals reconcile, but neither this arithmetic nor the southwest label proves that interior events were excluded. These sources lack an entry/large split. |
| Historical webpage capture dated June 21, 2025 | [archived CBP page](https://archive.li/2025.06.21-201312/https%3A/www.cbp.gov/newsroom/stats/nationwide-encounters) | The rendered archive shows the split going back to October 2023 before FY2026. Read through web retrieval; raw archive download returned 429 and is not claimed as a saved raw source. Corroboration only; current official tables and historical CSVs control the quantitative audit. |
| DHS OHSS KHSM dictionary, May 2026 | data/raw/ohss-cbp-dictionary.xlsx, KHSM CBP Dictionary sheet; [original](https://ohss.dhs.gov/system/files/2026-05/Data-Dictionary-KHSM-CBP-Encounters.xlsx) | Sector denotes a geographic USBP operational area; Region has a separate Air Ports of Entry/Interior value. This is a different report/schema and cannot establish that the CBP portal's Southwest Land Border category excludes At Large. No entry/large field or introduction date is supplied. |

## What the classifications do and do not establish

CBP's FY2024/FY2025/FY2026 tables define At Entry by whether a person who entered without admission has reached their destination, without a time-since-entry limit. At Large includes people who have already reached their destination and legally admitted people who overstayed. These are USBP enforcement classifications, not OFO encounters at official ports of entry, and not a border-versus-interior location flag. At Entry may be recorded inland or after the crossing month. Dropping At Large removes that category; it does not prove that every remaining event happened on the border or in the month of entry.

The published At Entry classification supplies a consistent comparison from **October 2023 through August 2026**, subject to ordinary revisions and any undocumented implementation changes. It is **not** a comparable continuation of earlier unsplit totals, because those totals' At Entry/At Large composition is unavailable. No exact start month for At Large inclusion, historical exclusion rule, or retrospective split before October 2023 was established by the inspected definitions/releases/tables.

The guessed prior-year URLs `nationwide-encounters-fy2021`, `fy2022` and `fy2023` returned 404. Searches for prior split tables and an older/different CBP portal dictionary did not find an authoritative start-date statement. These access/search results are limits on the evidence, not proof of absence or zero interior events.

## Quantification and corrected project behavior

`data/processed/scope_monthly_differences.csv` contains all 35 confirmed months: Total, At Entry, At Large, Total−At Entry, daily rates, difference per day, At Large as a percentage of Total, and Total's excess over At Entry. `scope_evidence_coverage.csv` preserves the remaining 81 months as unknown for this split. `scope_release_reconciliation.csv` contains every available release/table overlap, including early-release revisions.

The full published-total series is retained in `reported_total_series.csv` and is used throughout `monthly_encounters.csv` and both main charts. The timeline connects all 116 monthly totals. The term chart indexes monthly daily totals to January 2017, January 2021 and January 2025, respectively. Neither chart switches to At Entry. October 2023 marks **earliest verified split availability**, not an official counting-rule change. Historical interior consistency remains unconfirmed, and both chart footers state that limitation.

`at_entry_sensitivity.csv` preserves the 35-month classification separately as a supporting sensitivity check. It is not established as a comparable continuation of earlier unsplit totals. `presidential_term_index.csv` retains the 28 unavailable second-term observations after August 2026 as missing.

For comparable At Entry counts, August 2026 is 245.94/day, versus 1,828.26/day in August 2024 and 170.42/day in August 2025: −86.5% and +44.3%, respectively. The At Entry peak in the verified split window is December 2023, 7,912.10/day; August 2026 is 96.9% lower. This narrower comparison window is distinct from a claim about a harmonized 2017–2026 peak.

The source manifest and retrieval script include the new official evidence. Existing raw sources are unchanged. Run `analysis.R` to reproduce the audit, monthly dataset and charts. `scripts/scope_audit.R` can also run separately to regenerate the evidence tables.
