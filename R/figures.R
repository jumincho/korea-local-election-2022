# The figures in figures/, one function each. A figure function takes the
# list returned by load_election_data(), runs the analysis the figure needs
# and returns the finished plot, titles and captions included; numbers quoted
# in a caption are computed from the data, never typed in. figure_index()
# lists the figures with their file names and sizes, and write_figures() saves
# them all (scripts/make_figures.R calls it).

SOURCE_NEC <- "Source: National Election Commission (info.nec.go.kr), as compiled in data/."

#' Every figure, in README order: file name (without ".png"), the function
#' that builds it, and its width and height in inches.
figure_index <- function() {
  figure <- function(build, height, width = 10) list(build = build, width = width, height = height)
  list(
    "01_winner_maps" = figure(figure_winner_maps, height = 6.4),
    "02_margin_2022" = figure(figure_margin_2022, height = 6.4),
    "03_swing_2018_2022" = figure(figure_swing_2018_2022, height = 6.4),
    "04_presidential_vs_local_2022" = figure(figure_presidential_vs_local, height = 6.2),
    "05_local_2018_vs_2022" = figure(figure_local_2018_vs_2022, height = 6.2),
    "06_exit_poll_2022" = figure(figure_exit_poll_2022, height = 7),
    "07_elected_officials" = figure(figure_elected_officials, height = 5.6)
  )
}

#' Build every figure in [figure_index()] and save it as <dir>/<name>.png.
#'
#' @param d The list returned by [load_election_data()].
#' @return The paths written, named by figure, invisibly.
write_figures <- function(d, dir = here::here("figures"), dpi = 200) {
  index <- figure_index()
  paths <- vapply(names(index), function(name) {
    f <- index[[name]]
    save_figure(f$build(d), name, width = f$width, height = f$height, dpi = dpi, dir = dir)
  }, character(1))
  invisible(paths)
}

#' Figure 1: the party that won each governor race, 2018 and 2022.
figure_winner_maps <- function(d) {
  plot_winner_maps(
    d$geometry, province_winners(d$vote_share), d$parties, d$elections,
    races = c("local_2018", "local_2022"),
    title = "Winning party in each metropolitan mayor and governor race",
    subtitle = "7th (2018) and 8th (2022) local elections; counts are races won",
    caption = SOURCE_NEC
  )
}

#' Figure 2: the PPP's lead over the DPK in each 2022 governor race.
figure_margin_2022 <- function(d) {
  plot_margin(
    d$geometry, bloc_margin(d$vote_share, d$parties, d$provinces, "local_2022"),
    d$provinces, d$parties,
    title = sprintf(
      "How far ahead the PPP was in each governor race, %s",
      election_year("local_2022", d$elections)
    ),
    subtitle = "Share of the PPP candidate minus share of the DPK candidate",
    caption = SOURCE_NEC
  )
}

#' Figure 3: each main bloc's governor share by province, 2018 and 2022.
figure_swing_2018_2022 <- function(d) {
  years <- election_year(c("local_2018", "local_2022"), d$elections)
  plot_swing(
    bloc_swing(d$vote_share, d$parties, d$provinces, "local_2018", "local_2022"),
    d$provinces, d$parties, years,
    title = sprintf("Governor vote share by province, %s and %s", years[1], years[2]),
    subtitle = paste(
      "Labels give the change in percentage points;",
      "provinces are sorted by the change in DPK share"
    ),
    caption = paste(conservative_2018_note(d), SOURCE_NEC, sep = "\n")
  )
}

#' Figure 4: presidential against governor vote shares by province, 2022.
figure_presidential_vs_local <- function(d) {
  share_scatter(
    d, "presidential_2022", "local_2022",
    panels = c(democratic = "Democratic Party (DPK)", conservative = "People Power Party (PPP)"),
    x_title = "Presidential election, March 2022", y_title = "Governor races, June 2022",
    title = "Presidential and governor vote shares by province, 2022",
    caption = paste(
      "Presidential shares are recorded to one decimal place.",
      sprintf("Pearson's r over %d provinces, each weighted equally.", nrow(d$provinces)),
      SOURCE_NEC,
      sep = "\n"
    )
  )
}

#' Figure 5: 2018 against 2022 governor vote shares by province.
figure_local_2018_vs_2022 <- function(d) {
  share_scatter(
    d, "local_2018", "local_2022",
    panels = bloc_labels(d$parties)[MAIN_BLOCS],
    x_title = "Governor races, 2018", y_title = "Governor races, 2022",
    title = "Governor vote shares by province, 2018 and 2022",
    caption = paste(conservative_2018_note(d), SOURCE_NEC, sep = "\n")
  )
}

#' Figure 6: exit-poll vote share and turnout by sex and age group, 2022.
figure_exit_poll_2022 <- function(d) {
  plot_exit_poll(
    d$exit_poll, d$parties,
    title = "2022 local elections exit poll: party vote share by sex and age group",
    subtitle = "Vote share of the two main parties (top) and turnout (bottom) in each group",
    caption = paste(
      "Source: joint exit poll of the three terrestrial broadcasters, as compiled in",
      "data/exit_poll_2022.csv (not re-verified).\nOpen circle: the source repeats the",
      "turnout of the previous age group, probably a single figure for ages 60 and over."
    )
  )
}

#' Figure 7: share of each kind of local office won by each bloc, 2018 and 2022.
figure_elected_officials <- function(d) {
  plot_elected_officials(
    officials_by_bloc(d$elected_officials, d$parties), d$offices, d$elections, d$parties,
    title = "Share of local offices won, 2018 and 2022",
    subtitle = "Percentage of the officials elected to each kind of office, by party",
    caption = paste(
      "'Other' combines minor parties and independents, as in the source.",
      "Shares of seats won, not of votes.", SOURCE_NEC,
      sep = "\n"
    )
  )
}

# Scatter plots of each main bloc's province shares in two elections (figures
# 4 and 5), with the correlations computed from the same pairs.
share_scatter <- function(d, x_election, y_election, panels, x_title, y_title, title, caption) {
  pairs <- paired_shares(
    d$vote_share, d$parties, d$provinces, x_election, y_election, names(panels)
  )
  plot_share_scatter(
    pairs, bloc_correlations(pairs), d$provinces, d$parties, panels, x_title, y_title,
    title = title,
    subtitle = "Each point is a province; line of best fit in colour, y = x in grey",
    caption = caption
  )
}

#' Caption note on why the conservative bloc's 2018 shares are uneven: the
#' provinces where the LKP had no candidate, and the races an independent won.
conservative_2018_note <- function(d) {
  swing <- bloc_swing(d$vote_share, d$parties, d$provinces, "local_2018", "local_2022")
  absent <- swing$province_code[swing$bloc == "conservative" & is.na(swing$share_from)]
  winners <- province_winners(d$vote_share)
  won <- winners[winners$election == "local_2018" & winners$winner == "independent", ]
  lkp <- d$vote_share[d$vote_share$election == "local_2018" & d$vote_share$party_id == "lkp", ]
  notes <- c(
    if (length(absent) > 0) {
      sprintf(
        "No LKP candidate stood in %s in 2018.",
        paste(province_labels(absent, d$provinces), collapse = " or ")
      )
    },
    sprintf(
      "%s's 2018 race was won by an independent (%.2f%%); the LKP took %.2f%%.",
      province_labels(won$province_code, d$provinces), won$winner_pct,
      lkp$vote_share_pct[match(won$province_code, lkp$province_code)]
    )
  )
  paste(notes, collapse = " ")
}
