rm(list=ls())

#지도 작성을 위한 library load
library(ggmap)
library(ggplot2)
library(raster)
library(rgeos)
library(maptools)

#한국 지도 작성
korea = shapefile("ctp_rvn.shp")
korea = spTransform(korea, CRS("+proj=longlat"))
korea_map = fortify(korea)

#8회 지선 dataset load
setwd("C:/Users/prope/OneDrive/바탕 화면/데이터시각화 프로젝트/datasets (preprocessed)")
local8 = read.csv("8회_지선.csv")
local8$id = 0:16
local8$win = local8$더불어민주당 - local8$국민의힘
local8$win = local8$win > 0
merge_local8 = merge(korea_map, local8, by="id")

#8회 지선 결과 지도로 그리기
ggplot() + 
  geom_polygon(data=merge_local8, aes(x=long, y=lat, group=group, fill=win), col='black') + 
  ggtitle(label = "제 8회 지방 총선거 결과") + 
  labs(fill = "최다 득표 당") + 
  scale_fill_manual(labels = c("국민의힘", "더불어민주당"), values = c("red", "blue"))