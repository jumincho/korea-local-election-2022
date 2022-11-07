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

#7회 지선 dataset load
setwd("C:/Users/prope/OneDrive/바탕 화면/데이터시각화 프로젝트/datasets (preprocessed)")
local7 = read.csv("7회_지선_득표율.csv")
local7$id = 0:16
local7$win = local7$더불어민주당 - local7$자유한국당
local7$win[local7$win > 0] = 'c'
local7$win[local7$win < 0] = 'a'
local7$win[17] = 'b'
merge_local7 = merge(korea_map, local7, by="id")

#7회 지선 결과 지도로 그리기
ggplot() + 
  geom_polygon(data=merge_local7, aes(x=long, y=lat, group=group, fill=win), col='black') + 
  ggtitle(label = "제 7회 지방 총선거 결과") + 
  labs(fill = "최다 득표 당") + 
  scale_fill_manual(labels = c("자유한국당", "기타", "더불어민주당"), values = c("red", "gray", "blue"))