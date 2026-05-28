# 기초자치단체장 / 광역의회의원 / 기초의회의원 당선자의 정당 비율을
# 7회·8회 비교 3D 파이차트로.

source(here::here("src", "_helpers.R"))
suppressMessages(library(plotrix))


vote_7 <- load_vote_csv("07_local_other_vote_share")
vote_8 <- load_vote_csv("08_local_other_vote_share")

# 각 CSV 의 1·2·3행은 차례로 기초자치단체장 / 광역의회의원 / 기초의회의원.
ROW_LABELS <- c("기초자치단체장", "광역의회의원", "기초의회의원")

three_party <- function(vote_df, row_idx) {
  as.numeric(vote_df[row_idx, 2:4])
}

pie3d <- function(slices, parties, title) {
  pct <- round(slices / sum(slices) * 100)
  labels <- paste0(parties, " ", pct, "%")
  pie3D(slices, labels = labels,
        col = c("blue", "red", "gray"),
        main = title, explode = 0.05)
}


PARTIES_7 <- c("더불어민주당", "자유한국당", "기타")
PARTIES_8 <- c("더불어민주당", "국민의힘",   "기타")

for (i in seq_along(ROW_LABELS)) {
  label_7 <- paste("7회", ROW_LABELS[i])
  label_8 <- paste("8회", ROW_LABELS[i])
  save_base_figure(paste0("pie_07_", i),
                   pie3d(three_party(vote_7, i), PARTIES_7, label_7))
  save_base_figure(paste0("pie_08_", i),
                   pie3d(three_party(vote_8, i), PARTIES_8, label_8))
}
