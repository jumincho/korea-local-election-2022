# 시·도별 양당 득표율 변화 — 제7회 (2018) vs 제8회 (2022) 지선.
# 17개 시·도를 가로축으로, 더불어민주당과 (자유한국당 → 국민의힘) 흐름을
# 막대그래프로 비교.

source(here::here("src", "_helpers.R"))
suppressMessages({
  library(ggplot2)
  library(gridExtra)
})


vote_7 <- load_vote_csv("07_local_vote_share")[1:17, ]
vote_8 <- load_vote_csv("08_local_vote_share")[1:17, ]

minju <- rbind(
  data.frame(지역 = vote_7$시도, 투표율 = vote_7$더불어민주당, 선거 = "7회 지선"),
  data.frame(지역 = vote_8$시도, 투표율 = vote_8$더불어민주당, 선거 = "8회 지선")
)

# 보수: 7회 자유한국당 → 8회 국민의힘으로 정당이 바뀌었음.
kukmin <- rbind(
  data.frame(지역 = vote_7$시도, 투표율 = vote_7$자유한국당, 선거 = "7회 지선"),
  data.frame(지역 = vote_8$시도, 투표율 = vote_8$국민의힘,   선거 = "8회 지선")
)


bars <- function(df, palette, title) {
  ggplot(df, aes(x = 지역, y = 투표율, fill = 선거)) +
    geom_bar(
      position = position_dodge(0.5),
      stat = "identity",
      linewidth = 0.2,
      width = 0.4
    ) +
    scale_fill_manual(values = palette) +
    scale_x_discrete(limits = KOREA_PROVINCES) +
    ggtitle(title) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}


minju_plot <- bars(
  minju,
  palette = c("7회 지선" = "skyblue", "8회 지선" = "blue"),
  title = "더불어민주당 — 7회 vs 8회 지선"
)

kukmin_plot <- bars(
  kukmin,
  palette = c("7회 지선" = "pink", "8회 지선" = "red"),
  title = "자유한국당 → 국민의힘 — 7회 vs 8회 지선"
)


print(gridExtra::grid.arrange(minju_plot, kukmin_plot, nrow = 2))
save_figure("regional_party_support_trend",
            gridExtra::arrangeGrob(minju_plot, kukmin_plot, nrow = 2),
            width = 12, height = 8)
