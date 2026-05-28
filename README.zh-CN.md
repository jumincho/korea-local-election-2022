<div align="center">

# korea-local-election-2022

**第 8 届韩国全国同时地方选举的 R 可视化与分析**

![Language](https://img.shields.io/badge/language-R-276DC3?logo=r&logoColor=white)
![Domain](https://img.shields.io/badge/domain-election%20analysis-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Year](https://img.shields.io/badge/year-2022-blue)

[한국어](./README.md) · [English](./README.md#english) · **中文**

</div>

---

## 概览

> 用 R 对 2022 年 6 月 1 日举行的第 8 届韩国全国同时地方选举结果进行可视化与分析的项目

将各市道(省级)政党得票率叠加到韩国行政区划 shapefile 上,绘制分级统计图
(choropleth map),并与上一届第 7 届地方选举 (2018) 以及第 20 届总统选举 (2022.03)
对比,观察民意走向与相关性。

<img width="80%" src="https://user-images.githubusercontent.com/77545063/200377493-37fb592b-9b97-45d5-aebe-8c1c6c5861a1.png"/>

## 主要分析

| 脚本 | 产出 |
|---|---|
| [`src/07_local_election_map.R`](src/07_local_election_map.R) | 第 7 届地方选举分级统计图 |
| [`src/08_local_election_map.R`](src/08_local_election_map.R) | 第 8 届地方选举分级统计图 |
| [`src/presidential_local_correlation.R`](src/presidential_local_correlation.R) | 第 20 届大选 ↔ 第 8 届地选 / 第 7 届 ↔ 第 8 届的市道级 Pearson r + 回归线 |
| [`src/regional_party_support_trend.R`](src/regional_party_support_trend.R) | 17 个市道两党 第 7 → 第 8 届得票率变化柱状图 |
| [`src/vote_share_by_gender_age.R`](src/vote_share_by_gender_age.R) | 第 8 届出口民调 性别·年龄段政党得票率气泡图 (圆圈大小 = 投票率) |
| [`src/other_elected_officials_ratio.R`](src/other_elected_officials_ratio.R) | 基层行政首长 · 道议会议员 · 基层议会议员 当选者政党比例 第 7 vs 第 8 届 3D 饼图 |

所有图表在运行时会被保存为 `figures/` 下的 PNG。

## 技术栈

- **语言**: R
- **可视化**: `ggplot2`、`gridExtra`、`plotrix` (3D 饼图)、基础图形 (`symbols`、`plot`、`abline`)
- **空间数据**: 基于 `sp` 的 `raster`、`ggmap` —— 加载 `data/shapefiles/ctp_rvn.shp` 并投影到 `+proj=longlat`
- **统计**: 基础 `lm` / `cor`
- **工具**: `here` (基于仓库根目录的相对路径)

## 数据来源

- 中央选举管理委员会选举统计系统 ([info.nec.go.kr](http://info.nec.go.kr)) —— 第 7 / 8 届地方选举与第 20 届总统选举的市道级得票率 (`data/*.csv`)。
- 国家空间信息门户 —— 市道行政边界 shapefile (`data/shapefiles/ctp_rvn.*`)。

## 项目结构

```
.
├── src/
│   ├── _helpers.R                         # 公共加载/保存工具 + 17 市道常量
│   ├── 07_local_election_map.R            # 第 7 届分级统计图
│   ├── 08_local_election_map.R            # 第 8 届分级统计图
│   ├── presidential_local_correlation.R   # 大选 - 地选相关性
│   ├── regional_party_support_trend.R     # 市道两党得票率变化
│   ├── vote_share_by_gender_age.R         # 性别 × 年龄段气泡图
│   ├── other_elected_officials_ratio.R    # 基层首长 / 议员 3D 饼图
│   └── run_all.R                          # 按顺序运行全部脚本
├── data/                                  # 预处理 CSV + 市道 shapefile
├── figures/                               # 运行时生成 (gitignored)
└── docs/presentation.pptx                 # 演讲幻灯片
```

## 运行方式

```bash
# 1) 安装所需包 (仅首次)
Rscript -e 'install.packages(c("here", "ggplot2", "ggmap", "raster", "plotrix", "gridExtra"))'

# 2) 运行所有分析 —— 在 figures/ 下生成 PNG
Rscript src/run_all.R

# 或在 RStudio 中单独运行某个脚本:
#   setwd("/path/to/korea-local-election-2022")
#   source("src/08_local_election_map.R")
```

本项目仅使用 `raster::shapefile()`,因此不依赖 CRAN 已 retired 的
`rgeos` / `maptools`。长期来看推荐迁移至基于 `sf` 的实现。

## 演讲资料

- 演讲幻灯片: [`docs/presentation.pptx`](docs/presentation.pptx)

## 许可证

[MIT License](./LICENSE)
