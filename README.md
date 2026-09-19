<div align="center">

# korea-local-election-2022

**R-based visualization and analysis of Korea's 8th local election (June 2022)**

![Language](https://img.shields.io/badge/language-R-276DC3?logo=r&logoColor=white)
[![Verify](https://github.com/jumincho/korea-local-election-2022/actions/workflows/verify.yml/badge.svg)](https://github.com/jumincho/korea-local-election-2022/actions/workflows/verify.yml)
![Domain](https://img.shields.io/badge/domain-election%20analysis-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Year](https://img.shields.io/badge/year-2022-blue)

</div>

---

## Overview

Maps province-level vote shares from the 8th Korean local election (June 1, 2022)
onto Korean administrative shapefiles as choropleths, and compares them with the
previous 7th local election (2018) and the 20th presidential election (March 2022)
to track regional vote-pattern shifts and correlations.

<img width="80%" src="https://user-images.githubusercontent.com/77545063/200377493-37fb592b-9b97-45d5-aebe-8c1c6c5861a1.png" alt="choropleth of the 8th local election"/>

## Analyses

| Script | Output |
|---|---|
| [`src/07_local_election_map.R`](src/07_local_election_map.R) | 7th local election choropleth |
| [`src/08_local_election_map.R`](src/08_local_election_map.R) | 8th local election choropleth |
| [`src/presidential_local_correlation.R`](src/presidential_local_correlation.R) | Pearson r + regression for 20th presidential vs 8th local, and 7th vs 8th local |
| [`src/regional_party_support_trend.R`](src/regional_party_support_trend.R) | Province-level 7th → 8th vote-share delta bars for the two major parties |
| [`src/vote_share_by_gender_age.R`](src/vote_share_by_gender_age.R) | 8th exit-poll bubble chart by gender × age (bubble size = turnout) |
| [`src/other_elected_officials_ratio.R`](src/other_elected_officials_ratio.R) | 3D pies of party mix for mayors / provincial councils / municipal councils, 7th vs 8th |

All figures are written to `figures/` on run.

## Tech stack

- **Language**: R
- **Visualization**: `ggplot2`, `gridExtra`, `plotrix` (3D pies), base graphics (`symbols`, `plot`, `abline`)
- **Spatial**: `raster` + `sp` — loads `data/shapefiles/ctp_rvn.shp` and reprojects to `+proj=longlat`
- **Statistics**: base `lm` / `cor`
- **Utility**: `here` (repo-relative paths)

## Data

- National Election Commission Election Statistics System ([info.nec.go.kr](http://info.nec.go.kr)) — 7th / 8th local and 20th presidential province-level vote shares (`data/*.csv`).
- National Spatial Data Infrastructure Portal — province administrative shapefile (`data/shapefiles/ctp_rvn.*`).

## Project layout

```
.
├── src/
│   ├── _helpers.R                         # shared loader/saver utils + 17-province constant
│   ├── 07_local_election_map.R            # 7th choropleth
│   ├── 08_local_election_map.R            # 8th choropleth
│   ├── presidential_local_correlation.R   # presidential-local correlation
│   ├── regional_party_support_trend.R     # province-level party-support delta
│   ├── vote_share_by_gender_age.R         # gender × age bubble chart
│   ├── other_elected_officials_ratio.R    # mayor / council 3D pies
│   └── run_all.R                          # runs every script in order
├── data/
│   ├── 07_local_vote_share.csv            # 7th local: two-party vote share by province
│   ├── 07_local_other_vote_share.csv      # 7th local: party mix of mayors / councils
│   ├── 08_local_vote_share.csv
│   ├── 08_local_other_vote_share.csv
│   ├── 08_local_male_age_vote_share.csv   # 8th local: male vote share by age group
│   ├── 08_local_female_age_vote_share.csv # 8th local: female vote share by age group
│   ├── 20th_presidential_vote_share.csv   # 20th presidential: vote share by province
│   └── shapefiles/                        # province boundaries (.shp/.shx/.dbf/.prj)
│       └── ctp_rvn.*
├── figures/                               # generated on run (gitignored)
└── docs/
    └── presentation.pptx                  # presentation deck
```

## Run

```bash
# 1) Install required packages (first time only)
Rscript -e 'install.packages(c("here", "ggplot2", "raster", "sp", "plotrix", "gridExtra"))'

# 2) Run all analyses — writes PNGs under figures/
Rscript src/run_all.R

# Or run individual scripts in RStudio:
#   setwd("/path/to/korea-local-election-2022")
#   source("src/08_local_election_map.R")
```

The project only uses `raster::shapefile()`, so the CRAN-retired
`rgeos` / `maptools` packages are not required. A migration to `sf`
is the recommended longer-term direction.

## Materials

- Presentation slides: [`docs/presentation.pptx`](docs/presentation.pptx)

## License

[MIT License](./LICENSE)
