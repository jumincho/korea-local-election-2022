# The visual system in R/theme.R: glyphs, number formats, bloc colours and
# names.

test_that("glyphs are marked as UTF-8, whatever the locale", {
  expect_true(all(vapply(GLYPH, Encoding, character(1)) == "UTF-8"))
})

test_that("format_pp writes an explicit sign and a true minus", {
  expect_identical(
    format_pp(c(1.234, -2, 0, NA)),
    c("+1.2", paste0(GLYPH$minus, "2.0"), "0.0", NA)
  )
  expect_identical(format_margin(c(-0.15, 12.34)), c(paste0(GLYPH$minus, "0.15"), "+12.3"))
  expect_identical(percent_label(c(0, 20)), c("0%", "20%"))
})

test_that("bloc_colours needs exactly one colour per bloc", {
  parties <- dplyr::tibble(
    party_id = c("a", "b", "c"),
    bloc = c("democratic", "conservative", "conservative"),
    colour = c("#2a78d6", "#e34948", "#e34948")
  )
  expect_identical(bloc_colours(parties)[["conservative"]], "#e34948")
  parties$colour[3] <- "#000000"
  expect_error(bloc_colours(parties), "exactly one colour")
})

test_that("bloc_labels name the parties of each bloc", {
  labels <- bloc_labels(read_parties())
  expect_identical(labels[["democratic"]], "Democratic Party (DPK)")
  expect_identical(labels[["conservative"]], "LKP (2018) / PPP (2022)")
  expect_setequal(names(labels), unique(read_parties()$bloc))
})
