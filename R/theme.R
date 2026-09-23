# Visual system shared by every figure: chart chrome, party colours, a ggplot2
# theme and a PNG writer.
#
# Party colours come from data/parties.csv: DPK blue and LKP/PPP red are
# recognisable party colours that also stay distinct under protanopia and
# deuteranopia (checked with a CVD simulation, OKLab distance 21.6); every
# other party, independents and "other" share one neutral grey.

# R leaves \u escapes unmarked in C/POSIX locales, where they would then render
# as garbage; marking them as UTF-8 makes the figures independent of the locale.
as_utf8 <- function(x) {
  Encoding(x)[validUTF8(x)] <- "UTF-8"
  x
}

GLYPH <- list(
  minus = as_utf8("\u2212"),
  dot = as_utf8("\u00b7"),
  left = as_utf8("\u2190"),
  right = as_utf8("\u2192")
)

CHART <- list(
  surface = "#fcfcfb",
  ink = "#0b0b0b",
  ink_secondary = "#52514e",
  ink_muted = "#898781",
  grid = "#e1e0d9",
  axis = "#c3c2b7",
  neutral = "#f0efec"
)

#' Display colour of each bloc, taken from data/parties.csv.
bloc_colours <- function(parties) {
  colours <- tapply(parties$colour, parties$bloc, unique)
  if (any(lengths(colours) != 1)) stop("Each bloc needs exactly one colour", call. = FALSE)
  unlist(colours)
}

#' Human-readable bloc names for legends and panel titles.
#'
#' The conservative bloc is the Liberty Korea Party in 2018 and the People
#' Power Party in 2022 (its successor after the 2020 mergers).
bloc_labels <- function(parties) {
  label <- function(id) parties$label[parties$party_id == id]
  c(
    democratic = sprintf("Democratic Party (%s)", label("dpk")),
    conservative = sprintf("%s (2018) / %s (2022)", label("lkp"), label("ppp")),
    independent = "Independent",
    minor = "Minor parties",
    other = "Other parties and independents"
  )
}

#' Percentage-point change with an explicit sign and a true minus sign.
format_pp <- function(x, digits = 1) {
  out <- formatC(abs(x), format = "f", digits = digits)
  sign <- ifelse(x > 0, "+", ifelse(x < 0, GLYPH$minus, ""))
  ifelse(is.na(x), NA_character_, paste0(sign, out))
}

#' Base theme: recessive hairline grid, muted axes, left-aligned titles.
theme_election <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = CHART$surface, colour = NA),
      panel.grid.major = ggplot2::element_line(colour = CHART$grid, linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(colour = CHART$ink_secondary),
      axis.title = ggplot2::element_text(colour = CHART$ink_secondary, size = ggplot2::rel(0.9)),
      plot.title = ggplot2::element_text(
        colour = CHART$ink, face = "bold", size = ggplot2::rel(1.25),
        margin = ggplot2::margin(b = 4)
      ),
      plot.subtitle = ggplot2::element_text(
        colour = CHART$ink_secondary, margin = ggplot2::margin(b = 10)
      ),
      plot.caption = ggplot2::element_text(
        colour = CHART$ink_muted, size = ggplot2::rel(0.8), hjust = 0,
        margin = ggplot2::margin(t = 10)
      ),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      strip.text = ggplot2::element_text(
        colour = CHART$ink, face = "bold", hjust = 0, size = ggplot2::rel(0.95)
      ),
      legend.position = "top",
      legend.justification = "left",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour = CHART$ink_secondary),
      legend.margin = ggplot2::margin(0, 0, 0, 0),
      plot.margin = ggplot2::margin(12, 16, 12, 12)
    )
}

#' Theme for maps: no axes or grid.
theme_election_map <- function(base_size = 11) {
  theme_election(base_size) +
    ggplot2::theme(
      axis.text = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
    )
}

#' Write a figure to figures/<name>.png with ragg (no system graphics needed).
save_figure <- function(plot, name, width, height, dpi = 200, dir = here::here("figures")) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  path <- file.path(dir, paste0(name, ".png"))
  ggplot2::ggsave(
    path, plot,
    width = width, height = height, units = "in", dpi = dpi,
    device = ragg::agg_png, bg = CHART$surface
  )
  invisible(path)
}
