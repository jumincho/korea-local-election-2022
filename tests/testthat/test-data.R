d <- load_election_data()

race_sums <- function(vote_share) {
  s <- stats::aggregate(vote_share_pct ~ election + province_code, data = vote_share, FUN = sum)
  s$race <- paste(s$election, s$province_code)
  s
}

test_that("every election covers the same 17 provinces", {
  expect_equal(nrow(d$provinces), 17)
  expect_setequal(unique(d$vote_share$election), d$elections$election)
  for (election in d$elections$election) {
    covered <- unique(d$vote_share$province_code[d$vote_share$election == election])
    expect_setequal(covered, d$provinces$province_code)
  }
})

test_that("vote shares are percentages and every race adds up to about 100", {
  expect_true(all(d$vote_share$vote_share_pct >= 0 & d$vote_share$vote_share_pct <= 100))
  sums <- race_sums(d$vote_share)
  local <- sums[sums$election != "presidential_2022", ]
  expect_true(all(local$vote_share_pct >= 99.5 & local$vote_share_pct <= 100.5))
  # Only the three main presidential candidates are recorded.
  presidential <- sums[sums$election == "presidential_2022", ]
  expect_true(all(presidential$vote_share_pct >= 98 & presidential$vote_share_pct <= 100))
})

test_that("the races that do not add up are exactly those documented in data/README.md", {
  sums <- race_sums(d$vote_share)
  local <- sums[sums$election != "presidential_2022", ]
  expect_identical(local$race[local$vote_share_pct > 100.01], "local_2022 44")
  expect_setequal(local$race[local$vote_share_pct < 99.9], c("local_2018 44", "local_2022 11"))
})

test_that("governor races: DPK 14, LKP 2, independent 1 in 2018; PPP 12, DPK 5 in 2022", {
  winners <- province_winners(d$vote_share)
  won <- function(election) {
    n <- count_winners(winners[winners$election == election, ])
    stats::setNames(n$races, n$winner)
  }
  expect_equal(won("local_2018"), c(dpk = 14L, lkp = 2L, independent = 1L))
  expect_equal(won("local_2022"), c(ppp = 12L, dpk = 5L))
  jeju <- d$provinces$province_code[d$provinces$label == "Jeju"]
  expect_identical(
    winners$province_code[winners$election == "local_2018" & winners$winner == "independent"], jeju
  )
})

test_that("the exit poll covers two parties for each sex and age group", {
  e <- d$exit_poll
  expect_equal(nrow(e), 2 * 6 * 2)
  expect_setequal(e$party_id, c("dpk", "ppp"))
  expect_setequal(e$age_group, paste0(seq(20, 70, 10), "s"))
  shares <- stats::aggregate(vote_share_pct ~ sex + age_group, data = e, FUN = sum)
  expect_true(all(shares$vote_share_pct <= 100))
})

test_that("the duplicated 60s/70s turnout in the source is preserved, not smoothed", {
  e <- d$exit_poll
  turnout <- function(sex, age) unique(e$turnout_pct[e$sex == sex & e$age_group == age])
  for (sex in c("male", "female")) expect_identical(turnout(sex, "60s"), turnout(sex, "70s"))
})

test_that("elected-officials shares add up to 100 within rounding", {
  o <- d$elected_officials
  expect_equal(nrow(o), 2 * 3 * 3)
  sums <- stats::aggregate(share_pct ~ election + office, data = o, FUN = sum)
  expect_true(all(abs(sums$share_pct - 100) <= 0.05))
})

test_that("municipal-head shares are whole numbers of the 226 posts", {
  # Evidence that this table holds shares of seats, not of votes.
  o <- d$elected_officials[d$elected_officials$office == "municipal_head", ]
  for (election in unique(o$election)) {
    share <- o$share_pct[o$election == election]
    seats <- round(share / 100 * 226)
    expect_equal(sum(seats), 226)
    expect_equal(round(seats / 226 * 100, 2), share)
  }
})

test_that("every party in the data has a bloc and a colour", {
  used <- unique(c(d$vote_share$party_id, d$exit_poll$party_id, d$elected_officials$party_id))
  expect_true(all(used %in% d$parties$party_id))
  expect_length(bloc_colours(d$parties), length(unique(d$parties$bloc)))
})

test_that("data files are UTF-8 without a byte-order mark and end lines with LF", {
  files <- list.files(
    here::here("data"),
    pattern = "[.](csv|geojson|md)$", recursive = TRUE, full.names = TRUE
  )
  expect_gt(length(files), 5)
  for (file in files) {
    bytes <- readBin(file, "raw", file.size(file))
    expect_false(identical(bytes[1:3], as.raw(c(0xef, 0xbb, 0xbf))), info = file)
    expect_false(any(bytes == as.raw(0x0d)), info = file)
    expect_identical(bytes[length(bytes)], as.raw(0x0a), info = file)
    expect_true(validUTF8(rawToChar(bytes)), info = file)
  }
})
