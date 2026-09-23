# The raw inputs in data-raw/ must be exactly as recorded, and the tidy tables
# must hold exactly their values. The original CSVs are parsed here with base
# R, independently of the readr code that produced the tidy tables: every
# non-empty cell must match one tidy row, and vice versa.

raw_file <- function(...) here::here("data-raw", ...)

# Non-empty cells of an original file: row key, column header, value.
raw_cells <- function(file) {
  lines <- readLines(raw_file("original", file), encoding = "UTF-8", warn = FALSE)
  fields <- lapply(strsplit(lines, ",", fixed = TRUE), trimws)
  header <- fields[[1]]
  cells <- lapply(fields[-1], function(row) {
    filled <- which(nzchar(row) & seq_along(row) > 1)
    data.frame(key = rep(row[1], length(filled)), column = header[filled], text = row[filled])
  })
  cells <- do.call(rbind, cells)
  cells$value <- as.numeric(cells$text)
  cells
}

d <- load_election_data()
lookup <- function(x, table, from, to) table[[to]][match(x, table[[from]])]

test_that("the raw inputs are byte for byte those recorded in data-raw/MD5SUMS", {
  manifest <- utils::read.table(
    raw_file("MD5SUMS"),
    col.names = c("md5", "path"), colClasses = "character"
  )
  paths <- here::here(manifest$path)
  expect_true(all(file.exists(paths)))
  expect_identical(unname(tools::md5sum(paths)), manifest$md5)
  present <- list.files(raw_file(c("original", "shapefile")), full.names = TRUE)
  expect_setequal(normalizePath(present), normalizePath(paths))
})

test_that("vote_share.csv holds exactly the values of the original files", {
  files <- c(
    local_2018 = "07_local_vote_share.csv",
    presidential_2022 = "20th_presidential_vote_share.csv",
    local_2022 = "08_local_vote_share.csv"
  )
  for (election in names(files)) {
    raw <- raw_cells(files[[election]])
    tidy <- d$vote_share[d$vote_share$election == election, ]
    expect_equal(nrow(tidy), nrow(raw), info = election)
    province <- lookup(raw$key, d$provinces, "name_ko", "province_code")
    party <- lookup(raw$column, d$parties, "name_ko", "party_id")
    expect_false(anyNA(province) || anyNA(party), info = election)
    i <- match(paste(province, party), paste(tidy$province_code, tidy$party_id))
    expect_false(anyNA(i), info = election)
    expect_identical(tidy$vote_share_pct[i], raw$value, info = election)
  }
})

test_that("exit_poll_2022.csv holds exactly the values of the original files", {
  files <- c(
    male = "08_local_male_age_vote_share.csv",
    female = "08_local_female_age_vote_share.csv"
  )
  for (sex in names(files)) {
    raw <- raw_cells(files[[sex]])
    tidy <- d$exit_poll[d$exit_poll$sex == sex, ]
    party <- lookup(raw$column, d$parties, "name_ko", "party_id")
    votes <- raw[!is.na(party), ]
    turnout <- raw[is.na(party), ]
    expect_length(unique(turnout$column), 1)
    expect_equal(nrow(tidy), nrow(votes), info = sex)
    i <- match(paste0(votes$key, "s", party[!is.na(party)]), paste0(tidy$age_group, tidy$party_id))
    expect_false(anyNA(i), info = sex)
    expect_identical(tidy$vote_share_pct[i], votes$value, info = sex)
    j <- match(paste0(turnout$key, "s"), tidy$age_group)
    expect_identical(tidy$turnout_pct[j], turnout$value, info = sex)
  }
})

test_that("elected_officials_share.csv holds exactly the values of the original files", {
  files <- c(
    local_2018 = "07_local_other_vote_share.csv",
    local_2022 = "08_local_other_vote_share.csv"
  )
  for (election in names(files)) {
    raw <- raw_cells(files[[election]])
    tidy <- d$elected_officials[d$elected_officials$election == election, ]
    expect_equal(nrow(tidy), nrow(raw), info = election)
    office <- lookup(raw$key, d$offices, "name_ko", "office")
    party <- lookup(raw$column, d$parties, "name_ko", "party_id")
    i <- match(paste(office, party), paste(tidy$office, tidy$party_id))
    expect_false(anyNA(i), info = election)
    expect_identical(tidy$share_pct[i], raw$value, info = election)
  }
})
