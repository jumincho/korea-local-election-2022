<div align="center">

# korea-local-election-2022

**제8회 전국동시지방선거 R 시각화·분석**
**R-based visualization and analysis of Korea's 8th local election (June 2022)**

![Language](https://img.shields.io/badge/language-R-276DC3?logo=r&logoColor=white)
![Domain](https://img.shields.io/badge/domain-election%20analysis-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Year](https://img.shields.io/badge/year-2022-blue)

**한국어** · [English](#english)

</div>

---

## 개요

> 2022년 6월 1일 치러진 제8회 전국동시지방선거 결과를 R로 시각화·분석한 프로젝트

시·도별 정당 득표율을 한국 행정구역 shapefile에 매핑해 단계구분도(choropleth map)로
그리고, 직전 제7회 지방선거(2018) 및 제20대 대통령선거(2022)와의 표심 변화·
상관관계를 함께 살펴봅니다.

<img width="80%" src="https://user-images.githubusercontent.com/77545063/200377493-37fb592b-9b97-45d5-aebe-8c1c6c5861a1.png"/>

## 주요 분석

- **시·도별 단계구분도** — `data/shapefiles/ctp_rvn.shp`(시·도 경계)에 7회·8회 지선의 1·2위 정당
  득표 차를 매핑해, 한 장의 지도로 표심의 변화를 시각화
- **대선-지선 상관성** — 제20대 대선(2022.03)과 제8회 지선(2022.06) 사이
  더불어민주당·국민의힘 시·도별 득표율의 상관계수 산출 및 회귀선 표시
- **성별·연령별 득표율** — 8회 지선 출구조사 데이터로 남녀 연령대별 양당 득표율을
  버블 차트(원 크기 = 투표율)로 표현
- **기타 선출직 비율** — 기초자치단체장 / 광역의회의원 / 기초의회의원 당선자의
  정당 비율을 7회·8회 비교 3D 파이차트로 제시
- **지역별 정당 지지율 추이** — 17개 시·도를 가로축으로 두고 7회 → 8회 지선의
  더불어민주당·국민의힘 득표율 변화를 막대그래프로 비교

## 기술 스택

- **언어**: R
- **시각화**: `ggplot2`, `gridExtra`, `plotrix` (3D 파이차트), 기본 그래픽 (`symbols`, `plot`)
- **공간 데이터**: `sp` 기반 `raster`, `ggmap` — `ctp_rvn.shp`
  (`data/shapefiles/ctp_rvn.shp`, 시·도 행정경계) 로드 및 `+proj=longlat` 재투영
- **통계**: `MASS`, `agricolae`, 기본 `lm` / `cor` (회귀·상관분석)

## 데이터 출처

- 중앙선거관리위원회 선거통계시스템 ([info.nec.go.kr](http://info.nec.go.kr)) — 7회·8회
  지방선거, 제20대 대통령선거 시·도별 득표율 (`data/*.csv`)
- 국가공간정보포털 — 시·도 행정경계 shapefile (`data/shapefiles/ctp_rvn.*`)

## 프로젝트 구조

```
.
├── src/                                       # R 분석 스크립트
│   ├── 07_local_election_map.R                # 7회 지선 단계구분도
│   ├── 08_local_election_map.R                # 8회 지선 단계구분도
│   ├── presidential_local_correlation.R       # 대선-지선 상관성 분석
│   ├── vote_share_by_gender_age.R             # 성별·연령별 득표율 버블 차트
│   ├── other_elected_officials_ratio.R        # 기초/광역의회의원 당선자 비율
│   └── regional_party_support_trend.R         # 지역별 양당 지지율 변화
├── data/                                      # 데이터
│   ├── 07_local_vote_share.csv                #   전처리된 득표율 CSV
│   ├── 07_local_other_vote_share.csv
│   ├── 08_local_vote_share.csv
│   ├── 08_local_other_vote_share.csv
│   ├── 08_local_male_age_vote_share.csv
│   ├── 08_local_female_age_vote_share.csv
│   ├── 20th_presidential_vote_share.csv
│   └── shapefiles/                            #   시·도 행정경계 shapefile 번들
│       ├── ctp_rvn.shp                        #     (네 파일은 같은 디렉터리에
│       ├── ctp_rvn.shx                        #      같은 베이스네임으로 묶여
│       ├── ctp_rvn.dbf                        #      있어야 GDAL이 정상 로드)
│       └── ctp_rvn.prj
└── docs/
    └── presentation.pptx                      # 발표 슬라이드
```

## 실행 방법

RStudio 또는 R 콘솔에서 저장소 루트를 작업 디렉터리로 지정한 뒤 원하는 스크립트를
실행하면 됩니다. 모든 경로는 저장소 루트 기준 상대경로로 작성되어 있습니다.

```r
# 저장소 루트로 이동
setwd("/path/to/korea-local-election-2022")

# 필요 패키지 설치 (최초 1회)
install.packages(c(
  "ggplot2", "ggmap", "raster",
  "plotrix", "agricolae", "gridExtra"
))

# 분석 실행
source("src/08_local_election_map.R")
source("src/presidential_local_correlation.R")
```

이 프로젝트는 `raster::shapefile()` 만 사용하므로 CRAN에서 retired된
`rgeos` / `maptools` 는 필요하지 않습니다. 장기적으로는 `sf` 기반
마이그레이션이 권장됩니다.

## 발표 자료

- 발표 슬라이드: [`docs/presentation.pptx`](docs/presentation.pptx)

## 라이선스

[MIT License](./LICENSE)

---

<a name="english"></a>

## English

> R-based visualization and analysis of the 8th Korean local election held on June 1, 2022.

Maps province-level vote shares onto Korean administrative shapefiles as choropleths, and
compares them with the previous 7th local election (2018) and the 20th presidential election
(March 2022) to track regional vote-pattern shifts and correlations.

<img width="80%" src="https://user-images.githubusercontent.com/77545063/200377493-37fb592b-9b97-45d5-aebe-8c1c6c5861a1.png"/>

### Analyses

- **Province-level choropleth** — maps the 1st vs. 2nd party vote gap onto `data/shapefiles/ctp_rvn.shp` for both the 7th and 8th elections; one map shows the shift in voter sentiment.
- **Presidential-vs-local correlation** — correlation coefficients and regression lines between the 20th presidential election (2022.03) and the 8th local election (2022.06) by party (Democratic / People Power) at the province level.
- **Vote share by gender and age** — bubble chart of party support from the 8th local exit poll, broken out by gender × age band (bubble size = turnout).
- **Other elected positions** — 3D pie charts comparing the party mix of mayors / provincial council / municipal council winners across the 7th and 8th elections.
- **Regional party-support trend** — bar chart of the 7th → 8th delta in Democratic / People Power vote share for each of the 17 provinces.

### Stack

- **Language**: R
- **Visualization**: `ggplot2`, `gridExtra`, `plotrix` (3D pies), base graphics (`symbols`, `plot`)
- **Spatial**: `sp`-based `raster`, `ggmap` — loads `ctp_rvn.shp` and reprojects to `+proj=longlat`
- **Statistics**: `MASS`, `agricolae`, base `lm` / `cor`

### Data

- National Election Commission Election Statistics System ([info.nec.go.kr](http://info.nec.go.kr)) — 7th / 8th local + 20th presidential province-level vote shares (`data/*.csv`).
- National Spatial Data Infrastructure Portal — province administrative shapefile (`data/shapefiles/ctp_rvn.*`).

### Layout

```
.
├── src/                                       # R analysis scripts
│   ├── 07_local_election_map.R                # 7th local choropleth
│   ├── 08_local_election_map.R                # 8th local choropleth
│   ├── presidential_local_correlation.R       # presidential-local correlation
│   ├── vote_share_by_gender_age.R             # gender × age bubble chart
│   ├── other_elected_officials_ratio.R        # mayor / council party ratios
│   └── regional_party_support_trend.R         # regional party-support delta
├── data/                                      # data
│   ├── 07_local_vote_share.csv                #   preprocessed vote-share CSV
│   ├── 07_local_other_vote_share.csv
│   ├── 08_local_vote_share.csv
│   ├── 08_local_other_vote_share.csv
│   ├── 08_local_male_age_vote_share.csv
│   ├── 08_local_female_age_vote_share.csv
│   ├── 20th_presidential_vote_share.csv
│   └── shapefiles/                            #   province administrative shapefile bundle
│       ├── ctp_rvn.shp                        #     (the four files must sit together
│       ├── ctp_rvn.shx                        #      under the same basename for GDAL
│       ├── ctp_rvn.dbf                        #      to load them as one shapefile)
│       └── ctp_rvn.prj
└── docs/
    └── presentation.pptx                      # presentation slides
```

### Run

From RStudio or an R console, set the repo root as the working directory, then source the script you want. All paths are written relative to the repo root.

```r
# move to repo root
setwd("/path/to/korea-local-election-2022")

# install required packages (first time only)
install.packages(c(
  "ggplot2", "ggmap", "raster",
  "plotrix", "agricolae", "gridExtra"
))

# run an analysis
source("src/08_local_election_map.R")
source("src/presidential_local_correlation.R")
```

The project only uses `raster::shapefile()`, so the CRAN-retired
`rgeos` / `maptools` packages are not required. A migration to `sf`
is the recommended longer-term direction.

### Materials

- Presentation slides: [`docs/presentation.pptx`](docs/presentation.pptx)

### License

[MIT License](./LICENSE)
