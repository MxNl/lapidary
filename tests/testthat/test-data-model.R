test_that("new_gwl_ts builds and validates a canonical table", {
  df <- make_ts_fixture()
  x <- new_gwl_ts(df)
  expect_s3_class(x, "gwl_ts")
  expect_true(all(c("well_id", "date", "gwl", "variable", "source") %in% names(x)))
  expect_s3_class(x$date, "Date")
  expect_type(x$well_id, "character")
  expect_identical(validate_gwl_ts(x), x)
})

test_that("check_gwl_ts reports each failure mode", {
  good <- new_gwl_ts(make_ts_fixture())

  expect_error(check_gwl_ts(good[, c("well_id", "date")]), "missing required column")

  bad_type <- good
  bad_type$gwl <- as.character(bad_type$gwl)
  expect_error(check_gwl_ts(bad_type), "gwl must be numeric")

  bad_date <- as.data.frame(good)
  bad_date$date <- format(bad_date$date)
  expect_error(check_gwl_ts(bad_date), "date must be Date")

  expect_error(check_gwl_ts(1:10), "must be a data frame")
})

test_that("gwl_flag is coerced to a validated factor", {
  df <- make_ts_fixture()
  df$gwl_flag <- rep(c("observed", "imputed"), length.out = nrow(df))
  x <- new_gwl_ts(df)
  expect_s3_class(x$gwl_flag, "factor")

  df$gwl_flag <- "nonsense"
  expect_error(new_gwl_ts(df), "observed")
})

test_that("as_tibble drops the gwl_ts class", {
  x <- new_gwl_ts(make_ts_fixture())
  tb <- tibble::as_tibble(x)
  expect_false(inherits(tb, "gwl_ts"))
})

test_that("new_gwl_wells lands in EPSG:25832 and checks geometry", {
  pts <- data.frame(well_id = c("a", "b"), x = c(9, 10), y = c(50, 51))
  w <- new_gwl_wells(pts, coords = c("x", "y"), crs = 4326)
  expect_s3_class(w, "gwl_wells")
  expect_equal(sf::st_crs(w)$epsg, 25832L)
  expect_invisible(check_gwl_wells(w))

  poly <- sf::st_sf(well_id = "a", geometry = sf::st_sfc(
    sf::st_polygon(list(rbind(c(0, 0), c(1, 0), c(1, 1), c(0, 0)))),
    crs = 25832
  ))
  expect_error(check_gwl_wells(poly), "POINT")
})
