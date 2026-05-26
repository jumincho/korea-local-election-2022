rm(list=ls())
library(MASS)

vote_8_male=read.csv("data/08_local_male_age_vote_share.csv",header=T)
vote_8_female=read.csv("data/08_local_female_age_vote_share.csv",header=T)

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
