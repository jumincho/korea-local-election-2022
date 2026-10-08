#!/usr/bin/env Rscript
# Regenerate every figure in figures/ and the key statistics quoted in the
# README (results/key_statistics.csv), then print those statistics. The
# figures are defined in R/figures.R and the statistics in R/key_statistics.R;
# this script only runs them.
#
# Usage, from anywhere inside the repository:
#   Rscript scripts/make_figures.R        # or: make figures

for (file in sort(list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE))) {
  source(file)
}

d <- load_election_data()
figures <- write_figures(d)
statistics <- key_statistics(d)
results <- write_key_statistics(statistics)
written <- sub(paste0(here::here(), "/"), "", c(figures, results), fixed = TRUE)
message(paste("wrote", written, collapse = "\n"))

cat("\nKey statistics (results/key_statistics.csv)\n")
cat(sprintf(
  "  %-*s %9s %-9s %s\n",
  max(nchar(statistics$statistic)), statistics$statistic, as.character(statistics$value),
  statistics$unit, statistics$detail
), sep = "")
