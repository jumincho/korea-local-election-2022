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

# 8회 지선 dataset load
local8 = read.csv("data/08_local_vote_share.csv", header=TRUE, fileEncoding="UTF-8")
local8 = local8[1:17, ]
local8$id = 0:16     # shapefile fortify 의 polygon id 와 매칭 (서울→제주 순서 가정)
local8$win = ifelse(local8$더불어민주당 - local8$국민의힘 > 0, "민주", "국힘")
merge_local8 = merge(korea_map, local8, by="id")

# 8회 지선 결과 지도로 그리기
ggplot() +
  geom_polygon(data=merge_local8,
               aes(x=long, y=lat, group=group, fill=win),
               col='black') +
  ggtitle(label = "제 8회 전국동시지방선거 결과") +
  labs(fill = "최다 득표 당") +
  scale_fill_manual(labels = c("국민의힘", "더불어민주당"),
                    values = c("국힘"="red", "민주"="blue"))
