rm(list=ls())
library(plotrix)

# 경로 설정 필요
setwd("C:/Users/prope/OneDrive/바탕 화면/데이터시각화 프로젝트/datasets (preprocessed)")

vote_7_etc=read.csv("7회_지선_기타_득표율.csv",header=T)
기초자치단체장_7=as.numeric(vote_7_etc[1,c(2:4)])
광역의회의원_7=as.numeric(vote_7_etc[2,c(2:4)])
기초의회의원_7=as.numeric(vote_7_etc[3,c(2:4)])
vote_8_etc=read.csv("8회_지선_기타_득표율.csv",header=T)
기초자치단체장_8=as.numeric(vote_8_etc[1,c(2:4)])
광역의회의원_8=as.numeric(vote_8_etc[2,c(2:4)])
기초의회의원_8=as.numeric(vote_8_etc[3,c(2:4)])

# 7회 기초자치단체장
slices=기초자치단체장_7
lbls=c("더불어민주당","자유한국당","기타")
pct=round(slices/sum(slices)*100)
lbls=paste(lbls,pct)
lbls=paste(lbls,"%",sep="")
pie3D(slices,labels=lbls,col=c("blue","red","gray"),
      main="7회 기초자치단체장",explode = 0.05)

# 8회 기초자치단체장
slices=기초자치단체장_8
lbls=c("더불어민주당","국민의힘","기타")
pct=round(slices/sum(slices)*100)
lbls=paste(lbls,pct)
lbls=paste(lbls,"%",sep="")
pie3D(slices,labels=lbls,col=c("blue","red","gray"),
      main="8회 기초자치단체장",explode = 0.05)

# 7회 광역의회의원
slices=광역의회의원_7
lbls=c("더불어민주당","자유한국당","기타")
pct=round(slices/sum(slices)*100)
lbls=paste(lbls,pct)
lbls=paste(lbls,"%",sep="")
pie3D(slices,labels=lbls,col=c("blue","red","gray"),
      main="7회 광역의회의원",explode = 0.05)

# 8회 광역의회의원
slices=광역의회의원_8
lbls=c("더불어민주당","국민의힘","기타")
pct=round(slices/sum(slices)*100)
lbls=paste(lbls,pct)
lbls=paste(lbls,"%",sep="")
pie3D(slices,labels=lbls,col=c("blue","red","gray"),
      main="8회 광역의회의원",explode = 0.05)

# 7회 기초의회의원
slices=기초의회의원_7
lbls=c("더불어민주당","자유한국당","기타")
pct=round(slices/sum(slices)*100)
lbls=paste(lbls,pct)
lbls=paste(lbls,"%",sep="")
pie3D(slices,labels=lbls,col=c("blue","red","gray"),
      main="7회 기초의회의원",explode = 0.05)

# 8회 기초의회의원
slices=기초의회의원_8
lbls=c("더불어민주당","국민의힘","기타")
pct=round(slices/sum(slices)*100)
lbls=paste(lbls,pct)
lbls=paste(lbls,"%",sep="")
pie3D(slices,labels=lbls,col=c("blue","red","gray"),
      main="8회 기초의회의원",explode = 0.05)