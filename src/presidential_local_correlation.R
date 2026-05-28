# 대선(2022.03)과 지선(2022.06), 그리고 7회·8회 지선 사이의 시·도별
# 정당 득표율 상관성. 산점도 + 회귀선 + Pearson r.

source(here::here("src", "_helpers.R"))


vote_7  <- load_vote_csv("07_local_vote_share")
vote_8  <- load_vote_csv("08_local_vote_share")
vote_20 <- load_vote_csv("20th_presidential_vote_share")

minjoo_7  <- vote_7[1:17,  "더불어민주당"]
minjoo_8  <- vote_8[1:17,  "더불어민주당"]
minjoo_20 <- vote_20[1:17, "더불어민주당"]
hanguk_7  <- vote_7[1:17,  "자유한국당"]   # 7회 보수 정당
ppp_8     <- vote_8[1:17,  "국민의힘"]
ppp_20    <- vote_20[1:17, "국민의힘"]


plot_pair <- function(x, y, name, title, xlab, ylab, colour,
                      label_x, label_y) {
  r <- cor(x, y)
  save_base_figure(name, {
    plot(y ~ x, col = colour, pch = 16, main = title, xlab = xlab, ylab = ylab)
    abline(lm(y ~ x))
    text(label_x, label_y, sprintf("상관계수: %.2f", r))
  })
  r
}


r_minjoo_20_8 <- plot_pair(
  minjoo_20, minjoo_8,
  name = "corr_minjoo_pres20_local8",
  title = "더불어민주당 — 20대 대선 vs 8회 지선",
  xlab = "제20대 대통령선거 득표율",
  ylab = "제8회 지방선거 득표율",
  colour = "blue", label_x = 60, label_y = 40
)

r_minjoo_7_8 <- plot_pair(
  minjoo_7, minjoo_8,
  name = "corr_minjoo_local7_local8",
  title = "더불어민주당 — 7회 vs 8회 지선",
  xlab = "제7회 지방선거 득표율",
  ylab = "제8회 지방선거 득표율",
  colour = "blue", label_x = 70, label_y = 40
)

r_ppp_20_8 <- plot_pair(
  ppp_20, ppp_8,
  name = "corr_ppp_pres20_local8",
  title = "국민의힘 — 20대 대선 vs 8회 지선",
  xlab = "제20대 대통령선거 득표율",
  ylab = "제8회 지방선거 득표율",
  colour = "red", label_x = 60, label_y = 40
)

r_cons_7_8 <- plot_pair(
  hanguk_7, ppp_8,
  name = "corr_conservative_local7_local8",
  title = "보수 — 7회 자유한국당 vs 8회 국민의힘",
  xlab = "제7회 지방선거 자유한국당 득표율",
  ylab = "제8회 지방선거 국민의힘 득표율",
  colour = "red", label_x = 20, label_y = 60
)


cat(sprintf("민주당 (20대 대선 ↔ 8회 지선)     : %.3f\n", r_minjoo_20_8))
cat(sprintf("민주당 (7회 ↔ 8회 지선)           : %.3f\n", r_minjoo_7_8))
cat(sprintf("국민의힘 (20대 대선 ↔ 8회 지선)   : %.3f\n", r_ppp_20_8))
cat(sprintf("보수 (7회 자유한국당 ↔ 8회 국힘) : %.3f\n", r_cons_7_8))
