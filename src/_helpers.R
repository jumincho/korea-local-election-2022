# Shared helpers for the election analysis scripts.
#
# Source from any script: `source(here::here("src", "_helpers.R"))`
#
# Provided:
#   - load_korea_shapefile(crs = "+proj=longlat")
#   - load_vote_csv(name)                 # data/<name>.csv with UTF-8 encoding
#   - save_figure(name, plot, ...)        # ggplot → figures/<name>.png
#   - save_base_figure(name, expr, ...)   # base R draws → figures/<name>.png
#   - KOREA_PROVINCES                     # 17 시·도 표준 순서 (서울 → 제주)
#
# Required packages: here, raster, ggplot2, ggmap (loaded lazily by callers).

suppressMessages(library(here))


load_korea_shapefile <- function(crs = "+proj=longlat") {
  suppressMessages(library(raster))
  # rgeos / maptools 는 CRAN retired — raster::shapefile() 로 대체.
  korea <- shapefile(here("data", "shapefiles", "ctp_rvn.shp"))
  spTransform(korea, CRS(crs))
}


load_vote_csv <- function(name) {
  path <- here("data", paste0(name, ".csv"))
  read.csv(path, header = TRUE, fileEncoding = "UTF-8")
}


ensure_figures_dir <- function() {
  d <- here("figures")
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
  d
}


save_figure <- function(name, plot = ggplot2::last_plot(),
                        width = 8, height = 6, dpi = 150) {
  ensure_figures_dir()
  out <- here("figures", paste0(name, ".png"))
  ggplot2::ggsave(out, plot = plot, width = width, height = height, dpi = dpi)
  message("wrote ", out)
  invisible(out)
}


save_base_figure <- function(name, expr,
                             width = 1000, height = 750, res = 120) {
  ensure_figures_dir()
  out <- here("figures", paste0(name, ".png"))
  grDevices::png(out, width = width, height = height, res = res)
  on.exit(grDevices::dev.off())
  force(expr)
  message("wrote ", out)
  invisible(out)
}


KOREA_PROVINCES <- c(
  "서울특별시", "부산광역시", "대구광역시", "인천광역시", "광주광역시",
  "대전광역시", "울산광역시", "세종특별자치시", "경기도", "강원도",
  "충청북도", "충청남도", "전라북도", "전라남도", "경상북도",
  "경상남도", "제주특별자치도"
)
