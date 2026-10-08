# The key statistics behind the README's numbers (R/key_statistics.R).

d <- load_election_data()
statistics <- key_statistics(d)

test_that("results/key_statistics.csv matches what the code computes from data/", {
  committed <- readr::read_csv(
    here::here("results", "key_statistics.csv"),
    col_types = "cdcc", na = character(), progress = FALSE
  )
  expect_identical(names(committed), names(statistics))
  expect_identical(committed$statistic, statistics$statistic)
  expect_equal(committed$value, statistics$value)
  expect_identical(committed$unit, statistics$unit)
  expect_identical(committed$detail, statistics$detail)
})

test_that("every statistic has a unique id, a value and a known unit", {
  expect_identical(anyDuplicated(statistics$statistic), 0L)
  expect_true(all(grepl("^[a-z0-9_]+([.][a-z0-9_]+)+$", statistics$statistic)))
  expect_false(anyNA(statistics$value))
  expect_true(all(statistics$unit %in% c("races", "pp", "provinces", "r", "%", "groups")))
})

test_that("the sections come in README order", {
  sections <- unique(sub("[.].*$", "", statistics$statistic))
  expect_identical(sections, c(
    "governor_races_won", "margin_2022", "swing_2018_2022", "correlation", "exit_poll",
    "officials"
  ))
})

test_that("the swing statistics only count provinces with a candidate both times", {
  s <- swing_statistics(d)
  value <- function(id) s$value[s$statistic == id]
  expect_equal(value("swing_2018_2022.democratic.provinces_compared"), 17)
  # No LKP candidate in Gwangju or Jeonnam in 2018.
  expect_equal(value("swing_2018_2022.conservative.provinces_compared"), 15)
  expect_equal(value("swing_2018_2022.conservative.provinces_up"), 15)
})

test_that("the correlations agree with cor.test() on the same provinces", {
  s <- correlation_statistics(d)
  pairs <- paired_shares(d$vote_share, d$parties, d$provinces, "local_2018", "local_2022")
  conservative <- pairs[pairs$bloc == "conservative", ]
  expect_equal(
    s$value[s$statistic == "correlation.local_2018_vs_2022.conservative.r"],
    round(stats::cor(conservative$x, conservative$y, use = "complete.obs"), 3)
  )
})

test_that("write_key_statistics writes UTF-8 CSV with LF line endings", {
  path <- write_key_statistics(statistics, tempfile(fileext = ".csv"))
  bytes <- readBin(path, "raw", file.size(path))
  expect_false(any(bytes == as.raw(0x0d)))
  expect_identical(readLines(path, n = 1), "statistic,value,unit,detail")
})
