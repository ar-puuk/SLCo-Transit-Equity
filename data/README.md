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

## data/raw/ — External source files (copy manually)

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
file exists on disk it is loaded; otherwise the computation runs and the
result is written.

### File formats

| Format | Why | Files |
|--------|-----|-------|
| `.shp` (+ sidecars) | Standard interchange format for pure geometry layers with simple column names | `trax_iso.*`, `blockgrp_iso.*` |
| `.rds` | R's native binary format — **preserves all column names** (no 10-char truncation), CRS, and sf class | `TSFCA_Network.rds`, `LISA.rds` |

> **Why not `.shp` for everything?** Shapefile field names are truncated to
> 10 characters. `TSFCA_Network` and `LISA` inherit all the long ACS column
> names from `slco_blockgrp` (e.g. `total_popE`, `pop_hispanicE`, `age1E`…).
> Loading a `.shp` version of these would silently truncate those names and
> break every downstream regression and correlation call. `.rds` has no such
> limit and is faster to read/write.

### Files to copy

```
Local project (H:\...\Term Project\Data\)    →   data/processed/
──────────────────────────────────────────────────────────────────────────────
trax_iso.*          (.dbf .prj .shp .shx)    →   data/processed/
blockgrp_iso.*      (.dbf .prj .shp .shx)    →   data/processed/
```

For `TSFCA_Network` and `LISA`: these must be **re-saved as `.rds`** from your
local R session before copying, because the files you have on disk are `.shp`
(old format). Run this once locally:

```r
# Run in your local R session with the old .shp files available
library(sf)
library(tidycensus)

# Re-run the 2SFCA computation with slco_blockgrp in memory
# (or load the .shp and re-join to slco_blockgrp to restore column names)
# Then:
saveRDS(TSFCA_network, "data/processed/TSFCA_Network.rds")
saveRDS(LISA,          "data/processed/LISA.rds")
```

### If blockgrp_iso.shp exceeds 50 MB

```bash
git lfs install
git lfs track "data/processed/blockgrp_iso.shp"
git lfs track "data/processed/blockgrp_iso.dbf"
git add .gitattributes
```
