d <- load_election_data()

png_size <- function(path) {
  header <- readBin(path, "raw", 24)
  stopifnot(identical(header[2:4], charToRaw("PNG")))
  c(
    width = readBin(header[17:20], "integer", endian = "big"),
    height = readBin(header[21:24], "integer", endian = "big")
  )
}

test_that("results/key_statistics.csv matches what the code computes from data/", {
  committed <- readr::read_csv(
    here::here("results", "key_statistics.csv"),
    col_types = "cdcc", na = character(), progress = FALSE
  )
  current <- key_statistics(d)
  expect_identical(names(committed), names(current))
  expect_identical(committed$statistic, current$statistic)
  expect_equal(committed$value, current$value)
  expect_identical(committed$detail, current$detail)
})

test_that("save_figure writes a PNG of the requested size", {
  path <- save_figure(
    ggplot2::ggplot() + theme_election(), "blank",
    width = 2, height = 1, dpi = 100, dir = tempfile("figures-")
  )
  expect_equal(png_size(path), c(width = 200L, height = 100L))
})

test_that("every figure builder renders", {
  winners <- province_winners(d$vote_share)
  margins <- bloc_margin(d$vote_share, d$parties, d$provinces, "local_2022")
  swing <- bloc_swing(d$vote_share, d$parties, d$provinces, "local_2018", "local_2022")
  pairs <- paired_shares(
    d$vote_share, d$parties, d$provinces, "local_2018", "local_2022", "democratic"
  )
  stats <- dplyr::mutate(correlation_summary(pairs$x, pairs$y), bloc = "democratic")
  plots <- list(
    winners = plot_winner_maps(d$geometry, winners, d$parties, d$elections),
    margin = plot_margin(d$geometry, margins, d$provinces, d$parties, title = "t"),
    swing = plot_swing(swing, d$provinces, d$parties, years = c("2018", "2022")),
    scatter = plot_share_scatter(
      pairs, stats, d$provinces, d$parties, c(democratic = "DPK"), "x", "y", "t"
    ),
    exit_poll = plot_exit_poll(d$exit_poll, d$parties),
    officials = plot_elected_officials(d$elected_officials, d$offices, d$elections, d$parties)
  )
  dir <- tempfile("figures-")
  for (name in names(plots)) {
    path <- save_figure(plots[[name]], name, width = 6, height = 4, dpi = 40, dir = dir)
    expect_equal(png_size(path), c(width = 240L, height = 160L), info = name)
  }
})
