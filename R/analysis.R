# Analysis helpers. They take the tidy tables from R/data.R and return tidy
# data frames; nothing here reads files or draws.

#' The two blocs whose shares are compared across elections: the Democratic
#' Party of Korea, and the Liberty Korea Party (2018) and its successor the
#' People Power Party (2022). See data/README.md on party lineage.
MAIN_BLOCS <- c("democratic", "conservative")

# Fail if `values` holds anything that is not in `allowed`.
check_values <- function(values, allowed, what) {
  unknown <- setdiff(values, allowed)
  if (length(unknown) > 0) {
    stop("Unknown ", what, ": ", paste(unknown, collapse = ", "), call. = FALSE)
  }
  invisible(values)
}

#' Winner, runner-up and winning margin of every race.
#'
#' @param vote_share Rows of `election`, `province_code`, `party_id`,
#'   `vote_share_pct` (one row per candidate's party).
#' @return One row per election and province with `winner`, `winner_pct`,
#'   `runner_up`, `runner_up_pct` and `margin_pp` (winner minus runner-up, in
#'   percentage points; `NA` for an uncontested race).
province_winners <- function(vote_share) {
  winners <- vote_share |>
    dplyr::arrange(.data$election, .data$province_code, dplyr::desc(.data$vote_share_pct)) |>
    dplyr::summarise(
      winner = .data$party_id[1],
      winner_pct = .data$vote_share_pct[1],
      runner_up = .data$party_id[2],
      runner_up_pct = .data$vote_share_pct[2],
      .by = c("election", "province_code")
    ) |>
    dplyr::mutate(margin_pp = .data$winner_pct - .data$runner_up_pct)
  if (any(winners$margin_pp == 0, na.rm = TRUE)) {
    stop("Tied race: the winner is not determined by vote share", call. = FALSE)
  }
  winners
}

#' Number of races won by each party in each election.
#'
#' @param winners From [province_winners()].
#' @return `election`, `winner` and `races`, the most races first.
count_winners <- function(winners) {
  winners |>
    dplyr::summarise(races = dplyr::n(), .by = c("election", "winner")) |>
    dplyr::arrange(.data$election, dplyr::desc(.data$races), .data$winner)
}

#' Vote share of each bloc (sum over its parties) by election and province.
#'
#' A bloc that fielded no candidate in a race has no row; see [bloc_swing()]
#' for how that is handled.
bloc_shares <- function(vote_share, parties) {
  check_values(vote_share$party_id, parties$party_id, "party_id")
  vote_share |>
    dplyr::inner_join(parties[c("party_id", "bloc")], by = "party_id") |>
    dplyr::summarise(
      share_pct = sum(.data$vote_share_pct),
      .by = c("election", "province_code", "bloc")
    )
}

# Share of `bloc` in `election` for every province, in the order of
# `provinces`; NA where the bloc fielded no candidate.
bloc_share_by_province <- function(shares, provinces, election, bloc) {
  s <- shares[shares$election == election & shares$bloc == bloc, ]
  s$share_pct[match(provinces$province_code, s$province_code)]
}

#' Each bloc's share in two elections side by side.
#'
#' @return One row per bloc and province (blocs in the order given, provinces
#'   in lookup order): `province_code`, `bloc`, `x` (share in `x_election`)
#'   and `y` (share in `y_election`), with `NA` where the bloc fielded no
#'   candidate.
paired_shares <- function(vote_share, parties, provinces, x_election, y_election,
                          blocs = MAIN_BLOCS) {
  check_values(c(x_election, y_election), vote_share$election, "election")
  check_values(blocs, parties$bloc, "bloc")
  shares <- bloc_shares(vote_share, parties)
  dplyr::bind_rows(lapply(blocs, function(bloc) {
    # Computed first: inside tibble(), `bloc` would mean the new column.
    x <- bloc_share_by_province(shares, provinces, x_election, bloc)
    y <- bloc_share_by_province(shares, provinces, y_election, bloc)
    dplyr::tibble(province_code = provinces$province_code, bloc = bloc, x = x, y = y)
  }))
}

#' Change in each bloc's share between two elections, by province.
#'
#' @return One row per bloc and province with `share_from`, `share_to` and
#'   `change_pp` (`share_to - share_from`). The change is `NA` where the bloc
#'   had no candidate in one of the two elections: a missing candidate is not
#'   a swing.
bloc_swing <- function(vote_share, parties, provinces, from, to, blocs = MAIN_BLOCS) {
  p <- paired_shares(vote_share, parties, provinces, from, to, blocs)
  dplyr::tibble(
    province_code = p$province_code, bloc = p$bloc,
    share_from = p$x, share_to = p$y, change_pp = p$y - p$x
  )
}

#' Lead of one bloc over another in each race of an election, by province.
#'
#' @return `province_code` and `margin_pp` = share of `lead` minus share of
#'   `trail`, in percentage points (positive: `lead` ahead).
bloc_margin <- function(vote_share, parties, provinces, election,
                        lead = "conservative", trail = "democratic") {
  check_values(election, vote_share$election, "election")
  check_values(c(lead, trail), parties$bloc, "bloc")
  shares <- bloc_shares(vote_share, parties)
  share <- function(bloc) bloc_share_by_province(shares, provinces, election, bloc)
  dplyr::tibble(province_code = provinces$province_code, margin_pp = share(lead) - share(trail))
}

#' Pearson correlation with a confidence interval, plus the least-squares line.
#'
#' Pairs with a missing value are dropped. With n = 17 provinces the interval
#' is wide; every province counts once, whatever its population.
#'
#' @return One row: `n`, `r`, `conf_low`, `conf_high`, `slope`, `intercept`.
correlation_summary <- function(x, y, conf_level = 0.95) {
  keep <- stats::complete.cases(x, y)
  x <- x[keep]
  y <- y[keep]
  if (length(x) < 4) stop("Need at least four complete pairs", call. = FALSE)
  test <- stats::cor.test(x, y, method = "pearson", conf.level = conf_level)
  fit <- stats::lm(y ~ x)
  dplyr::tibble(
    n = length(x),
    r = unname(test$estimate),
    conf_low = test$conf.int[1],
    conf_high = test$conf.int[2],
    slope = unname(stats::coef(fit)[2]),
    intercept = unname(stats::coef(fit)[1])
  )
}

#' How closely each bloc's province shares in one election follow another.
#'
#' @param pairs From [paired_shares()].
#' @return One row per bloc: `bloc`, the columns of [correlation_summary()]
#'   and `mean_difference_pp`, the unweighted mean over provinces of `y - x`.
bloc_correlations <- function(pairs) {
  dplyr::summarise(
    pairs,
    correlation_summary(.data$x, .data$y),
    mean_difference_pp = mean(.data$y - .data$x, na.rm = TRUE),
    .by = "bloc"
  )
}

#' Lead of one party over another in each exit-poll group, in percentage points.
#'
#' @return One row per sex and age group: `sex`, `age_group`, `turnout_pct`
#'   and `gap_pp` = share of `lead` minus share of `trail`.
exit_poll_gap <- function(exit_poll, lead = "ppp", trail = "dpk") {
  check_values(c(lead, trail), exit_poll$party_id, "party_id")
  groups <- unique(exit_poll[c("sex", "age_group", "turnout_pct")])
  group_key <- paste(groups$sex, groups$age_group)
  share <- function(party) {
    rows <- exit_poll[exit_poll$party_id == party, ]
    rows$vote_share_pct[match(group_key, paste(rows$sex, rows$age_group))]
  }
  dplyr::mutate(groups, gap_pp = share(lead) - share(trail))
}

#' Elected-officials shares summed by bloc.
#'
#' @return One row per election, office and bloc: `share_pct`.
officials_by_bloc <- function(elected_officials, parties) {
  check_values(elected_officials$party_id, parties$party_id, "party_id")
  elected_officials |>
    dplyr::inner_join(parties[c("party_id", "bloc")], by = "party_id") |>
    dplyr::summarise(share_pct = sum(.data$share_pct), .by = c("election", "office", "bloc"))
}
