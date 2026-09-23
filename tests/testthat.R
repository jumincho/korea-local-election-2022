# Run the test suite from anywhere inside the repository:
#   Rscript tests/testthat.R        # or: make test
testthat::test_dir(here::here("tests", "testthat"), stop_on_failure = TRUE)
