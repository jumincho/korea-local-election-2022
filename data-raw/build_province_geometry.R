#!/usr/bin/env Rscript
# Build data/geo/provinces.geojson from the original province boundary file.
#
# Source: data-raw/shapefile/ctp_rvn.{shp,shx,dbf,prj}, 13 MB and 810k
# vertices, kept byte for byte as committed in 2022; data-raw/README.md says
# what is known about where it came from.
#
# Usage, from the repository root:
#   Rscript data-raw/build_province_geometry.R
#
# Steps
#   1. Read the shapefile (attributes are CP949) and check every CTPRVN_CD code
#      and Korean name against data/provinces.csv. Rows are matched by code,
#      never by position.
#   2. Clean the coverage. Neighbouring provinces were digitised separately and
#      their shared borders criss-cross at centimetre scale, leaving thousands
#      of sliver overlaps and gaps. All boundaries are noded into one planar
#      arrangement; each face is labelled with the provinces containing it
#      (exact, because no boundary crosses a face), and every sliver is given
#      to the neighbour it shares the longest border with (an overlap only to a
#      province that claims it). Uncovered faces of at least MIN_AREA_M2 are
#      genuine holes in the source, e.g. the Saemangeum sea-wall basin, and stay.
#   3. Drop islands and fill holes smaller than MIN_AREA_M2.
#   4. Simplify with shared borders intact: rings are cut into arcs at the
#      points where three or more borders meet, every arc is simplified once
#      (GEOS topology-preserving simplifier on all arcs together, tolerance
#      TOLERANCE_M metres) and the rings are reassembled from the arcs.
#   5. Transform the arcs to WGS 84, round them to DECIMALS places (rounding
#      per arc keeps shared borders identical), rebuild the polygons, check
#      that they are valid and write RFC 7946 GeoJSON; the file is then read
#      back and checked again.

SHAPEFILE <- file.path("data-raw", "shapefile", "ctp_rvn.shp")
OUTPUT <- file.path("data", "geo", "provinces.geojson")

MIN_AREA_M2 <- 5e4 # 0.05 km2: smaller islands are dropped, smaller holes filled
TOLERANCE_M <- 200 # simplification tolerance in metres
DECIMALS <- 6 # output coordinate precision, about 0.1 m (5 creates pinch points)

# ---- 1. source --------------------------------------------------------------

read_provinces <- function() {
  readr::read_csv(
    here::here("data", "provinces.csv"),
    col_types = readr::cols(.default = readr::col_character()),
    locale = readr::locale(encoding = "UTF-8"), progress = FALSE
  )
}

read_source <- function(path, provinces) {
  src <- sf::st_read(path, options = "ENCODING=CP949", quiet = TRUE, stringsAsFactors = FALSE)
  i <- match(provinces$province_code, src$CTPRVN_CD)
  if (nrow(src) != nrow(provinces) || anyNA(i)) {
    stop("Boundary codes do not match data/provinces.csv", call. = FALSE)
  }
  src <- src[i, ]
  if (!all(src$CTP_KOR_NM == provinces$name_ko)) {
    stop("Korean province names do not match data/provinces.csv", call. = FALSE)
  }
  src
}

# Polygon parts of every province with area >= min_area, as an sf table.
polygon_parts <- function(geometry, min_area) {
  parts <- sf::st_cast(
    sf::st_sf(province = seq_along(geometry), geometry = sf::st_cast(geometry, "MULTIPOLYGON")),
    "POLYGON",
    warn = FALSE
  )
  parts[as.numeric(sf::st_area(parts)) >= min_area, ]
}

# ---- 2-3. coverage cleaning and small features ------------------------------

# Faces of the planar arrangement formed by all boundaries.
arrangement_faces <- function(geometry) {
  edges <- sf::st_union(sf::st_boundary(geometry))
  sf::st_cast(sf::st_collection_extract(sf::st_polygonize(edges), "POLYGON"), "POLYGON")
}

# Province(s) containing each face, as a list of integer vectors.
face_membership <- function(faces, provinces_geometry) {
  hits <- sf::st_intersects(provinces_geometry, sf::st_point_on_surface(faces))
  members <- vector("list", length(faces))
  for (k in seq_along(hits)) {
    for (f in hits[[k]]) members[[f]] <- c(members[[f]], k)
  }
  members
}

# Integer id per distinct coordinate pair (exact match).
vertex_ids <- function(x, y) {
  key <- sprintf("%a %a", x, y)
  match(key, unique(key))
}

# Length of the border shared by each pair of adjacent faces, found by exact
# segment matching: polygonize() reuses the noded coordinates, so a border
# segment appears, bit for bit, in both faces it separates.
face_adjacency <- function(faces) {
  xy <- sf::st_coordinates(faces)
  from <- seq_len(nrow(xy) - 1)
  to <- from + 1L
  same_ring <- xy[from, "L1"] == xy[to, "L1"] & xy[from, "L2"] == xy[to, "L2"]
  from <- from[same_ring]
  to <- to[same_ring]
  vid <- vertex_ids(xy[, "X"], xy[, "Y"])
  segment <- pmin(vid[from], vid[to]) * (max(vid) + 1) + pmax(vid[from], vid[to])
  seg <- data.frame(
    segment = segment,
    face = as.integer(xy[from, "L2"]),
    length = sqrt((xy[to, "X"] - xy[from, "X"])^2 + (xy[to, "Y"] - xy[from, "Y"])^2)
  )
  seg <- seg[order(seg$segment, method = "radix"), ]
  twin <- which(seg$segment[-1] == seg$segment[-nrow(seg)])
  pairs <- data.frame(a = seg$face[twin], b = seg$face[twin + 1], length = seg$length[twin])
  pairs <- pairs[pairs$a != pairs$b, ]
  both <- rbind(pairs, data.frame(a = pairs$b, b = pairs$a, length = pairs$length))
  stats::aggregate(length ~ a + b, data = both, FUN = sum)
}

# Region growing: each unlabelled face (NA) joins the province label (> 0) it
# shares the longest border with; faces claimed by several provinces may only
# join one of them. Holes (label 0) never spread. Repeats until every
# reachable face is labelled.
grow_labels <- function(owner, members, adjacency) {
  todo <- which(is.na(owner))
  while (length(todo) > 0) {
    labelled <- !is.na(owner[adjacency$b]) & owner[adjacency$b] > 0
    edges <- adjacency[adjacency$a %in% todo & labelled, ]
    edges$label <- owner[edges$b]
    eligible <- mapply(
      function(face, label) length(members[[face]]) == 0 || label %in% members[[face]],
      edges$a, edges$label
    )
    edges <- edges[eligible, ]
    if (nrow(edges) == 0) break
    score <- stats::aggregate(length ~ a + label, data = edges, FUN = sum)
    score <- score[order(score$a, -score$length, score$label), ]
    best <- score[!duplicated(score$a), ]
    owner[best$a] <- best$label
    todo <- setdiff(todo, best$a)
  }
  owner
}

clean_coverage <- function(geometry, min_area) {
  parts <- polygon_parts(geometry, min_area)
  source_geometry <- do.call(c, lapply(seq_along(geometry), function(k) {
    sf::st_union(sf::st_geometry(parts)[parts$province == k])
  }))
  faces <- arrangement_faces(sf::st_geometry(parts))
  members <- face_membership(faces, source_geometry)
  n_members <- lengths(members)
  area <- as.numeric(sf::st_area(faces))
  owner <- rep(NA_integer_, length(faces))
  owner[n_members == 1] <- unlist(members[n_members == 1])
  hole <- n_members == 0 & area >= min_area
  gap <- n_members == 0 & !hole
  owner[hole] <- 0L
  owner <- grow_labels(owner, members, face_adjacency(faces))
  largest <- function(x) if (length(x) > 0) round(max(x)) else 0
  report <- c(
    faces = length(faces), overlaps = sum(n_members > 1),
    largest_overlap_m2 = largest(area[n_members > 1]),
    gaps = sum(gap), largest_gap_m2 = largest(area[gap]),
    holes_kept = sum(hole), largest_hole_m2 = largest(area[hole]),
    unassigned = sum(is.na(owner))
  )
  if (report[["unassigned"]] > 0) stop("Some sliver faces could not be assigned", call. = FALSE)
  cleaned <- do.call(c, lapply(seq_along(geometry), function(k) {
    sf::st_union(faces[owner == k], is_coverage = TRUE)
  }))
  kept <- polygon_parts(cleaned, min_area)
  cleaned <- do.call(c, lapply(seq_along(geometry), function(k) {
    sf::st_cast(sf::st_combine(sf::st_geometry(kept)[kept$province == k]), "MULTIPOLYGON")
  }))
  list(geometry = cleaned, report = report)
}

# ---- 4. arcs and topology-preserving simplification -------------------------

# Rings of a polygon coverage with one id per distinct vertex.
coverage_rings <- function(geometry) {
  xy <- sf::st_coordinates(geometry)
  ring_key <- paste(xy[, "L3"], xy[, "L2"], xy[, "L1"])
  ring <- match(ring_key, unique(ring_key))
  closing <- c(ring[-1] != ring[-length(ring)], TRUE)
  xy <- xy[!closing, ]
  ring <- ring[!closing]
  vid <- vertex_ids(xy[, "X"], xy[, "Y"])
  coords <- matrix(NA_real_, max(vid), 2)
  coords[vid, ] <- xy[, c("X", "Y")]
  meta <- unique(data.frame(
    ring = ring, feature = xy[, "L3"], part = xy[, "L2"], order = xy[, "L1"]
  ))
  list(vertex = split(vid, ring), coords = coords, meta = meta)
}

# A vertex is a junction when its neighbours differ between the rings that
# pass through it (where borders meet or part), or when a ring visits it twice.
find_junctions <- function(rings) {
  vid <- unlist(rings$vertex, use.names = FALSE)
  ring <- rep(seq_along(rings$vertex), lengths(rings$vertex))
  n <- lengths(rings$vertex)[ring]
  pos <- sequence(lengths(rings$vertex)) - 1L
  start <- cumsum(c(0L, lengths(rings$vertex)))[ring]
  prev <- vid[start + (pos - 1L) %% n + 1L]
  nxt <- vid[start + (pos + 1L) %% n + 1L]
  neighbours <- paste(pmin(prev, nxt), pmax(prev, nxt))
  distinct <- !duplicated(data.frame(vid, neighbours))
  n_pairs <- tabulate(vid[distinct], nbins = nrow(rings$coords))
  revisits <- tabulate(vid[duplicated(data.frame(vid, ring))], nbins = nrow(rings$coords))
  n_pairs > 1 | revisits > 0
}

# Cut one ring (vertex ids, not closed) into arcs from junction to junction.
# A ring without junctions is a single closed arc, rotated to start at its
# smallest vertex id so that the same ring traced by two provinces matches.
cut_ring <- function(v, junction) {
  at <- which(junction[v])
  if (length(at) == 0) {
    v <- c(v[which.min(v):length(v)], v[seq_len(which.min(v) - 1)])
    return(list(c(v, v[1])))
  }
  v <- c(v[at[1]:length(v)], v[seq_len(at[1] - 1)])
  ends <- c(which(junction[v]), length(v) + 1L)
  closed <- c(v, v[1])
  lapply(seq_len(length(ends) - 1), function(i) closed[ends[i]:ends[i + 1]])
}

# Orient an arc canonically so that the same border traced in either direction
# gets the same representation. Returns the arc and whether it was reversed.
canonical_arc <- function(p) {
  n <- length(p)
  flip <- if (p[1] != p[n]) p[1] > p[n] else n > 3 && p[2] > p[n - 1]
  list(arc = if (flip) rev(p) else p, reversed = flip)
}

# Cut every ring into arcs and store each distinct arc once; a border shared
# by two provinces becomes one arc referenced by both rings.
split_into_arcs <- function(rings) {
  junction <- find_junctions(rings)
  store <- new.env(hash = TRUE)
  store$arcs <- list()
  intern <- function(a) {
    key <- paste(length(a), a[1], a[2], a[length(a) - 1], a[length(a)])
    hit <- store[[key]]
    if (is.null(hit)) {
      hit <- length(store$arcs) + 1L
      store$arcs[[hit]] <- a
      store[[key]] <- hit
    } else if (!identical(store$arcs[[hit]], a)) {
      stop("Arc key collision", call. = FALSE)
    }
    hit
  }
  ring_arcs <- lapply(rings$vertex, function(v) {
    pieces <- lapply(cut_ring(v, junction), canonical_arc)
    list(
      ref = vapply(pieces, function(piece) intern(piece$arc), integer(1)),
      reversed = vapply(pieces, `[[`, logical(1), "reversed")
    )
  })
  list(arcs = store$arcs, ring_arcs = ring_arcs, junctions = sum(junction))
}

# Simplify all arcs together, so that no simplified arc crosses another, then
# transform to WGS 84 and round. Arc end points (junctions) are preserved.
simplify_arcs <- function(arcs, coords, crs, tolerance, decimals) {
  lines <- sf::st_sfc(
    sf::st_multilinestring(lapply(arcs, function(a) coords[a, , drop = FALSE])),
    crs = crs
  )
  simplified <- sf::st_simplify(lines, preserveTopology = TRUE, dTolerance = tolerance)
  if (length(simplified[[1]]) != length(arcs)) stop("Simplification lost arcs", call. = FALSE)
  wgs84 <- sf::st_transform(simplified, 4326)
  lapply(unclass(wgs84[[1]]), function(m) {
    m <- round(m, decimals)
    m[c(TRUE, rowSums(abs(diff(m))) > 0), , drop = FALSE]
  })
}

build_ring <- function(ring_arcs, arcs) {
  pieces <- Map(function(ref, reversed) {
    a <- arcs[[ref]]
    if (reversed) a[rev(seq_len(nrow(a))), , drop = FALSE] else a
  }, ring_arcs$ref, ring_arcs$reversed)
  do.call(rbind, c(pieces[1], lapply(pieces[-1], function(p) p[-1, , drop = FALSE])))
}

# A ring needs at least four points (first == last) and a non-zero area.
usable_ring <- function(m) {
  n <- nrow(m)
  n >= 4 && all(m[1, ] == m[n, ]) &&
    abs(sum(m[-n, 1] * m[-1, 2] - m[-1, 1] * m[-n, 2])) > 0
}

assemble_polygons <- function(rings, split, arcs, n_features) {
  ring_xy <- lapply(split$ring_arcs, build_ring, arcs = arcs)
  ok <- vapply(ring_xy, usable_ring, logical(1))
  geoms <- lapply(seq_len(n_features), function(feature) {
    meta <- rings$meta[rings$meta$feature == feature, ]
    polys <- lapply(split(meta, meta$part), function(part) {
      part <- part[order(part$order), ]
      if (!ok[part$ring[1]]) return(NULL)
      ring_xy[part$ring[ok[part$ring]]]
    })
    sf::st_multipolygon(Filter(Negate(is.null), polys))
  })
  list(geometry = sf::st_sfc(geoms, crs = 4326), dropped_rings = sum(!ok))
}

# ---- 5. validity and output -------------------------------------------------

# Validity in the GeoJSON's own planar lon/lat space (GEOS rather than s2) and,
# because the figures are drawn in it, in Korea 2000 / Unified CS (EPSG:5179).
# Polygonal geometry only, and no overlaps between provinces.
check_output_geometry <- function(geometry) {
  s2 <- suppressMessages(sf::sf_use_s2(FALSE))
  on.exit(suppressMessages(sf::sf_use_s2(s2)), add = TRUE)
  projected <- sf::st_transform(geometry, 5179)
  area_m2 <- sum(as.numeric(sf::st_area(projected)))
  union_m2 <- as.numeric(sf::st_area(sf::st_union(projected)))
  problems <- c(
    "non-polygonal geometry" =
      !all(sf::st_geometry_type(geometry) %in% c("POLYGON", "MULTIPOLYGON")),
    "invalid in lon/lat" = !all(sf::st_is_valid(geometry)),
    "invalid in EPSG:5179" = !all(sf::st_is_valid(projected)),
    "provinces overlap" = area_m2 - union_m2 > 1
  )
  if (any(problems)) {
    stop(
      "Output geometry check failed: ", paste(names(problems)[problems], collapse = ", "),
      ". Try a larger DECIMALS.",
      call. = FALSE
    )
  }
  invisible(geometry)
}

write_geojson <- function(geometry, provinces, path, decimals) {
  out <- sf::st_sf(
    province_code = provinces$province_code,
    name_en = provinces$name_en,
    name_ko = provinces$name_ko,
    geometry = geometry
  )
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  sf::st_write(
    out, path,
    driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE,
    layer_options = c("RFC7946=YES", paste0("COORDINATE_PRECISION=", decimals))
  )
  invisible(out)
}

summary_table <- function(source_geometry, output_geometry, provinces) {
  area_km2 <- function(g) as.numeric(sf::st_area(sf::st_transform(g, 5179))) / 1e6
  vertices <- function(g) vapply(g, function(x) nrow(sf::st_coordinates(x)), numeric(1))
  data.frame(
    code = provinces$province_code,
    province = provinces$label,
    area_source_km2 = round(area_km2(source_geometry), 1),
    area_output_km2 = round(area_km2(output_geometry), 1),
    vertices_source = vertices(source_geometry),
    vertices_output = vertices(output_geometry)
  )
}

main <- function() {
  provinces <- read_provinces()
  src <- read_source(here::here(SHAPEFILE), provinces)
  geometry <- sf::st_make_valid(sf::st_geometry(src))

  cleaned <- clean_coverage(geometry, MIN_AREA_M2)
  message("coverage: ", paste(names(cleaned$report), cleaned$report, sep = " = ", collapse = ", "))

  rings <- coverage_rings(cleaned$geometry)
  split <- split_into_arcs(rings)
  message(sprintf("arcs: %d (junctions: %d)", length(split$arcs), split$junctions))
  arcs <- simplify_arcs(split$arcs, rings$coords, sf::st_crs(src), TOLERANCE_M, DECIMALS)
  built <- assemble_polygons(rings, split, arcs, nrow(src))
  message("rings dropped after rounding: ", built$dropped_rings)
  check_output_geometry(built$geometry)

  write_geojson(built$geometry, provinces, here::here(OUTPUT), DECIMALS)
  written <- sf::st_read(here::here(OUTPUT), quiet = TRUE)
  check_output_geometry(sf::st_geometry(written))
  summary <- summary_table(geometry, sf::st_geometry(written), provinces)
  print(summary, row.names = FALSE)
  change <- summary$area_output_km2 / summary$area_source_km2 - 1
  message(sprintf(
    "total: %.0f -> %.0f km2 (largest change %+.2f%%, %s); %d -> %d vertices",
    sum(summary$area_source_km2), sum(summary$area_output_km2),
    100 * change[which.max(abs(change))], summary$province[which.max(abs(change))],
    sum(summary$vertices_source), sum(summary$vertices_output)
  ))
  message(sprintf("wrote %s (%.0f KiB)", OUTPUT, file.size(here::here(OUTPUT)) / 1024))
}

if (sys.nframe() == 0L) main()
