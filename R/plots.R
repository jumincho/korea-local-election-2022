# Chart builders. Each takes tidy tables and analysis results and returns a
# ggplot or patchwork object. The words around a chart (title, subtitle and
# caption) come from the caller, the figure functions in R/figures.R; a
# builder writes only the text inside the chart: axis titles, legends and
# labels.

#' Winner of every governor race, one map per election.
#'
#' @param winners From [province_winners()].
#' @param races The elections to map, one panel each, in panel order.
plot_winner_maps <- function(geometry, winners, parties, elections,
                             races = c("local_2018", "local_2022"),
                             title = NULL, subtitle = NULL, caption = NULL) {
  w <- winners[winners$election %in% races, ]
  w$bloc <- parties$bloc[match(w$winner, parties$party_id)]
  counts <- count_winners(w)
  counts$party <- parties$label[match(counts$winner, parties$party_id)]
  # Panel titles such as "2022: PPP 12 · DPK 5".
  panel <- vapply(races, function(id) {
    n <- counts[counts$election == id, ]
    sprintf(
      "%s: %s", election_year(id, elections),
      paste(n$party, n$races, collapse = paste0(" ", GLYPH$dot, " "))
    )
  }, character(1))
  map <- dplyr::inner_join(geometry, w, by = "province_code")
  map$panel <- factor(panel[map$election], levels = panel)
  blocs <- intersect(names(bloc_labels(parties)), map$bloc)

  ggplot2::ggplot(map) +
    ggplot2::geom_sf(ggplot2::aes(fill = .data$bloc), colour = CHART$surface, linewidth = 0.25) +
    ggplot2::facet_wrap(ggplot2::vars(.data$panel)) +
    ggplot2::scale_fill_manual(
      values = bloc_colours(parties)[blocs], labels = bloc_labels(parties)[blocs], breaks = blocs
    ) +
    ggplot2::labs(title = title, subtitle = subtitle, caption = caption) +
    map_layers() +
    ggplot2::theme(strip.text = ggplot2::element_text(size = ggplot2::rel(1.05)))
}

#' Lead of the PPP over the DPK in every governor race of one election: a map
#' on a binned diverging scale and a ranked bar chart coloured by the party
#' that led.
#'
#' @param margins From [bloc_margin()]: `province_code` and `margin_pp`.
#' @param limit The largest lead the colour scale covers, in percentage points.
plot_margin <- function(geometry, margins, provinces, parties, limit = 70,
                        title = NULL, subtitle = NULL, caption = NULL) {
  if (any(abs(margins$margin_pp) > limit, na.rm = TRUE)) {
    stop("A margin is beyond the colour scale's limit of ", limit, " points", call. = FALSE)
  }
  colours <- bloc_colours(parties)
  m <- margins
  m$label <- stats::reorder(province_labels(m$province_code, provinces), m$margin_pp)
  m$leader <- ifelse(m$margin_pp > 0, "conservative", "democratic")

  map <- ggplot2::ggplot(dplyr::inner_join(geometry, m, by = "province_code")) +
    ggplot2::geom_sf(
      ggplot2::aes(fill = .data$margin_pp),
      colour = CHART$surface, linewidth = 0.25
    ) +
    ggplot2::scale_fill_steps2(
      low = colours[["democratic"]], mid = CHART$neutral, high = colours[["conservative"]],
      midpoint = 0, limits = c(-limit, limit), breaks = c(-40, -20, 0, 20, 40),
      labels = function(x) format_pp(x, 0), name = "PPP lead over DPK, percentage points",
      guide = ggplot2::guide_coloursteps(
        title.position = "top", barwidth = ggplot2::unit(14, "lines"),
        barheight = ggplot2::unit(0.6, "lines")
      )
    ) +
    map_layers() +
    ggplot2::theme(
      legend.title = ggplot2::element_text(colour = CHART$ink_secondary, size = ggplot2::rel(0.85))
    )

  n <- nrow(m)
  bars <- ggplot2::ggplot(m, ggplot2::aes(x = .data$margin_pp, y = .data$label)) +
    ggplot2::geom_col(ggplot2::aes(fill = .data$leader), width = 0.72) +
    ggplot2::geom_vline(xintercept = 0, colour = CHART$axis, linewidth = 0.4) +
    ggplot2::geom_text(
      ggplot2::aes(
        label = format_margin(.data$margin_pp),
        hjust = ifelse(.data$margin_pp >= 0, -0.2, 1.2)
      ),
      size = 3, colour = CHART$ink_secondary
    ) +
    ggplot2::annotate(
      "text",
      x = c(-2, 2), y = n + 0.9, hjust = c(1, 0), size = 3, colour = CHART$ink_muted,
      label = c(paste(GLYPH$left, "DPK ahead"), paste("PPP ahead", GLYPH$right))
    ) +
    ggplot2::scale_fill_manual(values = colours, guide = "none") +
    ggplot2::scale_x_continuous(
      limits = c(-limit - 8, limit + 8), breaks = seq(-60, 60, 30),
      labels = function(x) format_pp(x, 0)
    ) +
    ggplot2::scale_y_discrete(expand = ggplot2::expansion(add = c(0.6, 1.4))) +
    ggplot2::labs(x = "PPP share minus DPK share (percentage points)", y = NULL) +
    theme_election() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())

  patchwork::wrap_plots(map, bars, widths = c(1.15, 1)) +
    patchwork::plot_annotation(
      title = title, subtitle = subtitle, caption = caption, theme = theme_election()
    )
}

#' Each bloc's share in two elections, one row per province (dumbbell chart),
#' with provinces sorted by the change in the democratic bloc's share.
#'
#' @param swing From [bloc_swing()].
#' @param years Labels of the two elections, e.g. `c("2018", "2022")`.
plot_swing <- function(swing, provinces, parties, years,
                       title = NULL, subtitle = NULL, caption = NULL) {
  labels <- bloc_labels(parties)
  s <- swing
  s$label <- province_labels(s$province_code, provinces)
  democratic <- s[s$bloc == "democratic", ]
  sorted <- democratic$label[order(democratic$change_pp, decreasing = TRUE)]
  s$label <- factor(s$label, levels = sorted)
  s$panel <- factor(labels[s$bloc], levels = labels[unique(s$bloc)])
  missing_year <- ifelse(is.na(s$share_from), years[1], years[2])
  s$note <- ifelse(
    is.na(s$change_pp), paste("no", missing_year, "candidate"), format_pp(s$change_pp)
  )
  s$note_x <- pmax(s$share_from, s$share_to, na.rm = TRUE) + 2.5
  ends <- tidyr::pivot_longer(
    s, c("share_from", "share_to"),
    names_to = "year", values_to = "share", values_drop_na = TRUE
  )
  ends$year <- factor(ifelse(ends$year == "share_from", years[1], years[2]), levels = years)

  ggplot2::ggplot(s, ggplot2::aes(y = .data$label)) +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = .data$share_from, xend = .data$share_to, yend = .data$label, colour = .data$bloc
      ),
      linewidth = 0.8, alpha = 0.5, na.rm = TRUE
    ) +
    ggplot2::geom_point(
      data = ends,
      ggplot2::aes(x = .data$share, shape = .data$year, colour = .data$bloc),
      fill = CHART$surface, size = 2.3, stroke = 1
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$note_x, label = .data$note),
      hjust = 0, size = 2.8, colour = CHART$ink_secondary
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$panel)) +
    ggplot2::scale_colour_manual(values = bloc_colours(parties), guide = "none") +
    ggplot2::scale_shape_manual(values = stats::setNames(c(21, 19), years)) +
    ggplot2::scale_x_continuous(
      limits = c(0, 100), breaks = seq(0, 80, 20), labels = percent_label, expand = c(0, 0)
    ) +
    ggplot2::labs(
      title = title, subtitle = subtitle, x = "Vote share", y = NULL, caption = caption
    ) +
    theme_election() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.spacing = ggplot2::unit(1.5, "lines")
    )
}

#' Province-level shares in two elections against each other, one panel per
#' bloc, with the line y = x, the least-squares line and Pearson's r.
#'
#' @param pairs From [paired_shares()]: `province_code`, `bloc`, `x`, `y`.
#' @param stats From [bloc_correlations()], one row per bloc.
#' @param panels Named vector: panel title for each bloc, in display order.
plot_share_scatter <- function(pairs, stats, provinces, parties, panels, x_title, y_title,
                               title = NULL, subtitle = NULL, caption = NULL) {
  colours <- bloc_colours(parties)
  p <- pairs[stats::complete.cases(pairs$x, pairs$y), ]
  p$label <- province_labels(p$province_code, provinces)
  p$panel <- factor(panels[p$bloc], levels = panels)
  stats$panel <- factor(panels[stats$bloc], levels = panels)
  stats$text <- sprintf(
    "r = %.2f (95%% CI %.2f to %.2f)\nn = %d provinces",
    stats$r, stats$conf_low, stats$conf_high, stats$n
  )

  ggplot2::ggplot(p, ggplot2::aes(x = .data$x, y = .data$y)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = CHART$axis, linewidth = 0.5) +
    ggplot2::annotate(
      "text",
      x = 90, y = 93, label = "y = x", angle = 45, size = 2.8, colour = CHART$ink_muted
    ) +
    ggplot2::geom_abline(
      data = stats,
      ggplot2::aes(slope = .data$slope, intercept = .data$intercept, colour = .data$bloc),
      linewidth = 0.6
    ) +
    ggplot2::geom_point(
      ggplot2::aes(fill = .data$bloc),
      shape = 21, colour = CHART$surface, size = 2.8, stroke = 0.6
    ) +
    ggrepel::geom_text_repel(
      ggplot2::aes(label = .data$label),
      size = 2.7, colour = CHART$ink_secondary, seed = 2022,
      box.padding = 0.3, point.padding = 0.15, min.segment.length = 0.3,
      segment.colour = CHART$axis, segment.size = 0.3, max.overlaps = Inf
    ) +
    ggplot2::geom_text(
      data = stats,
      ggplot2::aes(x = 3, y = 97, label = .data$text),
      hjust = 0, vjust = 1, size = 3, lineheight = 1.1, colour = CHART$ink, inherit.aes = FALSE
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$panel)) +
    ggplot2::scale_colour_manual(values = colours, guide = "none") +
    ggplot2::scale_fill_manual(values = colours, guide = "none") +
    ggplot2::scale_x_continuous(breaks = seq(0, 100, 20), labels = percent_label) +
    ggplot2::scale_y_continuous(breaks = seq(0, 100, 20), labels = percent_label) +
    ggplot2::coord_equal(xlim = c(0, 100), ylim = c(0, 100), expand = FALSE) +
    ggplot2::labs(title = title, subtitle = subtitle, x = x_title, y = y_title, caption = caption) +
    theme_election() +
    ggplot2::theme(panel.spacing = ggplot2::unit(2, "lines"))
}

#' Exit-poll vote share by sex and age group, with turnout underneath.
plot_exit_poll <- function(exit_poll, parties, title = NULL, subtitle = NULL, caption = NULL) {
  shown <- parties[parties$party_id %in% exit_poll$party_id, ]
  colours <- stats::setNames(shown$colour, shown$label)
  e <- exit_poll
  e$party <- factor(parties$label[match(e$party_id, parties$party_id)], levels = names(colours))
  e$sex <- factor(ifelse(e$sex == "male", "Men", "Women"), levels = c("Men", "Women"))
  # Age groups are "20s" to "70s" (see read_exit_poll()), so text order is age order.
  e$age_group <- factor(e$age_group, levels = sort(unique(e$age_group)))
  oldest <- e[e$age_group == levels(e$age_group)[nlevels(e$age_group)], ]
  # Vote share and turnout share one scale, so that the two panels compare.
  percent_scale <- ggplot2::scale_y_continuous(
    limits = c(0, 85), breaks = seq(0, 80, 20), labels = percent_label
  )

  shares <- ggplot2::ggplot(
    e, ggplot2::aes(x = .data$age_group, y = .data$vote_share_pct, colour = .data$party)
  ) +
    ggplot2::geom_line(ggplot2::aes(group = .data$party), linewidth = 0.7) +
    ggplot2::geom_point(size = 2.4) +
    ggplot2::geom_text(
      data = oldest, ggplot2::aes(label = .data$party),
      hjust = 0, nudge_x = 0.15, size = 3, colour = CHART$ink_secondary
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$sex)) +
    ggplot2::scale_colour_manual(values = colours) +
    percent_scale +
    ggplot2::labs(x = NULL, y = "Vote share") +
    theme_election()

  turnout <- unique(e[c("sex", "age_group", "turnout_pct")])
  turnout <- turnout[order(turnout$sex, turnout$age_group), ]
  # Flag groups whose turnout repeats the previous age group's (same sex).
  same_sex <- turnout$sex[-1] == turnout$sex[-nrow(turnout)]
  turnout$repeated <- c(FALSE, diff(turnout$turnout_pct) == 0 & same_sex)
  turnout_plot <- ggplot2::ggplot(
    turnout, ggplot2::aes(x = .data$age_group, y = .data$turnout_pct, group = .data$sex)
  ) +
    ggplot2::geom_line(colour = CHART$ink_secondary, linewidth = 0.6) +
    ggplot2::geom_point(
      ggplot2::aes(shape = .data$repeated),
      colour = CHART$ink_secondary, fill = CHART$surface, size = 2.2, stroke = 0.9
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$sex)) +
    ggplot2::scale_shape_manual(
      values = c("FALSE" = 19, "TRUE" = 21),
      labels = c("FALSE" = "Turnout", "TRUE" = "Same value as the age group before it")
    ) +
    percent_scale +
    ggplot2::labs(x = "Age group", y = "Turnout") +
    theme_election() +
    ggplot2::theme(strip.text = ggplot2::element_blank())

  patchwork::wrap_plots(shares, turnout_plot, ncol = 1, heights = c(2, 1)) +
    patchwork::plot_annotation(
      title = title, subtitle = subtitle, caption = caption, theme = theme_election()
    )
}

#' Share of each kind of local office won by each bloc, elections compared.
#'
#' @param officials From [officials_by_bloc()]: one row per election, office
#'   and bloc.
plot_elected_officials <- function(officials, offices, elections, parties,
                                   title = NULL, subtitle = NULL, caption = NULL) {
  stack_order <- c("democratic", "other", "conservative")
  o <- officials
  o$office <- factor(offices$label[match(o$office, offices$office)], levels = offices$label)
  o$year <- election_year(o$election, elections)
  o$year <- factor(o$year, levels = rev(sort(unique(o$year))))
  o$bloc <- factor(o$bloc, levels = stack_order)
  # Only segments wide enough to hold a label get one.
  o$text <- ifelse(o$share_pct >= 8, sprintf("%.1f%%", o$share_pct), "")

  ggplot2::ggplot(o, ggplot2::aes(x = .data$share_pct, y = .data$year, fill = .data$bloc)) +
    ggplot2::geom_col(
      width = 0.62, colour = CHART$surface, linewidth = 0.5,
      position = ggplot2::position_stack(reverse = TRUE)
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = .data$text),
      position = ggplot2::position_stack(vjust = 0.5, reverse = TRUE),
      colour = CHART$on_fill, size = 3, fontface = "bold"
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$office), ncol = 1) +
    ggplot2::scale_fill_manual(
      values = bloc_colours(parties)[stack_order], labels = bloc_labels(parties)[stack_order],
      breaks = c("democratic", "conservative", "other")
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 100, 25), labels = percent_label, expand = c(0, 0)
    ) +
    ggplot2::labs(title = title, subtitle = subtitle, x = NULL, y = NULL, caption = caption) +
    theme_election() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
}
