# 제 7회 전국동시지방선거 (2018) — 시·도별 단계구분도.
# 시·도별 1위 정당을 색으로 칠한 한 장의 지도.

source(here::here("src", "_helpers.R"))
suppressMessages(library(ggplot2))


korea_map <- ggplot2::fortify(load_korea_shapefile())

local7 <- load_vote_csv("07_local_vote_share")[1:17, ]
local7$id <- as.character(0:16)  # fortify polygon id(문자형) 와 매칭 (서울 → 제주 순서)

# 1위 정당 결정.
local7$win <- ifelse(
  local7$더불어민주당 - local7$자유한국당 > 0, "민주", "한국"
)
# 제주: 원희룡(무소속) 재선.
local7$win[local7$시도 == "제주특별자치도"] <- "무소속"
local7$win <- factor(local7$win, levels = c("한국", "무소속", "민주"))

merged <- merge(korea_map, local7, by = "id")

p <- ggplot() +
  geom_polygon(
    data = merged,
    aes(x = long, y = lat, group = group, fill = win),
    colour = "black"
  ) +
  scale_fill_manual(
    name   = "최다 득표 당",
    labels = c("자유한국당", "무소속", "더불어민주당"),
    values = c("한국" = "red", "무소속" = "gray", "민주" = "blue")
  ) +
  ggtitle("제 7회 전국동시지방선거 결과 (2018)") +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5))

print(p)
save_figure("07_local_election_map", p)
