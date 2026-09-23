provinces <- read_provinces()
geo <- read_province_geometry(provinces)

test_that("there is exactly one boundary per province code, in lookup order", {
  expect_equal(nrow(geo), 17)
  expect_identical(geo$province_code, provinces$province_code)
  expect_true(all(sf::st_geometry_type(geo) == "MULTIPOLYGON"))
})

test_that("every race in the vote data joins to a boundary by province code", {
  winners <- province_winners(read_vote_share(provinces))
  expect_true(all(winners$province_code %in% geo$province_code))
  joined <- dplyr::inner_join(geo, winners, by = "province_code")
  expect_equal(nrow(joined), nrow(winners))
})

test_that("the GeoJSON properties match data/provinces.csv", {
  raw <- sf::st_read(data_path("geo", "provinces.geojson"), quiet = TRUE, stringsAsFactors = FALSE)
  expect_identical(raw$province_code, provinces$province_code)
  expect_identical(raw$name_en, provinces$name_en)
  expect_identical(raw$name_ko, provinces$name_ko)
})

test_that("boundaries are valid, non-overlapping polygons in WGS 84", {
  expect_equal(sf::st_crs(geo)$epsg, 4326L)
  with_planar_geometry({
    expect_true(all(sf::st_is_valid(geo)))
    projected <- sf::st_transform(geo, 5179)
    expect_true(all(sf::st_is_valid(projected)))
    area <- as.numeric(sf::st_area(projected))
    overlap_m2 <- sum(area) - as.numeric(sf::st_area(sf::st_union(projected)))
    expect_lt(overlap_m2, 1)
    # The source covers about 100,000 km2; simplification changes that by < 0.1 %.
    expect_equal(sum(area) / 1e6, 100058, tolerance = 0.001)
  })
})

test_that("small islands survive simplification: Dokdo's two main islets", {
  dokdo_box <- sf::st_as_sfc(
    sf::st_bbox(c(xmin = 131.85, ymin = 37.23, xmax = 131.88, ymax = 37.25), crs = 4326)
  )
  gyeongbuk <- provinces$province_code[provinces$label == "Gyeongbuk"]
  parts <- sf::st_cast(geo[geo$province_code == gyeongbuk, ], "POLYGON", warn = FALSE)
  with_planar_geometry({
    expect_equal(sum(lengths(sf::st_intersects(parts, dokdo_box)) > 0), 2)
  })
})

test_that("the GeoJSON is small, rounded and inside South Korea's extent", {
  path <- data_path("geo", "provinces.geojson")
  expect_lt(file.size(path), 1024^2)
  expect_false(any(grepl("[0-9][.][0-9]{7,}", readLines(path, warn = FALSE))))
  bb <- sf::st_bbox(geo)
  expect_true(bb[["xmin"]] > 124 && bb[["xmax"]] < 132)
  expect_true(bb[["ymin"]] > 33 && bb[["ymax"]] < 39)
})
