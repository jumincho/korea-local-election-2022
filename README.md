# 제8회 전국동시지방선거 데이터 분석

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
실행합니다. 모든 경로는 저장소 루트 기준 상대경로로 작성되어 있습니다.

```r
# 예: 저장소 루트가 ~/code/analysis_of_the_8th_local_election_data 인 경우
setwd("~/code/analysis_of_the_8th_local_election_data")

# 필요 패키지 설치 (최초 1회)
install.packages(c(
  "ggplot2", "ggmap", "raster",
  "plotrix", "agricolae", "gridExtra"
))

# 분석 실행
source("src/08_local_election_map.R")
source("src/presidential_local_correlation.R")
```

> 본 프로젝트는 `raster::shapefile()` 만 사용하므로 CRAN retired 패키지인
> `rgeos` / `maptools` 는 더 이상 필요하지 않습니다. 장기적으로는 `sf` 기반
> 마이그레이션이 권장됩니다.

## 발표 자료

- 발표 슬라이드: [`docs/presentation.pptx`](docs/presentation.pptx)
