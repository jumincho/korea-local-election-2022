write_temp_csv <- function(lines) {
  path <- tempfile(fileext = ".csv")
  writeLines(lines, path)
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
