# 제8회 지선 출구조사 — 성별·연령대별 정당 득표율을 버블 차트로.
# 원의 크기 = 해당 연령대 투표율, 색 = 정당, 패널 = 성별.

source(here::here("src", "_helpers.R"))
suppressMessages(library(ggplot2))


male   <- load_vote_csv("08_local_male_age_vote_share")
female <- load_vote_csv("08_local_female_age_vote_share")

male$성별   <- "남성"
female$성별 <- "여성"


# wide → long: 정당 두 개를 한 컴럼으로 펴서 ggplot 에 넘김.
to_long <- function(df) {
  rbind(
    data.frame(성별 = df$성별, 연령 = df$연령, 정당 = "더불어민주당",
               득표율 = df$더불어민주당, 투표율 = df$투표율),
    data.frame(성별 = df$성별, 연령 = df$연령, 정당 = "국민의힘",
               득표율 = df$국민의힘,     투표율 = df$투표율)
  )
}

combined <- rbind(to_long(male), to_long(female))


p <- ggplot(combined, aes(x = 연령, y = 득표율, size = 투표율, fill = 정당)) +
  geom_point(shape = 21, colour = "black", alpha = 0.85) +
  scale_size_area(max_size = 18, name = "투표율") +
  scale_fill_manual(values = c("더불어민주당" = "blue", "국민의힘" = "red")) +
  facet_wrap(~ 성별, ncol = 2) +
  ylim(10, 90) +
  ggtitle("제 8회 지방선거 — 성별·연령대별 정당 득표율",
          subtitle = "(원의 크기 = 연령대 투표율)") +
  theme_minimal()

print(p)
save_figure("vote_share_by_gender_age", p, width = 12, height = 5)
