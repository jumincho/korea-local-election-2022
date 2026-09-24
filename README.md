# korea-local-election-2022

Province-level analysis in R of South Korea's 8th local elections (June 2022),
compared with the 2018 local elections and the March 2022 presidential election.

[![CI](https://github.com/jumincho/korea-local-election-2022/actions/workflows/ci.yml/badge.svg)](https://github.com/jumincho/korea-local-election-2022/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![R 4.1+](https://img.shields.io/badge/R-4.1%2B-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)

![Winning party in each metropolitan mayor and governor race, 2018 and 2022](figures/01_winner_maps.png)

## Overview

On 1 June 2022 South Korea held its 8th nationwide local elections, less than
three months after the 20th presidential election. This project looks at the
results for the 17 metropolitan-level local governments (the "provinces": Seoul,
six metropolitan cities, Sejong and nine provinces):

- who won each metropolitan mayor and governor race, and by how much;
- how each main party's share changed from the 7th local elections in 2018;
- how closely the governor vote followed the presidential vote;
- exit-poll vote share by sex and age group;
- the party mix of the officials elected to municipal and council offices.

The data are tidy, documented tables with tests that tie them to the original
2022 files. The R code regenerates every figure and every number in this README.

## Key findings

Every number here is computed by `make figures` and stored in
[`results/key_statistics.csv`](results/key_statistics.csv), which CI checks on
every push. Provinces count equally, whatever their population.

- **Governor races.** In 2018 the Democratic Party of Korea (DPK) won 14 of the
  17 metropolitan mayor and governor races, the Liberty Korea Party (LKP) 2 and
  an independent 1 (Jeju). In 2022 the People Power Party (PPP) won 12 and the
  DPK 5. ([Figure 1](#1-winners-by-province))
- **Margins in 2022.** Two races were decided by less than 5 percentage points:
  Gyeonggi, where the DPK led by 0.15, and Daejeon, where the PPP led by 2.39.
  The widest leads were the DPK's 64.23 points in North Jeolla and the PPP's
  60.78 points in Daegu. ([Figure 2](#2-margins-in-2022))
- **Change since 2018.** The DPK's share of the governor vote fell in 15 of the
  17 provinces, by a median of 13.11 points; the largest fall was 24.14 points,
  in Sejong. It rose in North Jeolla and Jeju. The main conservative party's
  share (LKP in 2018, PPP in 2022) rose in all 15 provinces where it had a
  candidate both times: by 13.40 points in Gyeonggi at the least, and by 36.22
  in Jeju at the most, where an independent had won in 2018.
  ([Figure 3](#3-change-since-2018))
- **Presidential and governor votes.** Across provinces, each party's June 2022
  governor share closely followed its March 2022 presidential share: Pearson's
  r = 0.97 for the DPK (95% CI 0.93 to 0.99) and 0.98 for the PPP (0.96 to
  0.99), over 17 provinces. On an unweighted average, DPK governor candidates
  polled 3.0 points below the party's presidential share, and PPP candidates
  4.6 points above. ([Figure 4](#4-presidential-and-governor-votes))
- **2018 and 2022 governor votes.** Shares were less consistent between the two
  local elections: r = 0.77 for the DPK (0.46 to 0.91, 17 provinces) and 0.87
  for the LKP/PPP (0.64 to 0.96, 15 provinces).
  ([Figure 5](#5-2018-and-2022-governor-votes))
- **Exit poll.** Men and women differed most among voters in their 20s: men
  voted 65.1% PPP and 32.9% DPK, women 66.8% DPK and 30.0% PPP. The DPK led in
  5 of the 12 sex and age groups: men in their 40s and 50s, and women in their
  20s, 30s and 40s. Turnout ranged from 29.7% (men in their 20s) to 73.9% (men
  in their 60s and 70s, which share one figure in the source).
  ([Figure 6](#6-exit-poll-by-sex-and-age))
- **Local offices.** The DPK's share of municipal heads went from 66.81% in 2018
  to 27.88% in 2022, and the LKP/PPP's from 23.45% to 64.16%. On metropolitan
  and provincial councils the DPK's share went from 78.65% to 36.72%, and the
  LKP/PPP's from 16.53% to 61.57%. ([Figure 7](#7-local-offices-won))

## Figures

All figures are written to [`figures/`](figures) by
[`scripts/make_figures.R`](scripts/make_figures.R).

### 1. Winners by province

The party that won each metropolitan mayor and governor race, 2018 and 2022
(the map at the top of this page).

### 2. Margins in 2022

PPP share minus DPK share in each 2022 governor race, as a map and as ranked bars.

![PPP lead over DPK in each 2022 governor race](figures/02_margin_2022.png)

### 3. Change since 2018

Each main party's share in 2018 and 2022, one row per province.

![Governor vote share by province in 2018 and 2022](figures/03_swing_2018_2022.png)

### 4. Presidential and governor votes

Each province's share in the March 2022 presidential election against its share
in the June 2022 governor race, with the line y = x, the least-squares line and
Pearson's r.

![Presidential against governor vote share by province, 2022](figures/04_presidential_vs_local_2022.png)

### 5. 2018 and 2022 governor votes

The same comparison between the 2018 and 2022 governor races. The conservative
panel pairs the LKP in 2018 with the PPP in 2022.

![Governor vote share by province, 2018 against 2022](figures/05_local_2018_vs_2022.png)

### 6. Exit poll by sex and age

Vote share of the two main parties and turnout by sex and age group, from the
2022 exit poll.

![Exit-poll vote share and turnout by sex and age group](figures/06_exit_poll_2022.png)

### 7. Local offices won

The party mix of the officials elected in 2018 and 2022: heads of municipal
governments, members of metropolitan and provincial councils, and members of
municipal councils.

![Share of local offices won by party, 2018 and 2022](figures/07_elected_officials.png)

## Data

| Table | Contents | Source |
|---|---|---|
| [`vote_share.csv`](data/vote_share.csv) | Vote share of each candidate's party by province: governor races 2018 and 2022, presidential election 2022 | National Election Commission ([info.nec.go.kr](http://info.nec.go.kr)) |
| [`elected_officials_share.csv`](data/elected_officials_share.csv) | Party shares of the officials elected to three kinds of local office, 2018 and 2022 | National Election Commission |
| [`exit_poll_2022.csv`](data/exit_poll_2022.csv) | Vote share of the two main parties and turnout by sex and age group | Joint exit poll of the terrestrial broadcasters, as recorded in 2022 (not re-verified) |
| [`geo/provinces.geojson`](data/geo/provinces.geojson) | Simplified province boundaries | Province shapefile from 2022, cleaned and simplified here |
| [`provinces.csv`](data/provinces.csv), [`parties.csv`](data/parties.csv), [`elections.csv`](data/elections.csv), [`offices.csv`](data/offices.csv) | Lookups: codes, English and Korean names, labels, colours | |

The original 2022 files are kept unchanged in [`data-raw/`](data-raw), next to
the scripts that build the tidy tables from them, and a test checks that every
value came through unchanged. The things to know before using the data:

- Some minor candidates are missing, so a few races do not add up to 100.
  South Chungcheong's 2022 race adds up to 100.04, which suggests one mistyped
  value; it is kept as recorded.
- The exit-poll turnout is the same for the 60s and 70s groups in the source.
- The LKP had no candidate in Gwangju or South Jeolla in 2018, and Jeju's 2018
  race was won by an independent.
- The elected-officials figures are shares of seats, not of votes.

[`data/README.md`](data/README.md) has the full data dictionary, provenance and
[caveats](data/README.md#caveats).

## Methods

- **Joins use official province codes.** Every table and the boundaries share
  the two-digit province code (`CTPRVN_CD`), and the readers in
  [`R/data.R`](R/data.R) reject unknown codes, parties or elections. Nothing is
  matched by row order.
- **Definitions.** The winner is the candidate with the largest share. The
  *margin* is the PPP share minus the DPK share, in percentage points. The
  *change* is a party's share in 2022 minus its share in 2018, with the LKP
  (2018) and the PPP (2022) treated as one conservative party. Where a party had
  no candidate there is no share, and so no change: it is not counted as zero.
- **Correlations** are Pearson's r over provinces, with 95% confidence intervals
  from `cor.test()` and least-squares lines from `lm()`. Each province counts
  once, whatever its population. With 17 points (15 for the conservative
  2018-2022 comparison) the intervals are wide. The correlations describe the
  geography of the vote, not how individuals voted.
- **Boundaries.** Neighbouring provinces' borders in the source do not line up.
  They are cleaned into a proper coverage and simplified with a 200 m
  tolerance, one shared border at a time, so neighbours still meet exactly.
  This takes the file from 13 MB to 564 KiB and changes no province's area by
  more than 0.4%. See [`data/README.md`](data/README.md#boundaries).
- **Figures** use ggplot2 with English labels, so no CJK font is needed. DPK blue
  and LKP/PPP red stay distinct under simulated protanopia and deuteranopia;
  other parties are a neutral grey, and legends or direct labels always go with
  the colours.

## Project structure

```
.
├── R/                         functions, sourced by the scripts and the tests
│   ├── data.R                 read and validate the tidy data
│   ├── analysis.R             winners, margins, change, correlations
│   ├── summary.R              the key statistics quoted in this README
│   ├── theme.R                colours, ggplot2 theme, PNG output
│   └── plots.R                one function per figure
├── data/                      tidy data; see data/README.md
│   └── geo/provinces.geojson  simplified boundaries
├── data-raw/                  original inputs and the scripts that build data/
│   ├── original/              the 2022 CSV files, unchanged
│   └── shapefile/             the province boundary file, unchanged
├── scripts/make_figures.R     regenerates figures/ and results/
├── figures/                   the figures above (PNG, 200 dpi)
├── results/key_statistics.csv the numbers quoted above
├── tests/                     testthat suite; tests/testthat.R runs it
├── docs/presentation.pptx     presentation slides
├── DESCRIPTION                R dependencies
├── Makefile                   make data | figures | test | lint
└── .github/workflows/ci.yml   lint, test and rebuild on every push
```

## Reproduce

You need R 4.1 or later and the packages listed in [`DESCRIPTION`](DESCRIPTION).
On Ubuntu 24.04, which is what CI uses, all of them come from the Ubuntu
archive:

```sh
sudo apt-get install -y --no-install-recommends \
  r-base-core r-cran-sf r-cran-ggplot2 r-cran-dplyr r-cran-tidyr r-cran-readr \
  r-cran-patchwork r-cran-ggrepel r-cran-scales r-cran-testthat r-cran-lintr \
  r-cran-ragg r-cran-here
```

Elsewhere, install them from CRAN (sf needs GDAL, GEOS and PROJ; CRAN's macOS
and Windows builds include them):

```sh
Rscript -e 'install.packages("remotes"); remotes::install_deps(dependencies = TRUE)'
```

Then, from the repository root:

```sh
make figures   # figures/*.png and results/key_statistics.csv
make test      # the test suite
make lint      # lintr, with the settings in .lintr
make data      # rebuild data/ from the original files in data-raw/
```

Without `make`, run `Rscript scripts/make_figures.R` and `Rscript tests/testthat.R`.

## License

[MIT](LICENSE), © 2022 jumincho.
