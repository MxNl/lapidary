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
