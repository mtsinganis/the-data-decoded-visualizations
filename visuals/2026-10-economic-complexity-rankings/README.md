# Economic complexity rankings, 1995–2024

Unpublished project for The Data Decoded. `story.md` owns website metadata and reader-facing prose; `post.md` contains synchronized X ALT text. The final chart displays **all 145 economies**, using their available observations: **four highlights and 141 grey trajectories**. Venezuela is grey and unlabeled. The selective 49-country export and its preview have been deleted and are no longer generated.

## Reproduce

From the repository root in PowerShell:

```powershell

& 'C:\Program Files\R\R-4.5.2\bin\Rscript.exe' visuals/2026-10-economic-complexity-rankings/analysis.R

```

Or from R with the repository as working directory:

```r

source('visuals/2026-10-economic-complexity-rankings/analysis.R', encoding='UTF-8')

```

The orchestrator runs acquisition, validation/analysis, and rendering scripts. Required packages and the existing R environment are recorded in `data/session-info.txt`; no renv configuration was found. Cached source files are checksum-verified by default. Set `TDD_REFRESH=1` to retrieve the same pinned version again; download failures are explicit and never silently substitute fabricated or partial rows. The website does not run R. PNG rendering uses a temporary file and checks replacement succeeds before copying the full chart to the final filename.

## Source and audit

[Harvard Growth Lab, Growth Projections and Complexity Rankings, version 12.0](https://doi.org/10.7910/DVN/XTAQMC), released February 8, 2026, accessed October 12, 2026. [Official CSV](https://dataverse.harvard.edu/api/access/datafile/13439575), [dictionary](https://dataverse.harvard.edu/api/access/datafile/13439574), and [pinned metadata](https://dataverse.harvard.edu/api/datasets/:persistentId/versions/12.0?persistentId=doi:10.7910/DVN/XTAQMC). URLs, access date, SHA-256, and CC0 license metadata are retained. The official CSV's MD5 also matches Harvard's metadata.

Use only `eci_hs92` and `eci_rank_hs92` across the complete 1995–2024 vintage. The [Nations Inquiry compilation](https://nationsinquiry.com/datasets/economic-complexity/) supplies display names and an exact cross-check of all 4,319 ranked country-year values. Its source-note preamble is parsed automatically by locating the actual header. Official country IDs and ISO3 codes are retained separately from display labels.

There are no duplicate country-years or published rank ties. Rounded ECI scores sometimes tie; original ranks are not recalculated. Each highlight has 30 annual observations. Coverage is 140 economies in 1995–1999, 144 in 2000–2005, and 145 from 2006 onward. No aggregate regions or income groups enter the chart. The actual CSV includes 2024 even though the descriptive Dataverse coverage field still ends at 2023. All 145 unique economies are drawn where data exists; absent observations are not invented. Country trajectories are split at gaps.

`audit.json`, `mirror_crosscheck.csv`, `coverage_by_year.csv`, `endpoint_checks.csv`, `rounded_score_ties.csv`, and `unranked_observations.csv` provide inspectable evidence.

## Highlighted trajectories

| Country | 1995 rank | 2024 rank | Net movement | Total absolute annual movement | ECI 1995 | ECI 2024 |

|---|---:|---:|---:|---:|---:|---:|

| Vietnam | 119 | 44 | Up 75 | 95 | -0.968 | 0.672 |

| China | 42 | 10 | Up 32 | 48 | 0.628 | 1.271 |

| Philippines | 69 | 38 | Up 31 | 89 | 0.128 | 0.739 |

| Australia | 33 | 73 | Down 40 | 80 | 0.768 | 0.131 |

The four highlights contrast rising manufacturing-export complexity with Australia's export-based relative decline. None is a monotonic trajectory. Their score changes support direction without measuring a cardinal quantity of know-how. `highlighted_trajectories.csv`, `annual_movements.csv`, and `trajectory_summary.csv` retain all annual values, score changes, greatest improvements/deteriorations, total movement, and reversals.

China passed Australia between 1997–1998. Vietnam passed Australia between 2013–2014, fell behind between 2014–2015, and passed again between 2015–2016. The Philippines passed Australia between 2009–2010. There are no crossings between China, Vietnam, and the Philippines. `crossover_analysis.csv` contains every observed order reversal. These intervals are not precisely dated intra-year events.

## Final design and annotations

`plots/chart_final.png` is the full-background chart, 3,283 × 3,317 pixels at 400 dpi (approximately 8.209 × 8.294 inches). `chart_background_full.png` is an identical copy. `chart_final.svg` contains editable text, embedded Lato 400/700/900 fonts, and the existing vector pterosaur. Editors that ignore embedded fonts should use the repository's Lato files. No chart contains creator-name credit.

The approved plotting spans, 1.35 point size at the four highlighted 2024 endpoints, saturated country colors, line weights, and tight right margin are retained. All 141 background lines are solid #d4d4d4 (RGB channels rounded from #ebebeb × 0.9, a 10% darkening trial) at 0.14 mm. Vertical guides mark the year ticks; horizontal guides are absent. Both foreground and background are built with `ggbump::geom_bump(smooth=8)`. Curves stay within observed rank extrema and connect annual values rather than estimating monthly ranks. A local stat copy removes unused lag-join metadata to avoid ggbump multiplying smooth rows; it does not change the sigmoid calculation or installed package.

The exact requested headline reads: Since 1995, China and several other Asian economies have overtaken resource-rich Australia in economic complexity. China is colored green (#168765) and Australia brand blue in the headline. Vietnam uses #8056B3, China #168765, and Australia uses #2455FF and the Philippines #D08A28. Font-metric title slots use a tighter first-line descent allowance so actual visible title gaps remain compact. Subtitle and Notes wording follow the latest request exactly. Source and Notes use bold labels, one space, regular text, and flush-left continuation lines above the faint signature divider.

Four regular Lato annotations (12.5pt, with the Philippines at 12pt and slightly tighter leading to clear China at the requested coordinates) use exact requested wording and their respective country's color. Australia is left-aligned at year-coordinate 2012.5 and rank 82; the Philippines annotation is at year-coordinate 2009.5 and rank 30. Explicit coordinates and two-line wrapping are recorded in `data/annotation_layout.csv` and the rendering script. They are broad contextual statements, without arrows, connectors, boxes, borders, fills, or repeated country names. The positions are staggered and avoid all highlighted paths, markers, and endpoint labels; the dense full-country context inevitably runs faint grey trajectories behind some text. Placement has no temporal or causal meaning.

The supporting context sources are in `story.md`: World Bank Vietnam diversification discussions, Harvard Kennedy School's discussion of Chinese manufacturing sophistication, and Australian DFAT's 2024 leading exports. The annotations are not a statistical decomposition of the ranking changes.

## Limitations and QA

ECI measures goods-export diversity and sophistication, not wealth, quality of life, overall economic performance, or technology across the entire economy. Gross export baskets may contain imported inputs; export sophistication is not identical to domestic value added. Ranks and normalized scores are relative; coverage, concordances, reporting differences, revisions, and inclusion thresholds matter. Australia's commodity specialization is not evidence of generalized economic deterioration. The chart establishes no political, policy, or event-level causation.

R checks confirm 145 trajectories (141 grey, four colored), four exact highlighted endpoint points, and no curve overshoot. Browser export QA verifies font loading, equal point radii, editable text, and no clipped labels. The final native PNG and browser-rendered SVG have been visually inspected. `data/svg_qa.json`, `rendered_qa.json`, `font_audit.csv`, `header_metrics.csv`, `annotation_layout.csv`, and `plot_layout.csv` record export/layout checks. ALT text is synchronized in story/post and remains below X's 1,000-character limit.

## Complete annual highlighted ranks

| Year | Vietnam | China | Philippines | Australia |

|---|---:|---:|---:|---:|

| 1995 | 119 | 42 | 69 | 33 |

| 1996 | 106 | 42 | 73 | 35 |

| 1997 | 106 | 39 | 72 | 35 |

| 1998 | 101 | 36 | 74 | 40 |

| 1999 | 98 | 33 | 71 | 35 |

| 2000 | 98 | 33 | 66 | 42 |

| 2001 | 84 | 33 | 63 | 40 |

| 2002 | 86 | 33 | 61 | 38 |

| 2003 | 87 | 32 | 63 | 40 |

| 2004 | 82 | 32 | 61 | 44 |

| 2005 | 81 | 27 | 65 | 48 |

| 2006 | 77 | 26 | 59 | 48 |

| 2007 | 73 | 21 | 61 | 50 |

| 2008 | 75 | 20 | 61 | 52 |

| 2009 | 74 | 21 | 56 | 55 |

| 2010 | 70 | 20 | 51 | 59 |

| 2011 | 67 | 20 | 55 | 56 |

| 2012 | 64 | 17 | 47 | 60 |

| 2013 | 64 | 18 | 47 | 62 |

| 2014 | 62 | 14 | 47 | 65 |

| 2015 | 65 | 16 | 49 | 63 |

| 2016 | 59 | 14 | 45 | 61 |

| 2017 | 56 | 12 | 39 | 67 |

| 2018 | 56 | 12 | 39 | 65 |

| 2019 | 55 | 13 | 38 | 63 |

| 2020 | 52 | 11 | 44 | 63 |

| 2021 | 49 | 9 | 38 | 68 |

| 2022 | 51 | 11 | 36 | 71 |

| 2023 | 48 | 12 | 39 | 71 |

| 2024 | 44 | 10 | 38 | 73 |

## Supplemental Asian overtakers audit

Run scripts/04_asian_overtakers.R from the repository root after analysis.R. It screens all available Asian economies against Australia using the same annual HS92 ranks, distinguishing endpoint overtakers from temporary crossings. Geography follows the UN M49 Asia list (including Cyprus, Armenia, and Türkiye), with Taiwan included as a separately reported Atlas economy for geographic completeness. The classification snapshot is in data/asia_geography.csv; data/asian_australia_summary.csv and data/asian_australia_crossovers.csv retain endpoints and every consecutive-year crossing. Sixteen other countries start behind Australia in 1995 and end ahead in 2024; Jordan and Qatar also pass temporarily but finish below Australia in 2024. Georgia starts ahead in 1995, falls behind, and re-passes Australia three times; it ends ahead again. Countries already above Australia in 1995 are not counted as endpoint overtakers. Rankings remain relative; passing Australia can reflect Australia's movement as well as the other country's trajectory.

The footer now adds 0.11 inches of space below Notes, matching the compact border-encounters metadata/divider convention. The canvas grows vertically to preserve the plot and header geometry.

The Philippines annotation adds the exact text Growing specialization in electronics and semiconductor exports. Its placement is chosen for visual balance without implying an event date. Its supporting Department of Trade and Industry source is linked in story.md. Philippines and Vietnam endpoint label blocks are displaced slightly to separate the nearby #38 and #44 endpoints; their values and colors remain exact. Curve validation uses explicit country groups.

The plotting panel has received two successive 15% height increases (32.25% cumulatively), with unchanged width. Only this panel expansion increases canvas height; header, footer, logo, typography and spacing within those sections retain their previous physical dimensions.

The plotting panel is also 15% wider. Canvas width increases only by this panel expansion; header and footer wrapping, divider length, logo and all vertical dimensions retain their prior layout.

The latest revision reduces the current plotting panel by 10% in both dimensions. The fixed header, footer and logo remain unchanged; only the panel and canvas dimensions contract.

The latest headline wraps over three lines at the existing 22.5pt size. The additional header line increases canvas height while preserving the plotting panel and footer.

The title now keeps “Asian economies” together on the first line. Both versions retain the same title layout and canvas dimensions; the article continues to reference `chart_final.png`.

The title’s second line ends with “Australia in economic”; the third line is “complexity”.

All four highlighted countries use 0.8 mm lines. China and Australia retain their later drawing order. Grey background lines remain 0.14 mm.


## Current two-chart output

The main `chart_final.png` / `.svg` highlights only China and Australia, with the requested industrial-rise/resource-boom headline and their two original annotations. `chart_asian_comparison.png` / `.svg` highlights Australia, the Philippines and Vietnam, retaining their three annotations. Both include all 145 trajectories, use 0.8 mm highlights and retain only 2024 endpoint points. Article metadata and ALT describe both charts; the article remains draft. This section supersedes the earlier four-highlight layout notes.

The second chart title is “Vietnam and the Philippines also overtook resource-rich Australia in economic complexity since 1995”.

The main chart headline is “China's industrial rise fueled Australia's resource boom as its economic complexity ranking fell.”
