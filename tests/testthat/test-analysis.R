# Analysis helpers on small made-up inputs whose answers are known.

toy_parties <- dplyr::tibble(
  party_id = c("a", "b", "c", "d"),
  bloc = c("democratic", "conservative", "conservative", "minor")
)
toy_provinces <- dplyr::tibble(province_code = c("01", "02"), label = c("One", "Two"))
toy_votes <- dplyr::tibble(
  election = c("e1", "e1", "e1", "e1", "e2", "e2", "e2"),
  province_code = c("01", "01", "01", "02", "01", "02", "02"),
  party_id = c("a", "b", "d", "a", "a", "a", "b"),
  vote_share_pct = c(50, 40, 10, 100, 45, 30, 70)
)

test_that("province_winners reports winner, runner-up and margin", {
  w <- province_winners(toy_votes)
  expect_equal(nrow(w), 4)
  race <- w[w$election == "e1" & w$province_code == "01", ]
  expect_identical(c(race$winner, race$runner_up), c("a", "b"))
  expect_equal(race$margin_pp, 10)
  uncontested <- w[w$election == "e1" & w$province_code == "02", ]
  expect_true(is.na(uncontested$runner_up) && is.na(uncontested$margin_pp))
})

test_that("province_winners refuses to break a tie", {
  tie <- dplyr::tibble(
    election = "e", province_code = "01", party_id = c("a", "b"), vote_share_pct = c(50, 50)
  )
  expect_error(province_winners(tie), "Tied race")
})

test_that("count_winners counts races per election and party", {
  n <- count_winners(province_winners(toy_votes))
  expect_equal(n$races[n$election == "e1" & n$winner == "a"], 2)
  expect_equal(n$races[n$election == "e2" & n$winner == "b"], 1)
})

test_that("bloc_shares adds up the parties of a bloc", {
  votes <- dplyr::tibble(
    election = "e", province_code = "01", party_id = c("a", "b", "c"),
    vote_share_pct = c(40, 30, 20)
  )
  s <- bloc_shares(votes, toy_parties)
  expect_equal(s$share_pct[s$bloc == "conservative"], 50)
  expect_equal(s$share_pct[s$bloc == "democratic"], 40)
  votes$party_id[1] <- "zz"
  expect_error(bloc_shares(votes, toy_parties), "Unknown party_id: zz")
})

test_that("paired_shares lines up two elections by province, NA where a bloc was absent", {
  p <- paired_shares(toy_votes, toy_parties, toy_provinces, "e1", "e2", "conservative")
  expect_identical(p$province_code, c("01", "02"))
  expect_equal(p$x, c(40, NA))
  expect_equal(p$y, c(NA, 70))
  both <- paired_shares(toy_votes, toy_parties, toy_provinces, "e1", "e2")
  expect_identical(both$bloc, rep(MAIN_BLOCS, each = 2))
  expect_equal(both$x[both$bloc == "democratic"], c(50, 100))
})

test_that("unknown elections and blocs are errors, not columns of NA", {
  expect_error(
    paired_shares(toy_votes, toy_parties, toy_provinces, "e1", "e3"), "Unknown election: e3"
  )
  expect_error(
    bloc_margin(toy_votes, toy_parties, toy_provinces, "e2", lead = "liberal"),
    "Unknown bloc: liberal"
  )
})

test_that("bloc_swing is the change in share and NA, not a swing, without a candidate", {
  s <- bloc_swing(toy_votes, toy_parties, toy_provinces, "e1", "e2")
  expect_equal(s$change_pp[s$bloc == "democratic"], c(-5, -70))
  expect_true(all(is.na(s$change_pp[s$bloc == "conservative"])))
})

test_that("bloc_margin is the lead of one bloc over another", {
  m <- bloc_margin(toy_votes, toy_parties, toy_provinces, "e2")
  expect_equal(m$margin_pp, c(NA, 40))
  flipped <- bloc_margin(toy_votes, toy_parties, toy_provinces, "e2", "democratic", "conservative")
  expect_equal(flipped$margin_pp, c(NA, -40))
})

test_that("correlation_summary agrees with cor.test() and lm(), dropping incomplete pairs", {
  x <- c(1, 2, 3, 4, 5, NA)
  y <- c(2, 4, 5, 4, 5, 1)
  s <- correlation_summary(x, y)
  expect_equal(s$n, 5)
  expect_equal(s$r, stats::cor(x[1:5], y[1:5]))
  expect_equal(s$slope, unname(stats::coef(stats::lm(y[1:5] ~ x[1:5]))[2]))
  expect_true(s$conf_low < s$r && s$r < s$conf_high)
  line <- correlation_summary(1:10, 3 + 2 * (1:10))
  expect_equal(c(line$r, line$slope, line$intercept), c(1, 2, 3))
  expect_error(correlation_summary(1:3, 1:3), "at least four")
})

test_that("bloc_correlations summarises each bloc's pairs separately", {
  pairs <- dplyr::tibble(
    province_code = rep(c("01", "02", "03", "04", "05"), 2),
    bloc = rep(c("democratic", "conservative"), each = 5),
    x = c(1, 2, 3, 4, 5, 10, 20, 30, 40, NA),
    y = c(2, 4, 6, 8, 10, 40, 30, 20, 10, 0)
  )
  s <- bloc_correlations(pairs)
  expect_identical(s$bloc, c("democratic", "conservative"))
  expect_equal(s$r, c(1, -1))
  expect_equal(s$n, c(5L, 4L))
  expect_equal(s$mean_difference_pp, c(3, 0))
})

test_that("exit_poll_gap is one party's lead in each sex and age group", {
  poll <- dplyr::tibble(
    sex = c("male", "male", "female", "female"),
    age_group = "20s",
    party_id = c("dpk", "ppp", "dpk", "ppp"),
    vote_share_pct = c(30, 60, 55, 40),
    turnout_pct = c(30, 30, 35, 35)
  )
  gap <- exit_poll_gap(poll)
  expect_equal(gap$gap_pp, c(30, -15))
  expect_equal(gap$turnout_pct, c(30, 35))
})

test_that("officials_by_bloc sums party shares within each bloc", {
  officials <- dplyr::tibble(
    election = "e", office = "x", party_id = c("a", "b", "c", "d"), share_pct = c(40, 30, 20, 10)
  )
  o <- officials_by_bloc(officials, toy_parties)
  expect_equal(o$share_pct[o$bloc == "conservative"], 50)
  expect_equal(sum(o$share_pct), 100)
})
