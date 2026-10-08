# The figures: the figure functions and index in R/figures.R, the chart
# builders in R/plots.R and the PNG writer in R/theme.R.

d <- load_election_data()

png_size <- function(path) {
  header <- readBin(path, "raw", 24)
  stopifnot(identical(header[2:4], charToRaw("PNG")))
  c(
    width = readBin(header[17:20], "integer", endian = "big"),
    height = readBin(header[21:24], "integer", endian = "big")
  )
}

test_that("save_figure writes a PNG of the requested size", {
  path <- save_figure(
    ggplot2::ggplot() + theme_election(), "blank",
    width = 2, height = 1, dpi = 100, dir = tempfile("figures-")
  )
  expect_equal(png_size(path), c(width = 200L, height = 100L))
})

test_that("write_figures renders every figure in the index at its size", {
  dpi <- 20
  paths <- write_figures(d, dir = tempfile("figures-"), dpi = dpi)
  index <- figure_index()
  expect_identical(names(paths), names(index))
  for (name in names(index)) {
    size <- c(width = index[[name]]$width, height = index[[name]]$height) * dpi
    expect_equal(png_size(paths[[name]]), round(size), info = name)
  }
})

test_that("figures/ holds exactly the indexed figures, and the README shows each", {
  names <- names(figure_index())
  expect_setequal(list.files(here::here("figures")), paste0(names, ".png"))
  readme <- readLines(here::here("README.md"), encoding = "UTF-8")
  for (name in names) {
    expect_true(any(grepl(sprintf("(figures/%s.png)", name), readme, fixed = TRUE)), info = name)
  }
})

test_that("the caption note on the 2018 conservative shares comes from the data", {
  expect_identical(
    conservative_2018_note(d),
    paste(
      "No LKP candidate stood in Gwangju or Jeonnam in 2018.",
      "Jeju's 2018 race was won by an independent (51.72%); the LKP took 3.26%."
    )
  )
})

test_that("plot_margin refuses a margin its colour scale cannot show", {
  margins <- dplyr::tibble(province_code = d$provinces$province_code, margin_pp = 75)
  expect_error(plot_margin(d$geometry, margins, d$provinces, d$parties), "limit of 70")
})
