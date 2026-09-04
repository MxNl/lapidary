test_that("lap_circular_mean_month wraps December and January", {
  expect_equal(lap_circular_mean_month(c(12, 1, 2)), 1, tolerance = 1e-6)
  expect_equal(lap_circular_mean_month(c(1, 1, 1)), 1, tolerance = 1e-6)
  expect_equal(lap_circular_mean_month(c(6, 6)), 6, tolerance = 1e-6)
  expect_equal(lap_circular_mean_month(c(11, 1)), 12, tolerance = 1e-6)
  expect_true(is.na(lap_circular_mean_month(c(NA, NA))))
})

test_that("lap_make_hex_grid covers and clips a region", {
  region <- sf::st_sf(geometry = sf::st_sfc(
    sf::st_polygon(list(rbind(
      c(4e6, 3e6), c(4.3e6, 3e6), c(4.3e6, 3.3e6), c(4e6, 3.3e6), c(4e6, 3e6)
    ))),
    crs = 3035
  ))
  grid <- lap_make_hex_grid(region, cellsize = 50000)
  expect_s3_class(grid, "sf")
  expect_true("hex_id" %in% names(grid))
  expect_equal(sf::st_crs(grid)$epsg, 25832L)
  expect_gt(nrow(grid), 5)
})

test_that("lap_aggregate_to_hex returns one row per hex and counts wells", {
  set.seed(1)
  region <- sf::st_sf(geometry = sf::st_sfc(
    sf::st_polygon(list(rbind(
      c(4e6, 3e6), c(4.4e6, 3e6), c(4.4e6, 3.4e6), c(4e6, 3.4e6), c(4e6, 3e6)
    ))),
    crs = 3035
  ))
  grid <- lap_make_hex_grid(region, cellsize = 60000)
  pts <- sf::st_sample(region, 60)
  wells <- sf::st_sf(
    well_id = paste0("w", seq_along(pts)),
    geometry = sf::st_transform(pts, 25832)
  )
  vals <- data.frame(well_id = wells$well_id, level = rnorm(nrow(wells), 10))

  hex <- lap_aggregate_to_hex(wells, values = vals, grid = grid)
  expect_equal(nrow(hex), nrow(grid))
  expect_equal(sum(hex$n_wells), nrow(wells))
  expect_true(all(is.na(hex$level[hex$n_wells == 0])))
  expect_true(all(!is.na(hex$level[hex$n_wells > 0])))
})

test_that("lap_aggregate_to_hex averages a `circular` month column on the circle", {
  set.seed(2)
  region <- sf::st_sf(geometry = sf::st_sfc(
    sf::st_polygon(list(rbind(
      c(4e6, 3e6), c(4.2e6, 3e6), c(4.2e6, 3.2e6), c(4e6, 3.2e6), c(4e6, 3e6)
    ))),
    crs = 3035
  ))
  grid <- lap_make_hex_grid(region, cellsize = 2e6, clip = FALSE)[1, ] # 1 hex
  pts <- sf::st_transform(sf::st_sample(sf::st_geometry(grid), 6), 25832)
  wells <- sf::st_sf(well_id = paste0("w", seq_along(pts)), geometry = pts)
  # months around the Dec/Jan wrap: naive mean ~ 8.3, circular mean ~ Dec/Jan
  vals <- data.frame(well_id = wells$well_id, min_month = c(12, 12, 1, 1, 12, 1))

  hex <- lap_aggregate_to_hex(wells, values = vals, grid = grid, circular = min_month)
  cm <- hex$min_month[hex$n_wells > 0]
  expect_length(cm, 1L)
  expect_true(cm > 11.5 || cm < 1.5) # circular mean sits at the Dec/Jan wrap
  # ... whereas the plain arithmetic mean of {12,12,1,1,12,1} lands mid-year
  expect_equal(mean(vals$min_month), 6.5)
})

test_that("lap_aggregate_to_hex `by` aggregates per hex x group, keeping factor type", {
  set.seed(3)
  region <- sf::st_sf(geometry = sf::st_sfc(
    sf::st_polygon(list(rbind(
      c(4e6, 3e6), c(4.4e6, 3e6), c(4.4e6, 3.4e6), c(4e6, 3.4e6), c(4e6, 3e6)
    ))),
    crs = 3035
  ))
  grid <- lap_make_hex_grid(region, cellsize = 60000)
  pts <- sf::st_transform(sf::st_sample(region, 40), 25832)
  wells <- sf::st_sf(well_id = paste0("w", seq_along(pts)), geometry = pts)
  vals <- data.frame(
    well_id = rep(wells$well_id, 2),
    period = factor(rep(c("early", "late"), each = nrow(wells)), c("early", "late"),
      ordered = TRUE
    ),
    level = rnorm(2 * nrow(wells), 10)
  )

  hex <- lap_aggregate_to_hex(wells, values = vals, cols = level, by = period, grid = grid)
  expect_s3_class(hex$period, "ordered")
  expect_identical(levels(hex$period), c("early", "late"))
  # complete = TRUE (default): every hex appears once per observed period,
  # empty hexes included - ready to facet by period with the full grid in
  # every panel.
  expect_equal(nrow(hex), nrow(grid) * 2L)
  expect_true(all(!is.na(hex$period)))
  expect_setequal(table(hex$hex_id), 2L)
  populated <- hex[hex$n_wells > 0, ]
  expect_equal(sum(populated$n_wells), 2L * nrow(wells))
  # a hex empty in a period keeps that period's label with NA values / n_wells = 0
  empty <- hex[hex$n_wells == 0, ]
  expect_true(all(!is.na(empty$period)))
  expect_true(all(is.na(empty$level)))

  # complete = FALSE: the old sparse shape - only observed hex x period
  # combinations, plus one NA-period row for a hex with wells in no period
  sparse <- lap_aggregate_to_hex(
    wells, values = vals, cols = level, by = period, grid = grid, complete = FALSE
  )
  expect_lte(nrow(sparse), nrow(hex))
  expect_equal(sum(sparse$n_wells), sum(hex$n_wells))
  never_populated <- setdiff(grid$hex_id, unique(populated$hex_id))
  expect_equal(sum(is.na(sparse$period)), length(never_populated))
})

test_that("lap_aggregate_to_hex is unchanged without `by`", {
  set.seed(4)
  region <- sf::st_sf(geometry = sf::st_sfc(
    sf::st_polygon(list(rbind(
      c(4e6, 3e6), c(4.3e6, 3e6), c(4.3e6, 3.3e6), c(4e6, 3.3e6), c(4e6, 3e6)
    ))),
    crs = 3035
  ))
  grid <- lap_make_hex_grid(region, cellsize = 60000)
  pts <- sf::st_transform(sf::st_sample(region, 30), 25832)
  wells <- sf::st_sf(well_id = paste0("w", seq_along(pts)), geometry = pts)
  vals <- data.frame(well_id = wells$well_id, level = rnorm(nrow(wells), 10))
  hex <- lap_aggregate_to_hex(wells, values = vals, grid = grid)
  expect_equal(nrow(hex), nrow(grid))
  expect_false("period" %in% names(hex))
})
