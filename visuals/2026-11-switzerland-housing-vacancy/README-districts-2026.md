# 2026 Swiss housing vacancy by district

This standalone map uses the latest complete district-level series available at preparation (2026), from the FSO Empty Dwellings Census, centred on the published national rate of 0.93%. It does not overwrite the existing charts.

## Sources and join

- The [FSO dataset DF_LWZ_1, version 1.1.0](https://statistik.admin.ch/en/asset/36836250) contains annual vacancy rates by district and other geographic levels. `data/fso-district-rates-2026.csv` archives the district-coded rows of the 2026 API response, filtered to total room counts, all vacancy types and measure `RATE`. Original response: https://disseminate.stats.swiss/rest/data/CH1.LWZ,DF_LWZ_1,1.1.0/._T._T.RATE.A?startPeriod=2026&endPeriod=2026 (CSV via `Accept: application/vnd.sdmx.data+csv;version=2.0`). All 144 rows have a valid published rate and status A.
- [swisstopo swissBOUNDARIES3D, January 2026](https://www.swisstopo.admin.ch/en/landscape-model-swissboundaries3d), supplies the 2026 `tlm_bezirksgebiet` and `tlm_kantonsgebiet` polygons. The original 2026 GeoPackage archive is https://data.geo.admin.ch/ch.swisstopo.swissboundaries3d/swissboundaries3d_2026-01/swissboundaries3d_2026-01_2056_5728.gpkg.zip. Its 135 district polygons join directly to FSO district codes after removal of the `B_` prefix; no district-name matching is used. The simplified, two-dimensional derivative is stored as `data/swisstopo-districts-2026.gpkg`, with a 40-metre geometry simplification for an economical SVG.
- Nine FSO district-equivalent records have no corresponding administrative district polygon. For Uri, Obwalden, Nidwalden, Glarus, Zug, Basel-Stadt, Appenzell Innerrhoden, Neuchâtel and Geneva, the corresponding 2026 cantonal polygon is matched to the statistical district-equivalent code and included. The derived `geography_type` identifies these. No observations or areas are left unmatched. Lake areas follow the original swisstopo administrative polygons.
- `data/district-vacancy-rate-2026.csv` contains the year, district identifier and name, canton identifier and abbreviation, geography type, published percentage and observation status. The project’s archived national FSO series supplies the 2026 Swiss rate. Rates are annual snapshots on 1 June of dwellings offered for sale or long-term rent, not all unoccupied homes.

## Design and checks

The stepped red–neutral–blue palette uses the published Swiss 0.93% rate as its reference. Zürich (ZH), 0.11%, and Moutier (JU), 7.27%, are the district extremes. Seventy-four areas fall below the national rate, one equals it and 69 are above; these are area counts, not population-weighted proportions. Small districts remain difficult to identify at social-feed size; the CSV supplies exact values. The 40-metre simplification changes the drawing only, not the data or join.

Run `districts-2026-alternatives.R` from the repository root to create the stepped PNG and SVG using the archived CSV and simplified GeoPackage. To recreate the derived inputs, set `SWISSTOPO_2026_GPKG` to the extracted original GeoPackage and run `districts-2026-prepare.R`.

## Geographic diagnostic and stepped map

The nine areas are FSO statistical district-equivalent codes, not failed polygon joins. Each district-equivalent rate equals the independently archived 2026 canton rate. The [FSO 2026 geographic register](https://www.agvchapp.bfs.admin.ch/fr/kennzahlen/results?IncAlt=True&SnapshotDate=01.01.2026&Unit=Districts) uses these canton-equivalent codes. [swisstopo's district-boundary description](https://opendata.swiss/de/dataset/swissboundaries3d-bezirksgrenzen) explains the lack of conventional administrative districts in eight of them. Neuchâtel also appears as a single canton-equivalent unit in the 2026 FSO classification. Alternative subdivisions or municipalities can exist, including the differently named districts of Appenzell Innerrhoden; they are not the published district-level units in this dataset. Mapping municipality rates would be a different geographic analysis, not a repair to this join.

| Canton | Reason for representation | Geometry | Vacancy source | Appropriate? |
| --- | --- | --- | --- | --- |
| Uri | FSO canton-equivalent district code | Canton | FSO DF_LWZ_1, B_400 | Yes |
| Obwalden | FSO canton-equivalent district code | Canton | FSO DF_LWZ_1, B_600 | Yes |
| Nidwalden | FSO canton-equivalent district code | Canton | FSO DF_LWZ_1, B_700 | Yes |
| Glarus | FSO canton-equivalent district code | Canton | FSO DF_LWZ_1, B_800 | Yes |
| Zug | FSO canton-equivalent district code | Canton | FSO DF_LWZ_1, B_900 | Yes |
| Basel-Stadt | FSO canton-equivalent district code | Canton | FSO DF_LWZ_1, B_1200 | Yes |
| Appenzell Innerrhoden | FSO uses one canton-equivalent unit at this level; its other local districts use a different classification | Canton | FSO DF_LWZ_1, B_1600 | Yes |
| Neuchâtel | FSO 2026 district-level geography uses one canton-equivalent unit | Canton | FSO DF_LWZ_1, B_2400 | Yes |
| Geneva | FSO canton-equivalent district code | Canton | FSO DF_LWZ_1, B_2500 | Yes |

`districts-2026-alternatives.R` generates the stepped map. The seven mutually exclusive, right-closed bins are: ≤0.30% (4 areas), >0.30–0.60% (28), >0.60–0.93% (43), >0.93–1.50% (41), >1.50–2.50% (22), >2.50–5.00% (5), and >5.00% (1). Exactly 0.93% is in the third bin; Moutier is the sole area above 5%. Labels point to their corresponding geographic units.
