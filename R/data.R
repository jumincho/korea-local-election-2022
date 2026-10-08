# Reading and validating the tidy data in data/.
#
# Every reader checks the columns, their types and the values that link the
# tables together (election ids, province codes, party ids) and fails with an
# informative error instead of returning something half-right. The scripts in
# data-raw/ read the lookups with these same readers, so the Korean names they
# match against the original files are checked as well.
#
# Each reader takes the path of its file as its last argument, so that the
# tests can hand it a broken copy.

#' Path to a file under the project's data/ directory.
data_path <- function(...) {
  here::here("data", ...)
}

# Signal an error that names the data file at fault.
stop_data <- function(file, ...) {
  stop(sprintf("data/%s: %s", file, paste0(...)), call. = FALSE)
}

#' Read a CSV from data/ with an exact column specification.
#'
#' @param file File name relative to data/ (used in error messages).
#' @param columns Named character vector: every column in file order, with its
#'   readr type code ("c" character, "d" double, "D" date).
#' @param path Where to read from; defaults to data/<file>.
#' @return A plain tibble, without readr's `spec` and `problems` attributes.
read_data_csv <- function(file, columns, path = data_path(file)) {
  header <- names(readr::read_csv(
    path,
    n_max = 0, col_types = readr::cols(.default = readr::col_character()), progress = FALSE
  ))
  if (!identical(header, names(columns))) {
    stop_data(
      file, "expected columns ", paste(names(columns), collapse = ", "),
      " but found ", paste(header, collapse = ", ")
    )
  }
  # Parsing problems are reported below as an error, so readr's warning is muffled.
  x <- withCallingHandlers(
    readr::read_csv(
      path,
      col_types = do.call(readr::cols, as.list(columns)), na = "",
      locale = readr::locale(encoding = "UTF-8"), progress = FALSE
    ),
    vroom_parse_issue = function(w) invokeRestart("muffleWarning")
  )
  if (nrow(readr::problems(x)) > 0) {
    stop_data(file, "could not parse ", nrow(readr::problems(x)), " value(s)")
  }
  if (anyNA(x)) {
    stop_data(file, "missing values in ", paste(names(x)[colSums(is.na(x)) > 0], collapse = ", "))
  }
  structure(x, spec = NULL, problems = NULL, class = c("tbl_df", "tbl", "data.frame"))
}

# Fail unless the values of `columns` together identify every row.
check_unique <- function(x, columns, file) {
  if (anyDuplicated(x[columns]) > 0) {
    stop_data(file, "duplicate rows for ", paste(columns, collapse = " + "))
  }
  invisible(x)
}

# Fail if `column` holds a value that is not in `allowed`.
check_known <- function(x, column, allowed, file) {
  unknown <- setdiff(unique(x[[column]]), allowed)
  if (length(unknown) > 0) {
    stop_data(file, "unknown ", column, ": ", paste(unknown, collapse = ", "))
  }
  invisible(x)
}

# Fail if `column` holds a value outside 0 to 100.
check_percent <- function(x, column, file) {
  if (any(x[[column]] < 0 | x[[column]] > 100)) {
    stop_data(file, column, " must lie between 0 and 100")
  }
  invisible(x)
}

# ---- lookups ----------------------------------------------------------------
#
# `name_ko` is how the original files in data-raw/ name a province, party or
# office, so it must identify one row as surely as the id does.

#' The 17 metropolitan-level provinces, keyed by their official two-digit code.
read_provinces <- function(path = data_path("provinces.csv")) {
  file <- "provinces.csv"
  x <- read_data_csv(file, c(province_code = "c", name_en = "c", name_ko = "c", label = "c"), path)
  for (column in c("province_code", "name_ko", "label")) check_unique(x, column, file)
  if (nrow(x) != 17) stop_data(file, "expected 17 provinces, found ", nrow(x))
  if (!all(grepl("^[0-9]{2}$", x$province_code))) stop_data(file, "codes must have two digits")
  x
}

#' Parties and independents, with the bloc and display colour used in figures.
#'
#' The figures colour blocs, not parties, so every party of a bloc must have
#' the same colour.
read_parties <- function(path = data_path("parties.csv")) {
  file <- "parties.csv"
  x <- read_data_csv(file, c(
    party_id = "c", name_en = "c", name_ko = "c", label = "c", bloc = "c", colour = "c"
  ), path)
  for (column in c("party_id", "name_ko")) check_unique(x, column, file)
  check_known(x, "bloc", c("democratic", "conservative", "minor", "independent", "other"), file)
  if (!all(grepl("^#[0-9a-f]{6}$", x$colour))) stop_data(file, "colours must look like #rrggbb")
  if (anyDuplicated(unique(x[c("bloc", "colour")])$bloc) > 0) {
    stop_data(file, "every party of a bloc must have the same colour")
  }
  x
}

#' The three elections, in chronological order.
read_elections <- function(path = data_path("elections.csv")) {
  file <- "elections.csv"
  x <- read_data_csv(file, c(
    election = "c", date = "D", name_en = "c", name_ko = "c", race = "c", label = "c"
  ), path)
  check_unique(x, "election", file)
  check_known(x, "race", c("governor", "president"), file)
  x[order(x$date), ]
}

#' The three kinds of office in the elected-officials table.
read_offices <- function(path = data_path("offices.csv")) {
  file <- "offices.csv"
  x <- read_data_csv(file, c(office = "c", name_en = "c", name_ko = "c", label = "c"), path)
  for (column in c("office", "name_ko")) check_unique(x, column, file)
  x
}

#' Short English label of each province code, e.g. "Jeonbuk" for "45".
province_labels <- function(codes, provinces) {
  i <- match(codes, provinces$province_code)
  if (anyNA(i)) {
    stop("Unknown province_code: ", paste(codes[is.na(i)], collapse = ", "), call. = FALSE)
  }
  provinces$label[i]
}

#' Year of each election, e.g. "2022" for "local_2022".
election_year <- function(ids, elections) {
  i <- match(ids, elections$election)
  if (anyNA(i)) {
    stop("Unknown election: ", paste(ids[is.na(i)], collapse = ", "), call. = FALSE)
  }
  format(elections$date[i], "%Y")
}

# ---- results ----------------------------------------------------------------

#' Vote share of every candidate's party, by election and province.
read_vote_share <- function(provinces = read_provinces(), parties = read_parties(),
                            elections = read_elections(),
                            path = data_path("vote_share.csv")) {
  file <- "vote_share.csv"
  x <- read_data_csv(file, c(
    election = "c", province_code = "c", party_id = "c", vote_share_pct = "d"
  ), path)
  check_known(x, "election", elections$election, file)
  check_known(x, "province_code", provinces$province_code, file)
  check_known(x, "party_id", parties$party_id, file)
  check_unique(x, c("election", "province_code", "party_id"), file)
  check_percent(x, "vote_share_pct", file)
  x
}

#' Exit-poll party shares and turnout by sex and age group (2022 local elections).
read_exit_poll <- function(parties = read_parties(), path = data_path("exit_poll_2022.csv")) {
  file <- "exit_poll_2022.csv"
  x <- read_data_csv(file, c(
    sex = "c", age_group = "c", party_id = "c", vote_share_pct = "d", turnout_pct = "d"
  ), path)
  check_known(x, "sex", c("male", "female"), file)
  if (!all(grepl("^[1-9]0s$", x$age_group))) stop_data(file, "age groups must look like 20s")
  check_known(x, "party_id", parties$party_id, file)
  check_unique(x, c("sex", "age_group", "party_id"), file)
  check_percent(x, "vote_share_pct", file)
  check_percent(x, "turnout_pct", file)
  turnouts <- tapply(x$turnout_pct, paste(x$sex, x$age_group), function(v) length(unique(v)))
  if (any(turnouts != 1)) {
    stop_data(file, "turnout must be the same on every row of a sex and age group")
  }
  x
}

#' Party shares of the officials elected to each kind of local office.
read_elected_officials <- function(parties = read_parties(), elections = read_elections(),
                                   offices = read_offices(),
                                   path = data_path("elected_officials_share.csv")) {
  file <- "elected_officials_share.csv"
  x <- read_data_csv(file, c(election = "c", office = "c", party_id = "c", share_pct = "d"), path)
  check_known(x, "election", elections$election, file)
  check_known(x, "office", offices$office, file)
  check_known(x, "party_id", parties$party_id, file)
  check_unique(x, c("election", "office", "party_id"), file)
  check_percent(x, "share_pct", file)
  x
}

#' Simplified province boundaries (WGS 84), one feature per province code, in
#' the order of data/provinces.csv.
read_province_geometry <- function(provinces = read_provinces(),
                                   path = data_path("geo", "provinces.geojson")) {
  file <- file.path("geo", "provinces.geojson")
  geo <- sf::st_read(path, quiet = TRUE, stringsAsFactors = FALSE)
  one_to_one <- setequal(geo$province_code, provinces$province_code) &&
    anyDuplicated(geo$province_code) == 0
  if (!one_to_one) stop_data(file, "features must match data/provinces.csv one to one")
  geo <- geo[match(provinces$province_code, geo$province_code), "province_code"]
  sf::st_cast(geo, "MULTIPOLYGON")
}

#' Load and validate every table.
#'
#' @return A named list: `provinces`, `parties`, `elections`, `offices`,
#'   `vote_share`, `exit_poll`, `elected_officials` and `geometry`. The
#'   figure functions and key_statistics() take it as their argument `d`.
load_election_data <- function() {
  provinces <- read_provinces()
  parties <- read_parties()
  elections <- read_elections()
  offices <- read_offices()
  list(
    provinces = provinces,
    parties = parties,
    elections = elections,
    offices = offices,
    vote_share = read_vote_share(provinces, parties, elections),
    exit_poll = read_exit_poll(parties),
    elected_officials = read_elected_officials(parties, elections, offices),
    geometry = read_province_geometry(provinces)
  )
}
