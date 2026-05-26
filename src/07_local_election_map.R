rm(list=ls())

# 지도 작성을 위한 library load
# (rgeos / maptools 는 CRAN retired — raster::shapefile() 로 대체)
library(ggmap)
library(ggplot2)
library(raster)

# 한국 시·도 행정경계 shapefile
korea     = shapefile("data/shapefiles/ctp_rvn.shp")
korea     = spTransform(korea, CRS("+proj=longlat"))
korea_map = fortify(korea)

# 7회 지선 dataset load
local7 = read.csv("data/07_local_vote_share.csv", header=TRUE, fileEncoding="UTF-8")
local7 = local7[1:17, ]
local7$id = 0:16     # shapefile fortify 의 polygon id 와 매칭 (서울→제주 순서 가정)
local7$win = local7$더불어민주당 - local7$자유한국당
local7$win[local7$win > 0] = 'c'   # 더불어민주당 우세
local7$win[local7$win < 0] = 'a'   # 자유한국당 우세
local7$win[local7$시도 == "제주특별자치도"] = 'b'   # 제주: 원희룡(무소속) 재선
merge_local7 = merge(korea_map, local7, by="id")

# 7회 지선 결과 지도로 그리기
ggplot() +
  geom_polygon(data=merge_local7,
               aes(x=long, y=lat, group=group, fill=win),
               col='black') +
  ggtitle(label = "제 7회 전국동시지방선거 결과") +
  labs(fill = "최다 득표 당") +
  scale_fill_manual(labels = c("자유한국당", "무소속", "더불어민주당"),
                    values = c("a"="red", "b"="gray", "c"="blue"))
