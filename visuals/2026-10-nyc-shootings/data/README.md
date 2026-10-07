# Saved input provenance

- Source: NYPD, NYC Open Data, Shootings (2006–Present), dataset 5ucz-vwe8.
- Dataset page: https://data.cityofnewyork.us/Public-Safety/Shootings-2006-Present-/5ucz-vwe8
- Retrieval URL: https://data.cityofnewyork.us/api/views/5ucz-vwe8/rows.csv?accessType=DOWNLOAD
- Retrieval date (UTC): 2026-10-02.
- Snapshot: shootings_snapshot.csv.
- SHA-256: 0e6281a6bb657295c42044e2442a1c1f937e6c882ba064ac3695871b17d01793.
- Coverage: January 1, 2006–June 30, 2026; 24,310 records / unique INCIDENT_KEY values; no duplicate IDs or missing IDs/dates.
- Unit: unique shooting incidents, not shooting victims; dates use OCCUR_DATE.
- Verified 2026 cutoff: June 30; 322 first-half incidents matches NYPD's July 2 first-half announcement linked in story.md. Statistics are preliminary and may be revised.

The snapshot is preserved unchanged. nyc_shootings_original.R is the supplied original script, retained for provenance. analysis.R recreates annual_incident_counts.csv, january_june_comparison.csv, monthly_coverage.csv, monthly_incident_counts.csv and quality_checks.csv locally; those derived tables are intentionally untracked. The original reference images and intermediate typography trials remain preserved on the trial branch, outside this focused publication change. The documented 688 dataset / 688 NYPD prose / 687 NYPD table discrepancy is explained in story.md.
