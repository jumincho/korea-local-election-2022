rm(list=ls())

library(ggplot2)
library(gridExtra)

cido = c("서울특별시", "부산광역시", "대구광역시", "인천광역시", "광주광역시",
         "대전광역시", "울산광역시", "세종특별자치시", "경기도", "강원도",
         "충청북도", "충청남도", "전라북도", "전라남도", "경상북도",
         "경상남도", "제주특별자치도")

vote_7 = read.csv("data/07_local_vote_share.csv", header=TRUE, fileEncoding="UTF-8")
vote_8 = read.csv("data/08_local_vote_share.csv", header=TRUE, fileEncoding="UTF-8")

# 17개 시·도 데이터만 사용 (각 CSV 1~17행)
vote_7 = vote_7[1:17, ]
vote_8 = vote_8[1:17, ]

# 민주당: 7회·8회 모두 "더불어민주당" 컬럼
minju = rbind(
  data.frame(지역 = vote_7$시도, 투표율 = vote_7$더불어민주당, 선거 = "7회 지선"),
  data.frame(지역 = vote_8$시도, 투표율 = vote_8$더불어민주당, 선거 = "8회 지선")
)

# 보수: 7회 "자유한국당" → 8회 "국민의힘" 으로 정당이 바뀜
kukmin = rbind(
  data.frame(지역 = vote_7$시도, 투표율 = vote_7$자유한국당, 선거 = "7회 지선"),
  data.frame(지역 = vote_8$시도, 투표율 = vote_8$국민의힘,   선거 = "8회 지선")
)

minjuPlot = ggplot(minju, aes(x=지역, y=투표율, fill=선거)) +
  geom_bar(position = position_dodge(0.5), stat = "identity",
           linewidth = .2, width = 0.4) +
  scale_fill_manual(values = c("7회 지선" = "skyblue", "8회 지선" = "blue")) +
  scale_x_discrete(limits = cido) +
  ggtitle("더불어민주당 투표결과(7회지선, 8회지선)")

kukminPlot = ggplot(kukmin, aes(x=지역, y=투표율, fill=선거)) +
  geom_bar(position = position_dodge(0.5), stat = "identity",
           linewidth = .2, width = 0.4) +
  scale_fill_manual(values = c("7회 지선" = "pink", "8회 지선" = "red")) +
  scale_x_discrete(limits = cido) +
  ggtitle("자유한국당 → 국민의힘 투표결과(7회지선, 8회지선)")

grid.arrange(minjuPlot, kukminPlot, nrow = 2)
