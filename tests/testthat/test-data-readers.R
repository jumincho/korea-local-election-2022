# The readers in R/data.R: the generic CSV reader and checks, and the rules
# each table must follow, tried on broken copies of the real files.

write_temp_csv <- function(lines) {
  path <- tempfile(fileext = ".csv")
  writeLines(lines, path)
  path
}

# A copy of data/<file> with `edit` applied to its rows (all read as text).
broken_copy <- function(file, edit) {
  x <- readr::read_csv(
    data_path(file),
    col_types = readr::cols(.default = readr::col_character()), progress = FALSE
  )
  path <- tempfile(fileext = ".csv")
  readr::write_csv(edit(x), path, na = "")
  path
}

test_that("read_data_csv returns plain tibbles with the declared types", {
  path <- write_temp_csv(c("a,b", "x,1.5"))
  x <- read_data_csv("t.csv", c(a = "c", b = "d"), path = path)
  expect_s3_class(x, "tbl_df")
  expect_null(attr(x, "spec"))
  expect_type(x$b, "double")
})

test_that("read_data_csv rejects wrong columns, unparsable values and gaps", {
  expect_error(
    read_data_csv("t.csv", c(a = "c", c = "d"), path = write_temp_csv(c("a,b", "x,1"))),
    "expected columns a, c but found a, b"
  )
  expect_error(
    read_data_csv("t.csv", c(a = "c", b = "d"), path = write_temp_csv(c("a,b", "x,one"))),
    "could not parse"
  )
  expect_error(
    read_data_csv("t.csv", c(a = "c", b = "d"), path = write_temp_csv(c("a,b", "x,"))),
    "missing values in b"
  )
})

test_that("the checks catch duplicates, unknown ids and impossible percentages", {
  x <- data.frame(id = c("a", "a"), pct = c(10, 120))
  expect_error(check_unique(x, "id", "t.csv"), "data/t.csv: duplicate rows for id")
  expect_error(check_known(x, "id", "b", "t.csv"), "unknown id: a")
  expect_error(check_percent(x, "pct", "t.csv"), "between 0 and 100")
  expect_silent(check_known(x, "id", c("a", "b"), "t.csv"))
})

test_that("the lookups reject a Korean name that would match two rows", {
  same_name <- function(x) {
    x$name_ko[2] <- x$name_ko[1]
    x
  }
  expect_error(read_provinces(broken_copy("provinces.csv", same_name)), "rows for name_ko")
  expect_error(read_parties(broken_copy("parties.csv", same_name)), "rows for name_ko")
  expect_error(read_offices(broken_copy("offices.csv", same_name)), "rows for name_ko")
})

test_that("read_provinces wants 17 provinces with two-digit codes", {
  expect_error(read_provinces(broken_copy("provinces.csv", function(x) x[-1, ])), "found 16")
  one_digit <- function(x) {
    x$province_code[1] <- "1"
    x
  }
  expect_error(read_provinces(broken_copy("provinces.csv", one_digit)), "two digits")
})

test_that("read_parties wants one known bloc and one colour per bloc", {
  unknown_bloc <- function(x) {
    x$bloc[1] <- "liberal"
    x
  }
  expect_error(read_parties(broken_copy("parties.csv", unknown_bloc)), "unknown bloc: liberal")
  second_colour <- function(x) {
    x$colour[x$party_id == "ppp"] <- "#000000"
    x
  }
  expect_error(read_parties(broken_copy("parties.csv", second_colour)), "same colour")
})

test_that("read_exit_poll wants decade age groups and one turnout per group", {
  bad_age <- function(x) {
    x$age_group[1:2] <- "18-29"
    x
  }
  expect_error(read_exit_poll(path = broken_copy("exit_poll_2022.csv", bad_age)), "like 20s")
  two_turnouts <- function(x) {
    x$turnout_pct[1] <- "30"
    x
  }
  expect_error(
    read_exit_poll(path = broken_copy("exit_poll_2022.csv", two_turnouts)),
    "turnout must be the same"
  )
})

test_that("the results tables reject ids that are not in the lookups", {
  unknown_party <- function(x) {
    x$party_id[1] <- "zz"
    x
  }
  expect_error(
    read_vote_share(path = broken_copy("vote_share.csv", unknown_party)), "unknown party_id: zz"
  )
  expect_error(
    read_elected_officials(path = broken_copy("elected_officials_share.csv", unknown_party)),
    "unknown party_id: zz"
  )
})

test_that("the readers validate the real data without complaint", {
  expect_silent(d <- load_election_data())
  expect_named(
    d,
    c(
      "provinces", "parties", "elections", "offices", "vote_share",
      "exit_poll", "elected_officials", "geometry"
    )
  )
  expect_identical(d$elections$election, c("local_2018", "presidential_2022", "local_2022"))
})
