# Run every analysis script and write all figures to figures/.
#
# Usage:
#   Rscript src/run_all.R
#   # or from R:
#   source(here::here("src", "run_all.R"))

scripts <- c(
  "07_local_election_map.R",
  "08_local_election_map.R",
  "presidential_local_correlation.R",
  "regional_party_support_trend.R",
  "vote_share_by_gender_age.R",
  "other_elected_officials_ratio.R"
)

for (s in scripts) {
  message("\n=== ", s, " ===")
  source(here::here("src", s), encoding = "UTF-8")
}
