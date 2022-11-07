rm(list=ls())
library(MASS)

# 경로 설정 필요
setwd("C:/Users/prope/OneDrive/바탕 화면/데이터시각화 프로젝트/datasets (preprocessed)")

vote_8_male=read.csv("8회_지선_남성연령별_득표율.csv",header=T)
vote_8_female=read.csv("8회_지선_여성연령별_득표율.csv",header=T)

ratio_male=vote_8_male$투표율
ratio_female=vote_8_female$투표율

radius_male=(ratio_male/10)
radius_female=(ratio_female/10)

# 정당별 남성 득표율
symbols(vote_8_male$연령,vote_8_male$더불어민주당,
       circles=radius_male,
       inches=0.35,
       bg="blue",
       lwd=1.5,
       ylim=range(10,90),
       xlab="연령대",
       ylab="득표율",
       main="정당별 남성 득표율",
       sub="(원의 크기 = 투표율)")
par(new=TRUE)
symbols(vote_8_male$연령,vote_8_male$국민의힘,
        circles=radius_male,
        inches=0.35,
        bg="red",
        lwd=1.5,
        ylim=range(10,90),
        xlab="연령대",
        ylab="득표율")
par(new=FALSE)

# 정당별 여성 득표율
symbols(vote_8_female$연령,vote_8_female$더불어민주당,
        circles=radius_female,
        inches=0.35,
        bg="blue",
        lwd=1.5,
        ylim=range(10,90),
        xlab="연령대",
        ylab="득표율",
        main="정당별 여성 득표율",
        sub="(원의 크기 = 투표율)")
par(new=TRUE)
symbols(vote_8_female$연령,vote_8_female$국민의힘,
        circles=radius_female,
        inches=0.35,
        bg="red",
        lwd=1.5,
        ylim=range(10,90),
        xlab="연령대",
        ylab="득표율")