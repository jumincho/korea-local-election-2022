#!/usr/bin/env Rscript
# Derive the tidy election tables in data/ from the original wide CSV files.
#
# The originals, in data-raw/original/, were compiled in 2022: wide format,
# Korean headers, stray trailing commas and spaces. They are kept byte for
# byte (see data-raw/README.md), so every tidy value can be traced back to a
# cell in one of them.
#
# Usage, from the repository root:
#   Rscript data-raw/tidy_election_data.R
#
# Besides the originals it reads the hand-written lookups in the data folder
# (provinces.csv, parties.csv and offices.csv map Korean names to ids) and
# writes vote_share.csv, exit_poll_2022.csv and elected_officials_share.csv
# next to them.

RAW_DIR <- file.path("data-raw", "original")

RAW_FILES <- list(
  vote_share = c(
    local_2018 = "07_local_vote_share.csv",
    presidential_2022 = "20th_presidential_vote_share.csv",
    local_2022 = "08_local_vote_share.csv"
  ),
  exit_poll = c(
    male = "08_local_male_age_vote_share.csv",
    female = "08_local_female_age_vote_share.csv"
  ),
  elected_officials = c(
    local_2018 = "07_local_other_vote_share.csv",
    local_2022 = "08_local_other_vote_share.csv"
  )
)

# R stores \u escapes as UTF-8 bytes but leaves them unmarked in C/POSIX
# locales; mark them so comparisons with the UTF-8 file contents always work.
utf8 <- function(x) {
  Encoding(x)[validUTF8(x)] <- "UTF-8"
  x
}

# Korean header labels of the originals, written as escapes so that the
# script itself stays ASCII.
HEADER_PROVINCE <- utf8("시도") # "sido": province
HEADER_AGE <- utf8("연령") # "yeollyeong": age group
HEADER_TURNOUT <- utf8("투표율") # "tupyoyul": turnout
HEADER_OFFICE <- utf8("선출대상") # "seonchul daesang": office

# Read an original wide file and return one row per non-empty cell: the row
# key (first column), the column header and the numeric value. The header row
# is read as data, so Korean labels never become column names (which fails
# with warnings in non-UTF-8 locales). Blank columns and rows are dropped.
read_cells <- function(file, key_header) {
  raw <- readr::read_csv(
    here::here(RAW_DIR, file),
    col_names = FALSE, col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "UTF-8"),
    na = "", trim_ws = TRUE, progress = FALSE
  )
  header <- unname(unlist(raw[1, ]))
  header[is.na(header)] <- ""
  if (!identical(header[1], key_header)) {
    stop("Unexpected first column in ", file, ": ", header[1], call. = FALSE)
  }
  body <- raw[-1, , drop = FALSE]
  body <- body[rowSums(!is.na(body)) > 0, , drop = FALSE]
  if (any(!is.na(as.matrix(body[header == ""])))) {
    stop("Values under a blank header in ", file, call. = FALSE)
  }
  key <- body[[1]]
  if (anyNA(key) || anyDuplicated(key) > 0) {
    stop("Row keys must be present and unique in ", file, call. = FALSE)
  }
  cells <- dplyr::bind_rows(lapply(which(header != "")[-1], function(j) {
    filled <- !is.na(body[[j]])
    dplyr::tibble(key = key[filled], column = header[j], text = body[[j]][filled])
  }))
  cells$value <- suppressWarnings(as.numeric(cells$text))
  if (anyNA(cells$value)) {
    stop("Non-numeric cells in ", file, call. = FALSE)
  }
  cells[c("key", "column", "value")]
}

# Map `x` from one lookup column to another, failing on anything unmatched.
recode_strict <- function(x, from, to, what) {
  i <- match(x, from)
  if (anyNA(i)) {
    stop("Unknown ", what, ": ", paste(unique(x[is.na(i)]), collapse = ", "), call. = FALSE)
  }
  to[i]
}

read_lookup <- function(file) {
  readr::read_csv(
    here::here("data", file),
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "UTF-8"), progress = FALSE
  )
}

party_ids <- function(names_ko, lookups) {
  recode_strict(names_ko, lookups$parties$name_ko, lookups$parties$party_id, "party")
}

tidy_vote_share <- function(files, lookups) {
  tables <- lapply(names(files), function(election) {
    cells <- read_cells(files[[election]], HEADER_PROVINCE)
    dplyr::tibble(
      election = election,
      province_code = recode_strict(
        cells$key, lookups$provinces$name_ko, lookups$provinces$province_code, "province"
      ),
      party_id = party_ids(cells$column, lookups),
      vote_share_pct = cells$value
    )
  })
  out <- dplyr::bind_rows(tables)
  per_election <- tapply(out$province_code, out$election, function(x) length(unique(x)))
  if (any(per_election != nrow(lookups$provinces))) {
    stop("Every election must cover all provinces", call. = FALSE)
  }
  dplyr::arrange(
    out,
    match(.data$election, lookups$elections$election),
    match(.data$province_code, lookups$provinces$province_code),
    match(.data$party_id, lookups$parties$party_id)
  )
}

tidy_exit_poll <- function(files, lookups) {
  tables <- lapply(names(files), function(sex) {
    cells <- read_cells(files[[sex]], HEADER_AGE)
    if (!all(grepl("^[1-9]0$", cells$key))) {
      stop("Age groups must be written as decades (20, 30, ...)", call. = FALSE)
    }
    turnout <- cells[cells$column == HEADER_TURNOUT, ]
    votes <- cells[cells$column != HEADER_TURNOUT, ]
    dplyr::tibble(
      sex = sex,
      age_group = paste0(votes$key, "s"),
      party_id = party_ids(votes$column, lookups),
      vote_share_pct = votes$value,
      turnout_pct = turnout$value[match(votes$key, turnout$key)]
    )
  })
  out <- dplyr::bind_rows(tables)
  if (anyNA(out$turnout_pct)) stop("Missing turnout values", call. = FALSE)
  dplyr::arrange(
    out,
    match(.data$sex, names(files)), .data$age_group,
    match(.data$party_id, lookups$parties$party_id)
  )
}

tidy_elected_officials <- function(files, lookups) {
  tables <- lapply(names(files), function(election) {
    cells <- read_cells(files[[election]], HEADER_OFFICE)
    dplyr::tibble(
      election = election,
      office = recode_strict(
        cells$key, lookups$offices$name_ko, lookups$offices$office, "office"
      ),
      party_id = party_ids(cells$column, lookups),
      share_pct = cells$value
    )
  })
  dplyr::arrange(
    dplyr::bind_rows(tables),
    match(.data$election, lookups$elections$election),
    match(.data$office, lookups$offices$office),
    match(.data$party_id, lookups$parties$party_id)
  )
}

write_tidy <- function(x, file) {
  path <- here::here("data", file)
  readr::write_csv(x, path, na = "", eol = "\n")
  message(sprintf("wrote data/%s (%d rows)", file, nrow(x)))
}

main <- function() {
  lookups <- lapply(
    c(
      provinces = "provinces.csv", parties = "parties.csv",
      offices = "offices.csv", elections = "elections.csv"
    ),
    read_lookup
  )
  write_tidy(tidy_vote_share(RAW_FILES$vote_share, lookups), "vote_share.csv")
  write_tidy(tidy_exit_poll(RAW_FILES$exit_poll, lookups), "exit_poll_2022.csv")
  write_tidy(
    tidy_elected_officials(RAW_FILES$elected_officials, lookups),
    "elected_officials_share.csv"
  )
}

if (sys.nframe() == 0L) main()
