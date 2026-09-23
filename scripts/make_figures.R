#!/usr/bin/env Rscript
# Regenerate every figure in figures/ and the key statistics quoted in the
# README (results/key_statistics.csv), then print those statistics.
#
# Usage, from anywhere inside the repository:
#   Rscript scripts/make_figures.R        # or: make figures

root <- here::here()
for (file in sort(list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE))) {
  source(file)
}

d <- load_election_data()
provinces <- d$provinces
parties <- d$parties
elections <- d$elections
year <- function(id) format(elections$date[elections$election == id], "%Y")
nec <- "Source: National Election Commission (info.nec.go.kr), as compiled in data/."

winners <- province_winners(d$vote_share)
margins <- bloc_margin(d$vote_share, parties, provinces, "local_2022")
swing <- bloc_swing(d$vote_share, parties, provinces, "local_2018", "local_2022")

# Numbers quoted in captions come from the data, not from memory.
share_of <- function(election, province, party) {
  v <- d$vote_share
  v$vote_share_pct[v$election == election & v$province_code == province & v$party_id == party]
}
jeju <- provinces$province_code[provinces$label == "Jeju"]
no_lkp <- swing$province_code[swing$bloc == "conservative" & is.na(swing$share_from)]
lkp_note <- sprintf(
  paste(
    "No LKP candidate stood in %s in 2018.",
    "Jeju's 2018 race was won by an independent (%.2f%%); the LKP took %.2f%%."
  ),
  paste(province_labels(no_lkp, provinces), collapse = " or "),
  share_of("local_2018", jeju, "independent"), share_of("local_2018", jeju, "lkp")
)

scatter <- function(x_election, y_election, panels, x_title, y_title, title, caption) {
  blocs <- names(panels)
  pairs <- dplyr::bind_rows(lapply(blocs, function(b) {
    paired_shares(d$vote_share, parties, provinces, x_election, y_election, b)
  }))
  stats <- dplyr::bind_rows(lapply(blocs, function(b) {
    p <- pairs[pairs$bloc == b, ]
    dplyr::mutate(correlation_summary(p$x, p$y), bloc = b)
  }))
  plot_share_scatter(pairs, stats, provinces, parties, panels, x_title, y_title, title,
    subtitle = "Each point is a province; line of best fit in colour, y = x in grey",
    caption = caption
  )
}

figures <- list(
  "01_winner_maps" = list(
    plot = plot_winner_maps(d$geometry, winners, parties, elections, caption = nec),
    width = 10, height = 6.4
  ),
  "02_margin_2022" = list(
    plot = plot_margin(d$geometry, margins, provinces, parties,
      title = sprintf("How far ahead the PPP was in each governor race, %s", year("local_2022")),
      caption = nec
    ),
    width = 10, height = 6.4
  ),
  "03_swing_2018_2022" = list(
    plot = plot_swing(swing, provinces, parties,
      years = c(year("local_2018"), year("local_2022")),
      caption = paste(lkp_note, nec, sep = "\n")
    ),
    width = 10, height = 6.4
  ),
  "04_presidential_vs_local_2022" = list(
    plot = scatter(
      "presidential_2022", "local_2022",
      panels = c(democratic = "Democratic Party (DPK)", conservative = "People Power Party (PPP)"),
      x_title = "Presidential election, March 2022", y_title = "Governor races, June 2022",
      title = "Presidential and governor vote shares by province, 2022",
      caption = paste(
        "Presidential shares are recorded to one decimal place.",
        sprintf("Pearson's r over %d provinces, each weighted equally.", nrow(provinces)), nec,
        sep = "\n"
      )
    ),
    width = 10, height = 6.2
  ),
  "05_local_2018_vs_2022" = list(
    plot = scatter(
      "local_2018", "local_2022",
      panels = c(
        democratic = "Democratic Party (DPK)",
        conservative = "LKP (2018) / PPP (2022)"
      ),
      x_title = "Governor races, 2018", y_title = "Governor races, 2022",
      title = "Governor vote shares by province, 2018 and 2022",
      caption = paste(lkp_note, nec, sep = "\n")
    ),
    width = 10, height = 6.2
  ),
  "06_exit_poll_2022" = list(
    plot = plot_exit_poll(d$exit_poll, parties,
      caption = paste(
        "Source: joint exit poll of the three terrestrial broadcasters, as compiled in",
        "data/exit_poll_2022.csv (not re-verified).\nOpen circle: the source repeats the",
        "turnout of the previous age group, probably a single figure for ages 60 and over."
      )
    ),
    width = 10, height = 7
  ),
  "07_elected_officials" = list(
    plot = plot_elected_officials(d$elected_officials, d$offices, elections, parties,
      caption = paste(
        "'Other' combines minor parties and independents, as in the source.",
        "Shares of seats won, not of votes.", nec,
        sep = "\n"
      )
    ),
    width = 10, height = 5.6
  )
)

for (name in names(figures)) {
  f <- figures[[name]]
  path <- save_figure(f$plot, name, width = f$width, height = f$height)
  message("wrote ", sub(paste0(root, "/"), "", path, fixed = TRUE))
}

stats <- key_statistics(d)
dir.create(file.path(root, "results"), showWarnings = FALSE)
readr::write_csv(stats, file.path(root, "results", "key_statistics.csv"), na = "", eol = "\n")
message("wrote results/key_statistics.csv")

cat("\nKey statistics (results/key_statistics.csv)\n")
cat(sprintf(
  "  %-*s %9s %-9s %s\n",
  max(nchar(stats$statistic)), stats$statistic, as.character(stats$value), stats$unit, stats$detail
), sep = "")
