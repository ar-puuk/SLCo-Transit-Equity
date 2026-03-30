# Transit Equity in Salt Lake County

**Does UTA-TRAX moderate social equity in Salt Lake County, Utah?**

A reproducible GIS-based accessibility analysis using the Two-Step Floating Catchment Area (2SFCA) method, ACS 2015–2019 Census Block Group data, and spatial autoregressive models.

[![Render & Publish](https://github.com/ar-puuk/SLCo-Transit-Equity/actions/workflows/quarto-publish.yml/badge.svg)](https://github.com/ar-puuk/SLCo-Transit-Equity/actions/workflows/quarto-publish.yml)

📄 **Published Article:** Zinia, F. A., Bhandari, P., Tuffour, J. P., & Hong, A. (2023). Evaluating Social Equity of Transit Accessibility: A Case of Salt Lake County, U.S. Transportation Research Record: Journal of the Transportation Research Board, 2677(12), 806-814. [DOI: 10.1177/03611981231170005](https://doi.org/10.1177/03611981231170005)

🌐 **Live Report:** [ar-puuk.github.io/SLCo-Transit-Equity](https://ar-puuk.github.io/SLCo-Transit-Equity)

---

## Overview

This study examines whether the UTA-TRAX light rail system in Salt Lake County, Utah equitably serves socially vulnerable populations. We construct a spatial transit accessibility index using the 2SFCA method — based on 20-minute pedestrian isochrones from the OpenRouteService API — and evaluate its relationship with eight social equity indicators via spatial autoregressive models (Spatial Lag and Spatial Error).

**Key finding:** Vehicle-free households are the only equity variable with a statistically significant positive relationship with TRAX accessibility, confirming partial but incomplete service to transit-dependent populations.

---

## Repo Structure

```
SLCo-Transit-Equity/
│
├── index.qmd               ← Main Quarto document (all analysis + narrative)
├── _quarto.yml             ← Multi-format config (HTML, Typst/PDF, DOCX)
├── renv.lock               ← Pinned R package versions (run renv::restore())
├── .gitignore
├── README.md
├── SLCo-Transit-Equity.Rproj
│
├── R/                      ← Helper scripts sourced by index.qmd
│   ├── utils.R             ← Shared utility functions
│   ├── 2sfca.R             ← 2SFCA computation functions
│   └── spatial_models.R    ← Spatial weights + model wrappers
│
├── data/                   ← NOT tracked in git (see Data section below)
│   ├── raw/                ← Source shapefiles from UGRC / ACS
│   │   └── .gitkeep
│   └── processed/          ← Computed outputs (isochrones, TSFCA, LISA)
│       └── .gitkeep
│
├── maps/                   ← QGIS2Web Leaflet interactive HTML exports
│   ├── study-area/
│   ├── demand-supply/
│   ├── transit-accessibility/
│   └── lisa/
│
├── docs/                   ← Quarto rendered output (GitHub Pages source)
│   ├── index.html
│   ├── index.pdf
│   └── index.docx
│
├── references/
│   ├── references.bib      ← BibTeX bibliography
│   └── *.pdf               ← Archived literature
│
└── .github/
    └── workflows/
        └── quarto-publish.yml  ← CI/CD: render + deploy to GitHub Pages
```

---

## Data

**Spatial data is not tracked in this repository** because shapefiles exceed GitHub's 100MB file limit and are reproducible from public sources.

### Obtaining the Raw Data

Place all files in `data/raw/` before running the analysis.

| File | Source | Notes |
|------|--------|-------|
| `LightRailStations_UTA_3566.shp` | [UGRC](https://opendata.gis.utah.gov/datasets/utah::trax-light-rail-stations/about) | UTA TRAX station points, reprojected to EPSG:3566 |
| `LightRail_UTA_3566.shp` | [UGRC](https://opendata.gis.utah.gov/datasets/utah::uta-trax-light-rail-routes/about) | UTA TRAX route lines, reprojected to EPSG:3566 |
| ACS 2015–2019 (Block Group) | Retrieved via `tidycensus` | Automatically downloaded when you run `index.qmd` |

The processed outputs (`data/processed/`) are generated automatically during rendering. The main computationally expensive step — generating ~670 walking isochrones via the OpenRouteService API — is cached to disk on first run and skipped on subsequent renders.

---

## Reproducing the Analysis

### Prerequisites

- R ≥ 4.3
- Quarto ≥ 1.4 ([install](https://quarto.org/docs/get-started/))
- A U.S. Census API key ([register free](https://api.census.gov/data/key_signup.html))
- An OpenRouteService API key ([register free](https://openrouteservice.org/dev/#/login))

### Setup

```r
# 1. Clone the repo
#    git clone https://github.com/ar-puuk/SLCo-Transit-Equity.git

# 2. Open SLCo-Transit-Equity.Rproj in RStudio

# 3. Restore the package environment
install.packages("renv")
renv::restore()

# 4. Set your API keys (stored in ~/.Renviron, never committed)
tidycensus::census_api_key("YOUR_CENSUS_KEY", install = TRUE)
openrouteservice::ors_api_key("YOUR_ORS_KEY")
```

### Rendering

```bash
# HTML (default, includes interactive maps)
quarto render index.qmd --to html

# PDF via Typst
quarto render index.qmd --to typst

# Word document
quarto render index.qmd --to docx

# All three formats at once
quarto render index.qmd
```

---

## Interactive Maps

The QGIS2Web Leaflet exports in `maps/` are embedded in the HTML report as iframes. They can also be opened directly:

| Map | File |
|-----|------|
| Study Area & Population Density | `maps/study-area/index.html` |
| TRAX Demand vs. Supply | `maps/demand-supply/index.html` |
| Transit Accessibility (2SFCA) | `maps/transit-accessibility/index.html` |
| LISA Clusters | `maps/lisa/index.html` |

---

## Authors

- **Faria Afrin Zinia** — University of Utah, Department of City & Metropolitan Planning
- **Pukar Bhandari** — University of Utah, Department of City & Metropolitan Planning
- **Justice Prosper Tuffour** — University of Utah, Department of City & Metropolitan Planning
- **Andy Hong** — University of Utah, Department of City & Metropolitan Planning & Healthy Aging and Resilient Places Lab

*CMP 6455 — Advanced GIS Applications, Spring 2022. Instructor: Andy Hong.*

---

## Citation

```bibtex
@article{doi:10.1177/03611981231170005,
author = {Faria Afrin Zinia and Pukar Bhandari and Justice Prosper Tuffour and Andy Hong},
title = {Evaluating Social Equity of Transit Accessibility: A Case of Salt Lake County, U.S.},
journal = {Transportation Research Record},
volume = {2677},
number = {12},
pages = {806-814},
year = {2023},
doi = {10.1177/03611981231170005},
URL = {https://doi.org/10.1177/03611981231170005},
eprint = {https://doi.org/10.1177/03611981231170005},
abstract = { Addressing social equity in public transportation remains a key challenge for many cities and planning organizations. In this study, we examined social equity dimensions of accessibility to light rail transit (LRT) stations in Salt Lake County, U.S., by employing two novel methods. First, we used the two-step floating catchment area (2SFCA) method to examine the interactions between the demand and supply of the public transit service. Second, we developed geospatial models to account for spatial bias in transit equity analysis. Results showed little evidence of inequitable access to LRT stations in Salt Lake County. The accessibility to LRT stations appeared to be generally higher in the downtown and transit catchment areas with a higher concentration of low-income and ethnic minority populations. Furthermore, we found statistically significant associations between higher transit accessibility and households which are not homeowners, and/or do not own a private motor vehicle. Our findings suggest that transit investments in Salt Lake County could leverage substantial transportation accessibility opportunities to achieve an equitable and sustainable future. }
}
```

---

## License

Code: [MIT License](LICENSE)
Data: Original data sources retain their respective licenses (U.S. Census Bureau public domain; UGRC Open Data).
