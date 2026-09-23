# The key statistics quoted in the README, computed from the tidy data.
# scripts/make_figures.R prints them and writes results/key_statistics.csv;
# tests/testthat/test-results.R checks that the committed file is up to date.

#' Key statistics as a long table: `statistic` (id), `value`, `unit`, `detail`.
key_statistics <- function(data) {
  d <- data
  label <- function(codes) province_labels(codes, d$provinces)
  row <- function(statistic, value, unit, detail = "") {
    dplyr::tibble(statistic = statistic, value = round(value, 3), unit = unit, detail = detail)
  }
  local <- c("local_2018", "local_2022")

  winners <- province_winners(d$vote_share)
  wins <- count_winners(winners[winners$election %in% local, ])
  won <- row(sprintf("governor_races_won.%s.%s", wins$election, wins$winner), wins$races, "races")

  m <- bloc_margin(d$vote_share, d$parties, d$provinces, "local_2022")
  m <- m[order(abs(m$margin_pp)), ]
  ppp <- which.max(m$margin_pp)
  dpk <- which.min(m$margin_pp)
  margins <- dplyr::bind_rows(
    row("margin_2022.closest", m$margin_pp[1], "pp", label(m$province_code[1])),
    row("margin_2022.second_closest", m$margin_pp[2], "pp", label(m$province_code[2])),
    row("margin_2022.races_within_5pp", sum(abs(m$margin_pp) < 5), "races"),
    row("margin_2022.largest_ppp_lead", m$margin_pp[ppp], "pp", label(m$province_code[ppp])),
    row("margin_2022.largest_dpk_lead", m$margin_pp[dpk], "pp", label(m$province_code[dpk]))
  )

  swing <- bloc_swing(d$vote_share, d$parties, d$provinces, "local_2018", "local_2022")
  swings <- dplyr::bind_rows(lapply(c("democratic", "conservative"), function(b) {
    s <- swing[swing$bloc == b & !is.na(swing$change_pp), ]
    dplyr::bind_rows(
      row(sprintf("swing_2018_2022.%s.provinces_compared", b), nrow(s), "provinces"),
      row(sprintf("swing_2018_2022.%s.provinces_up", b), sum(s$change_pp > 0), "provinces",
          paste(label(s$province_code[s$change_pp > 0]), collapse = ", ")),
      row(sprintf("swing_2018_2022.%s.median_change", b), stats::median(s$change_pp), "pp"),
      row(sprintf("swing_2018_2022.%s.min_change", b), min(s$change_pp), "pp",
          label(s$province_code[which.min(s$change_pp)])),
      row(sprintf("swing_2018_2022.%s.max_change", b), max(s$change_pp), "pp",
          label(s$province_code[which.max(s$change_pp)]))
    )
  }))

  pairs <- list(
    presidential_vs_local_2022.democratic = c("presidential_2022", "local_2022", "democratic"),
    presidential_vs_local_2022.conservative = c("presidential_2022", "local_2022", "conservative"),
    local_2018_vs_2022.democratic = c("local_2018", "local_2022", "democratic"),
    local_2018_vs_2022.conservative = c("local_2018", "local_2022", "conservative")
  )
  correlations <- dplyr::bind_rows(lapply(names(pairs), function(id) {
    p <- pairs[[id]]
    s <- paired_shares(d$vote_share, d$parties, d$provinces, p[1], p[2], p[3])
    cs <- correlation_summary(s$x, s$y)
    dplyr::bind_rows(
      row(paste0("correlation.", id, ".r"), cs$r, "r"),
      row(paste0("correlation.", id, ".conf_low"), cs$conf_low, "r"),
      row(paste0("correlation.", id, ".conf_high"), cs$conf_high, "r"),
      row(paste0("correlation.", id, ".n"), cs$n, "provinces"),
      row(paste0("correlation.", id, ".mean_difference"), mean(s$y - s$x, na.rm = TRUE), "pp",
          "unweighted mean over provinces of (second election - first)")
    )
  }))

  e <- d$exit_poll
  gap <- exit_poll_gap(e)
  share <- function(sex, age, party) {
    e$vote_share_pct[e$sex == sex & e$age_group == age & e$party_id == party]
  }
  # Difference between men and women in the PPP-minus-DPK gap, by age group.
  men <- gap[gap$sex == "male", ]
  women <- gap[gap$sex == "female", ]
  by_age <- men$gap_pp - women$gap_pp[match(men$age_group, women$age_group)]
  widest <- which.max(abs(by_age))
  groups_where <- function(keep) paste(gap$sex[keep], gap$age_group[keep], collapse = ", ")
  exit_poll <- dplyr::bind_rows(
    row("exit_poll.male_20s.ppp", share("male", "20s", "ppp"), "%"),
    row("exit_poll.male_20s.dpk", share("male", "20s", "dpk"), "%"),
    row("exit_poll.female_20s.dpk", share("female", "20s", "dpk"), "%"),
    row("exit_poll.female_20s.ppp", share("female", "20s", "ppp"), "%"),
    row("exit_poll.widest_sex_difference", by_age[widest], "pp",
        paste("PPP-minus-DPK gap, men minus women, age", men$age_group[widest])),
    row("exit_poll.groups_led_by_dpk", sum(gap$gap_pp < 0), "groups",
        groups_where(gap$gap_pp < 0)),
    row("exit_poll.turnout_min", min(gap$turnout_pct), "%",
        groups_where(gap$turnout_pct == min(gap$turnout_pct))),
    row("exit_poll.turnout_max", max(gap$turnout_pct), "%",
        groups_where(gap$turnout_pct == max(gap$turnout_pct)))
  )

  o <- officials_by_bloc(d$elected_officials, d$parties)
  officials <- row(sprintf("officials.%s.%s.%s", o$office, o$election, o$bloc), o$share_pct, "%")

  dplyr::bind_rows(won, margins, swings, correlations, exit_poll, officials)
}
