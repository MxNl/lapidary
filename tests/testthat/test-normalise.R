test_that("range normalisation lands in [0, 1] per well", {
  x <- new_gwl_ts(make_ts_fixture())
  out <- lap_normalise_gwl(x, "range")
  by_well <- split(out$gwl_norm, out$well_id)
  expect_true(all(vapply(by_well, min, 0) >= -1e-9))
  expect_true(all(vapply(by_well, max, 0) <= 1 + 1e-9))
})

test_that("zscore normalisation is per-well standardised", {
  x <- new_gwl_ts(make_ts_fixture())
  out <- lap_normalise_gwl(x, "zscore")
  by_well <- split(out$gwl_norm, out$well_id)
  expect_equal(unname(vapply(by_well, mean, 0)), c(0, 0), tolerance = 1e-8)
  expect_equal(unname(vapply(by_well, stats::sd, 0)), c(1, 1), tolerance = 1e-8)
})

test_that("sgi is deseasonalised and approximately standard normal", {
  x <- new_gwl_ts(make_ts_fixture(1991:2000))
  out <- lap_normalise_gwl(x, "sgi")
  expect_equal(mean(out$gwl_norm), 0, tolerance = 0.05)
  expect_gt(stats::sd(out$gwl_norm), 0.8)
  # within a calendar month, mean is ~ 0
  m <- as.integer(format(out$date, "%m"))
  month_means <- tapply(out$gwl_norm, list(out$well_id, m), mean)
  expect_true(all(abs(month_means) < 0.15))
})

test_that("sgi requires a date column", {
  df <- data.frame(well_id = "a", gwl = 1:10)
  expect_error(lap_normalise_gwl(df, "sgi"), "date")
})
