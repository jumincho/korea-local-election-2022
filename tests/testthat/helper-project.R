# The project's functions live in R/ and are sourced rather than installed as
# a package; testthat runs helper files before the tests, in their environment.
for (file in sort(list.files(here::here("R"), pattern = "[.]R$", full.names = TRUE))) {
  source(file, local = TRUE)
}

# Evaluate `code` with GEOS (planar) rather than s2 (spherical) geometry, as
# GeoJSON coordinates are planar by definition; sf's reminder that it treats
# longitude/latitude as planar is muted.
with_planar_geometry <- function(code) {
  s2 <- suppressMessages(sf::sf_use_s2(FALSE))
  on.exit(suppressMessages(sf::sf_use_s2(s2)), add = TRUE)
  withCallingHandlers(
    force(code),
    message = function(m) {
      if (grepl("assumes\\s+that\\s+they\\s+are\\s+planar", conditionMessage(m))) {
        invokeRestart("muffleMessage")
      }
    }
  )
}
