# data/ — GIS File Layout

**Guiding principle:**
- `raw/` — data that originates *outside* this analysis. You didn't compute
  it; you obtained it from an external source (UGRC, UTA, QGIS).
- `processed/` — data *computed by this R script*, regardless of whether the
  computation happened in a loop, via an API call, or as a simple derivation.

Both folders are **tracked in git** so the repo is self-contained and GitHub
Actions CI never needs to re-hit the ORS API.

---

## What is NOT in this repo

The following layers are fetched and cached automatically by `tigris` /
`tidycensus` — they are never committed because any machine can reproduce
them with a single R function call:

| Layer | Fetched by |
|-------|-----------|
| SLCo block group polygons + ACS attributes | `tidycensus::get_acs(geography = "block group", geometry = TRUE, ...)` |
| SLCo county boundary | `tigris::counties(state = "UT", cb = TRUE)` |
| SLCo census tracts | `tigris::tracts(state = "UT", county = "Salt Lake")` |

`tigris` caches downloads in `~/.cache/tigris/` after the first run
(enabled via `options(tigris_use_cache = TRUE)`), so subsequent renders
are instant without any network call.

---

## data/raw/ — External source files

These files were **obtained from outside this analysis** — from UGRC, UTA,
or derived in QGIS as a pre-processing step before this R script was written.
They are inputs to the analysis, not outputs of it.

```
Files to copy from H:\...\Term Project\Data\   →   data/raw/
──────────────────────────────────────────────────────────────────────────────
# UTA/UGRC light rail data (5 sidecar files each: .cpg .dbf .prj .shp .shx)
LightRailStations_UTA_3566.*                   →   data/raw/
LightRail_UTA_3566.*                           →   data/raw/

# QGIS-computed isochrones (pre-analysis, not from this R script)
Isochron_walking.*                             →   data/raw/
Isochron_dissolved.*                           →   data/raw/

# Manually assembled equity indicators spreadsheet
Equity_Indicators.csv                          →   data/raw/
```

### Required attributes on `LightRailStations_UTA_3566.shp`

| Column | Type | Description |
|--------|------|-------------|
| `OBJECTID` | Integer | Unique station ID |
| `STATIONNAM` | String | Station name |
| `AvgRider` | Double | Average daily ridership |
| `ServCapaCT` | Double | Service capacity (seats × cars × daily departures) |
| `Boarding` | Double | Average daily boardings |
| `Alighting` | Double | Average daily alightings |

> `ServCapaCT` was computed as 70 seats × 3 cars/train × daily departures.
> If missing from the UGRC download, add it before running the 2SFCA step:
> ```r
> trax_stn <- trax_stn |> mutate(ServCapaCT = 70 * 3 * daily_freq)
> ```

### Data sources

| Layer | Source |
|-------|--------|
| TRAX Stations & Lines | [UGRC SGID — Light Rail](https://gis.utah.gov/products/sgid/transportation/light-rail/) |
| Ridership (`AvgRider`, `ServCapaCT`) | [UTA Stops & Most Recent Ridership dataset](https://www.rideuta.com/) |
| Isochron_walking / Isochron_dissolved | Computed in QGIS via ORS QGIS plugin (pre-dates this R script) |

---

## data/processed/ — Script-computed outputs (copy from your local project)

Every file here was **written by the R script** — either derived spatially
(`st_centroid`, `st_join`) or fetched via the ORS API isochrone loops.
They are committed so that subsequent renders (locally and on GitHub Actions)
load from disk and skip all API calls.

The `if (!file.exists(...))` guards in `index.qmd` enforce this: if the
file exists on disk it is loaded with `st_read()`; otherwise the computation
runs and the result is written with `st_write()`.

```
Files to copy from H:\...\Term Project\Data\   →   data/processed/
──────────────────────────────────────────────────────────────────────────────
# Derived by st_centroid() from ACS block groups
blockgrp_centroid.*                            →   data/processed/

# ORS API isochrone loops (the expensive step — ~30 min to recompute)
trax_iso.*                                     →   data/processed/
blockgrp_iso.*                                 →   data/processed/

# 2SFCA accessibility surface (joined block groups + scores)
TSFCA_Network.*                                →   data/processed/

# LISA cluster assignments
LISA.*                                         →   data/processed/
```

### If blockgrp_iso.shp exceeds 50 MB

Run once to migrate it to Git LFS before your first push:

```bash
git lfs install
git lfs track "data/processed/blockgrp_iso.shp"
git lfs track "data/processed/blockgrp_iso.dbf"
git add .gitattributes
```

All subsequent `git push` and `git clone` operations will handle it
transparently.