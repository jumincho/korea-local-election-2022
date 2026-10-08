# The key statistics quoted in the README, computed from the tidy data.
#
# key_statistics() collects one section per finding, in README order, with
# ids of the form `<section>.<detail>`. scripts/make_figures.R writes the
# result to results/key_statistics.csv; CI and
# tests/testthat/test-key-statistics.R check that the committed file is up to
# date, so a changed number shows up in review.

#' Key statistics as a long table.
#'
#' @param d The list returned by [load_election_data()].
#' @return `statistic` (id), `value` (rounded to three decimals), `unit` and
#'   `detail` (the provinces or groups concerned, or a note; may be empty).
key_statistics <- function(d) {
  dplyr::bind_rows(
    governor_race_statistics(d),
    margin_statistics(d),
    swing_statistics(d),
    correlation_statistics(d),
    exit_poll_statistics(d),
    officials_statistics(d)
  )
}

#' Write the key statistics as CSV: UTF-8, LF line endings.
write_key_statistics <- function(statistics,
                                 path = here::here("results", "key_statistics.csv")) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  readr::write_csv(statistics, path, na = "", eol = "\n")
  invisible(path)
}

# Rows of the key statistics table; every argument may be a vector.
stat_rows <- function(statistic, value, unit, detail = "") {
  dplyr::tibble(statistic = statistic, value = round(value, 3), unit = unit, detail = detail)
}

# Governor races won by each party in the two local elections.
governor_race_statistics <- function(d) {
  winners <- province_winners(d$vote_share)
  wins <- count_winners(winners[winners$election %in% c("local_2018", "local_2022"), ])
  stat_rows(sprintf("governor_races_won.%s.%s", wins$election, wins$winner), wins$races, "races")
}

# Lead of the PPP over the DPK in the 2022 governor races: the closest races
# and the widest leads.
margin_statistics <- function(d) {
  m <- bloc_margin(d$vote_share, d$parties, d$provinces, "local_2022")
  m <- m[order(abs(m$margin_pp)), ]
  label <- function(i) province_labels(m$province_code[i], d$provinces)
  ppp <- which.max(m$margin_pp)
  dpk <- which.min(m$margin_pp)
  dplyr::bind_rows(
    stat_rows("margin_2022.closest", m$margin_pp[1], "pp", label(1)),
    stat_rows("margin_2022.second_closest", m$margin_pp[2], "pp", label(2)),
    stat_rows("margin_2022.races_within_5pp", sum(abs(m$margin_pp) < 5), "races"),
    stat_rows("margin_2022.largest_ppp_lead", m$margin_pp[ppp], "pp", label(ppp)),
    stat_rows("margin_2022.largest_dpk_lead", m$margin_pp[dpk], "pp", label(dpk))
  )
}

# Change in each main bloc's governor share from 2018 to 2022, over the
# provinces where it had a candidate both times.
swing_statistics <- function(d) {
  swing <- bloc_swing(d$vote_share, d$parties, d$provinces, "local_2018", "local_2022")
  dplyr::bind_rows(lapply(MAIN_BLOCS, function(bloc) {
    s <- swing[swing$bloc == bloc & !is.na(swing$change_pp), ]
    id <- sprintf("swing_2018_2022.%s.", bloc)
    label <- function(i) paste(province_labels(s$province_code[i], d$provinces), collapse = ", ")
    up <- s$change_pp > 0
    dplyr::bind_rows(
      stat_rows(paste0(id, "provinces_compared"), nrow(s), "provinces"),
      stat_rows(paste0(id, "provinces_up"), sum(up), "provinces", label(up)),
      stat_rows(paste0(id, "median_change"), stats::median(s$change_pp), "pp"),
      stat_rows(paste0(id, "min_change"), min(s$change_pp), "pp", label(which.min(s$change_pp))),
      stat_rows(paste0(id, "max_change"), max(s$change_pp), "pp", label(which.max(s$change_pp)))
    )
  }))
}

# Correlation of each main bloc's province shares between two elections: the
# 2022 presidential and governor votes, and the 2018 and 2022 governor votes.
correlation_statistics <- function(d) {
  comparisons <- list(
    presidential_vs_local_2022 = c("presidential_2022", "local_2022"),
    local_2018_vs_2022 = c("local_2018", "local_2022")
  )
  results <- dplyr::bind_rows(lapply(names(comparisons), function(name) {
    pair <- comparisons[[name]]
    shares <- paired_shares(d$vote_share, d$parties, d$provinces, pair[1], pair[2])
    dplyr::mutate(bloc_correlations(shares), comparison = name)
  }))
  dplyr::bind_rows(lapply(seq_len(nrow(results)), function(i) {
    row <- results[i, ]
    id <- sprintf("correlation.%s.%s.", row$comparison, row$bloc)
    dplyr::bind_rows(
      stat_rows(paste0(id, "r"), row$r, "r"),
      stat_rows(paste0(id, "conf_low"), row$conf_low, "r"),
      stat_rows(paste0(id, "conf_high"), row$conf_high, "r"),
      stat_rows(paste0(id, "n"), row$n, "provinces"),
      stat_rows(
        paste0(id, "mean_difference"), row$mean_difference_pp, "pp",
        "unweighted mean over provinces of (second election - first)"
      )
    )
  }))
}

# Exit poll: how men and women in their 20s voted, the groups the DPK led,
# and the range of turnout.
exit_poll_statistics <- function(d) {
  e <- d$exit_poll
  share <- function(sex, age, party) {
    e$vote_share_pct[e$sex == sex & e$age_group == age & e$party_id == party]
  }
  gap <- exit_poll_gap(e)
  groups <- function(keep) paste(gap$sex[keep], gap$age_group[keep], collapse = ", ")
  # Difference between men and women in the PPP-minus-DPK gap, by age group.
  men <- gap[gap$sex == "male", ]
  women <- gap[gap$sex == "female", ]
  by_age <- men$gap_pp - women$gap_pp[match(men$age_group, women$age_group)]
  widest <- which.max(abs(by_age))
  dplyr::bind_rows(
    stat_rows("exit_poll.male_20s.ppp", share("male", "20s", "ppp"), "%"),
    stat_rows("exit_poll.male_20s.dpk", share("male", "20s", "dpk"), "%"),
    stat_rows("exit_poll.female_20s.dpk", share("female", "20s", "dpk"), "%"),
    stat_rows("exit_poll.female_20s.ppp", share("female", "20s", "ppp"), "%"),
    stat_rows(
      "exit_poll.widest_sex_difference", by_age[widest], "pp",
      paste("PPP-minus-DPK gap, men minus women, age", men$age_group[widest])
    ),
    stat_rows("exit_poll.groups_led_by_dpk", sum(gap$gap_pp < 0), "groups", groups(gap$gap_pp < 0)),
    stat_rows(
      "exit_poll.turnout_min", min(gap$turnout_pct), "%",
      groups(gap$turnout_pct == min(gap$turnout_pct))
    ),
    stat_rows(
      "exit_poll.turnout_max", max(gap$turnout_pct), "%",
      groups(gap$turnout_pct == max(gap$turnout_pct))
    )
  )
}

# Share of each kind of local office won by each bloc, 2018 and 2022.
officials_statistics <- function(d) {
  o <- officials_by_bloc(d$elected_officials, d$parties)
  stat_rows(sprintf("officials.%s.%s.%s", o$office, o$election, o$bloc), o$share_pct, "%")
}
