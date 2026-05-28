# 제 8회 전국동시지방선거 (2022) — 시·도별 단계구분도.

source(here::here("src", "_helpers.R"))
suppressMessages(library(ggplot2))


korea_map <- ggplot2::fortify(load_korea_shapefile())

local8 <- load_vote_csv("08_local_vote_share")[1:17, ]
local8$id <- 0:16
local8$win <- factor(
  ifelse(local8$더불어민주당 - local8$국민의힘 > 0, "민주", "국힘"),
  levels = c("국힘", "민주")
)

merged <- merge(korea_map, local8, by = "id")

p <- ggplot() +
  geom_polygon(
    data = merged,
    aes(x = long, y = lat, group = group, fill = win),
    colour = "black"
  ) +
  scale_fill_manual(
    name   = "최다 득표 당",
    labels = c("국민의힘", "더불어민주당"),
    values = c("국힘" = "red", "민주" = "blue")
  ) +
  ggtitle("제 8회 전국동시지방선거 결과 (2022)") +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5))

print(p)
save_figure("08_local_election_map", p)
