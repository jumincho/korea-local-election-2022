rm(list=ls())

library(agricolae)
library(gridExtra)

setwd("C:/Users/prope/OneDrive/바탕 화면/데이터시각화 프로젝트/datasets (preprocessed)")
minju = read.csv("minju.csv")
kukmin = read.csv("kukmin.csv")
cido = c("서울특별시", "부산광역시", "대구광역시", "인천광역시", "광주광역시", "대전광역시", "울산광역시", "세종특별자치시", "경기도", "강원도", "충청북도", "충청남도", "전라북도", "전라남도", "경상북도", "경상남도", "제주특별자치도")

minjuPlot = ggplot(minju, aes(x=지역, y=투표율, fill=선거)) +
  geom_bar(position = position_dodge(0.5),
           stat = "identity", size=.2, width=0.4) +
  scale_fill_manual(labels = c("7회 지선", "8회 지선"), values=c("skyblue", "blue")) +
  scale_x_discrete(limits=cido) + ggtitle("더불어민주당 투표결과(7회지선, 8회지선)")

kukminPlot = ggplot(kukmin, aes(x=지역, y=투표율, fill=선거)) +
  geom_bar(position = position_dodge(0.5),
           stat = "identity", size=.2, width=0.4) +
  scale_fill_manual(labels = c("7회 지선", "8회 지선"), values=c("pink", "red")) +
  scale_x_discrete(limits=cido) + ggtitle("자유한국당, 국민의힘 투표결과(7회지선, 8회지선)")

grid.arrange(minjuPlot, kukminPlot, nrow=2)