rm(list=ls())

vote_8_male   = read.csv("data/08_local_male_age_vote_share.csv",   header=TRUE, fileEncoding="UTF-8")
vote_8_female = read.csv("data/08_local_female_age_vote_share.csv", header=TRUE, fileEncoding="UTF-8")

# 원의 크기 = 투표율 (% 값을 시각적으로 적절한 반지름으로 스케일)
radius_male   = vote_8_male$투표율   / 10
radius_female = vote_8_female$투표율 / 10

xrange_male   = range(vote_8_male$연령)
xrange_female = range(vote_8_female$연령)

# 정당별 남성 득표율
symbols(vote_8_male$연령, vote_8_male$더불어민주당,
        circles = radius_male,
        inches  = 0.35,
        bg      = "blue",
        lwd     = 1.5,
        xlim    = xrange_male,
        ylim    = c(10, 90),
        xlab    = "연령대",
        ylab    = "득표율",
        main    = "정당별 남성 득표율",
        sub     = "(원의 크기 = 투표율)")
par(new = TRUE)
symbols(vote_8_male$연령, vote_8_male$국민의힘,
        circles = radius_male,
        inches  = 0.35,
        bg      = "red",
        lwd     = 1.5,
        xlim    = xrange_male,
        ylim    = c(10, 90),
        xlab    = "",
        ylab    = "",
        main    = "",
        axes    = FALSE)
par(new = FALSE)

# 정당별 여성 득표율
symbols(vote_8_female$연령, vote_8_female$더불어민주당,
        circles = radius_female,
        inches  = 0.35,
        bg      = "blue",
        lwd     = 1.5,
        xlim    = xrange_female,
        ylim    = c(10, 90),
        xlab    = "연령대",
        ylab    = "득표율",
        main    = "정당별 여성 득표율",
        sub     = "(원의 크기 = 투표율)")
par(new = TRUE)
symbols(vote_8_female$연령, vote_8_female$국민의힘,
        circles = radius_female,
        inches  = 0.35,
        bg      = "red",
        lwd     = 1.5,
        xlim    = xrange_female,
        ylim    = c(10, 90),
        xlab    = "",
        ylab    = "",
        main    = "",
        axes    = FALSE)
par(new = FALSE)
