rm(list=ls())

vote_7  = read.csv("data/07_local_vote_share.csv",         header=TRUE, fileEncoding="UTF-8")
vote_8  = read.csv("data/08_local_vote_share.csv",         header=TRUE, fileEncoding="UTF-8")
vote_20 = read.csv("data/20th_presidential_vote_share.csv", header=TRUE, fileEncoding="UTF-8")

minjoo_vote_7   = vote_7[1:17,  "더불어민주당"]
minjoo_vote_8   = vote_8[1:17,  "더불어민주당"]
minjoo_vote_20  = vote_20[1:17, "더불어민주당"]
hanguk_vote_7   = vote_7[1:17,  "자유한국당"]   # 7회 지선의 보수 정당
ppp_vote_8      = vote_8[1:17,  "국민의힘"]
ppp_vote_20     = vote_20[1:17, "국민의힘"]

# 대선(2022.03) → 8회 지선(2022.06): 더불어민주당
plot(minjoo_vote_8 ~ minjoo_vote_20,
     col="blue", pch=16,
     main="더불어민주당",
     xlab="제20대 대통령선거 득표율",
     ylab="제8회 지방선거 득표율")
abline(lm(minjoo_vote_8 ~ minjoo_vote_20))
r_minjoo_20_8 = cor(minjoo_vote_20, minjoo_vote_8)
text(60, 40, sprintf("상관계수 : %.2f", r_minjoo_20_8))

# 7회(2018) → 8회(2022) 지선: 더불어민주당
plot(minjoo_vote_8 ~ minjoo_vote_7,
     col="blue", pch=16,
     main="더불어민주당",
     xlab="제7회 지방선거 득표율",
     ylab="제8회 지방선거 득표율")
abline(lm(minjoo_vote_8 ~ minjoo_vote_7))
r_minjoo_7_8 = cor(minjoo_vote_7, minjoo_vote_8)
text(70, 40, sprintf("상관계수 : %.2f", r_minjoo_7_8))

# 대선 → 8회 지선: 국민의힘
plot(ppp_vote_8 ~ ppp_vote_20,
     col="red", pch=16,
     main="국민의힘",
     xlab="제20대 대통령선거 득표율",
     ylab="제8회 지방선거 득표율")
abline(lm(ppp_vote_8 ~ ppp_vote_20))
r_ppp_20_8 = cor(ppp_vote_20, ppp_vote_8)
text(60, 40, sprintf("상관계수 : %.2f", r_ppp_20_8))

# 7회 자유한국당 → 8회 국민의힘 지선 비교 (정당 승계)
plot(ppp_vote_8 ~ hanguk_vote_7,
     col="red", pch=16,
     main="자유한국당 → 국민의힘",
     xlab="제7회 지방선거 자유한국당 득표율",
     ylab="제8회 지방선거 국민의힘 득표율")
abline(lm(ppp_vote_8 ~ hanguk_vote_7))
r_cons_7_8 = cor(hanguk_vote_7, ppp_vote_8)
text(20, 60, sprintf("상관계수 : %.2f", r_cons_7_8))

cat(sprintf("민주당 (20대 대선 ↔ 8회 지선): %.3f\n", r_minjoo_20_8))
cat(sprintf("민주당 (7회 ↔ 8회 지선)     : %.3f\n", r_minjoo_7_8))
cat(sprintf("국민의힘 (20대 대선 ↔ 8회 지선): %.3f\n", r_ppp_20_8))
cat(sprintf("보수 (7회 자유한국당 ↔ 8회 국민의힘): %.3f\n", r_cons_7_8))
