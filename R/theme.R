# Visual system shared by every figure: chart colours, party colours and
# names, number formats, ggplot2 themes and a PNG writer.
#
# Party colours come from data/parties.csv: DPK blue and LKP/PPP red are
# recognisable party colours that also stay distinct under protanopia and
# deuteranopia (checked with a CVD simulation, OKLab distance 21.6); every
# other party, independents and "other" share one neutral grey.

# Typographic characters. intToUtf8() marks its result as UTF-8 in every
# locale, whereas a "−" literal is left unmarked in a C/POSIX locale and
# would then render as garbage.
GLYPH <- list(
  minus = intToUtf8(0x2212),
  dot = intToUtf8(0x00b7),
  left = intToUtf8(0x2190),
  right = intToUtf8(0x2192)
)

CHART <- list(
  surface = "#fcfcfb",
  ink = "#0b0b0b",
  ink_secondary = "#52514e",
  ink_muted = "#898781",
  grid = "#e1e0d9",
  axis = "#c3c2b7",
  neutral = "#f0efec",
  on_fill = "#ffffff"
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

#' Margins below one point get two decimals, so that a close race is not
#' rounded to zero.
format_margin <- function(x) {
  ifelse(abs(x) < 1, format_pp(x, 2), format_pp(x, 1))
}

#' Axis labels on a 0 to 100 percentage scale: 20 becomes "20%".
percent_label <- function(x) paste0(x, "%")

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

#' Projection and theme for maps: Korea 2000 / Unified CS (EPSG:5179), the
#' national grid, without graticules.
map_layers <- function() {
  list(
    ggplot2::coord_sf(crs = sf::st_crs(5179), datum = NA),
    theme_election_map()
  )
}

#' Write a figure to <dir>/<name>.png with ragg (no system graphics needed).
#'
#' @return The path written, invisibly.
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
