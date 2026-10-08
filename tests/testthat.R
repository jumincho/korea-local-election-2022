# Run the test suite from anywhere inside the repository:
#   Rscript tests/testthat.R        # or: make test
#
# A warning fails the run as surely as a failed expectation: in this code a
# warning (recycling, coercion, a dropped row) means a wrong number.
testthat::test_dir(
  here::here("tests", "testthat"),
  stop_on_failure = TRUE, stop_on_warning = TRUE
)
