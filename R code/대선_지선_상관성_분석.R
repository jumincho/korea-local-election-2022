rm(list=ls())

# 경로 설정 필요
setwd("C:/Users/prope/OneDrive/바탕 화면/데이터시각화 프로젝트/datasets (preprocessed)")

vote_7=read.csv("7회_지선_득표율.csv",header=T)
vote_8=read.csv("8회_지선_득표율.csv",header=T)
vote_20=read.csv("20대_대선_득표율.csv",header=T)
minjoo_vote_7=(vote_7[,2])[1:17]
minjoo_vote_8=(vote_8[,2])[1:17]
minjoo_vote_20=(vote_20[,2])[1:17]
ppp_vote_8=(vote_8[,3])[1:17]
ppp_vote_20=(vote_20[,3])[1:17]

# 대선 영향 분석(상관관계)
tbl = data.frame(cbind(minjoo_vote_20,minjoo_vote_8))
tbl; class(tbl) 
plot(minjoo_vote_8~minjoo_vote_20,data=tbl,
     col="blue",pch=16,
     main="더불어민주당",
     xlab="제20대 대통령선거 득표율",
     ylab="제8대 지방선거 득표율")		# 산점도 
res=lm(minjoo_vote_8~minjoo_vote_20,data=tbl) 		# 회귀식 도출
abline(res) 			# 회귀선 그리기
cor(minjoo_vote_20,minjoo_vote_8)			# 상관성 분석 시행
text(60,40,"상관계수 : 0.97")

tbl = data.frame(cbind(minjoo_vote_7,minjoo_vote_8))
tbl; class(tbl) 
plot(minjoo_vote_8~minjoo_vote_7,data=tbl,
     col="blue",pch=16,
     main="더불어민주당",
     xlab="제7대 지방선거 득표율",
     ylab="제8대 지방선거 득표율")		# 산점도 
res=lm(minjoo_vote_8~minjoo_vote_7,data=tbl) 		# 회귀식 도출
abline(res) 			# 회귀선 그리기
cor(minjoo_vote_7,minjoo_vote_8)			# 상관성 분석 시행
text(70,40,"상관계수 : 0.76")

tbl = data.frame(cbind(ppp_vote_20,ppp_vote_8))
tbl; class(tbl) 
plot(ppp_vote_8~ppp_vote_20,data=tbl,
     col="red",pch=16,
     main="국민의힘",
     xlab="제20대 대통령선거 득표율",
     ylab="제8대 지방선거 득표율")		# 산점도 
res=lm(ppp_vote_8~ppp_vote_20,data=tbl) 		# 회귀식 도출
abline(res) 			# 회귀선 그리기
cor(ppp_vote_20,ppp_vote_8)			# 상관성 분석 시행
text(60,40,"상관계수 : 0.98")