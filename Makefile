# Common tasks; run from the repository root. `make help` lists them.

RSCRIPT ?= Rscript

.PHONY: help all data figures test lint check

help: ## List the available targets
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  make %-8s %s\n", $$1, $$2}'

all: check figures ## Lint, test and regenerate the figures

data: ## Rebuild data/ from the original files in data-raw/
	$(RSCRIPT) data-raw/tidy_election_data.R
	$(RSCRIPT) data-raw/build_province_geometry.R

figures: ## Regenerate figures/ and results/key_statistics.csv
	$(RSCRIPT) scripts/make_figures.R

test: ## Run the test suite
	$(RSCRIPT) tests/testthat.R

lint: ## Lint all R code with the settings in .lintr
	$(RSCRIPT) -e 'lints <- lintr::lint_dir("."); print(lints); quit(status = length(lints) > 0)'

check: lint test ## Lint and test
