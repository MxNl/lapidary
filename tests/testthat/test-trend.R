test_that("lap_gw_trend recovers a known slope and direction", {
  set.seed(1)
  years <- 1991:2020
  df <- rbind(
    data.frame(well_id = "down", year = years, mean_gwl = 50 - 0.1 * (years - 1991) + rnorm(30, 0, 0.05)),
    data.frame(well_id = "flat", year = years, mean_gwl = 20 + rnorm(30, 0, 0.05))
  )
  tr <- lap_gw_trend(df)
  down <- tr[tr$well_id == "down", ]
  flat <- tr[tr$well_id == "flat", ]

  expect_equal(down$slope, -0.1, tolerance = 0.02)
  expect_lt(down$p_value, 0.001)
  expect_true(down$significant)
  expect_equal(down$direction, "decreasing")

  expect_gt(flat$p_value, 0.05)
  expect_false(flat$significant)
})

test_that("slope confidence interval brackets the estimate", {
  set.seed(2)
  years <- 1991:2020
  df <- data.frame(well_id = "a", year = years, mean_gwl = 10 + 0.05 * (years - 1991) + rnorm(30, 0, 0.1))
  tr <- lap_gw_trend(df)
  expect_lt(tr$slope_lower, tr$slope)
  expect_gt(tr$slope_upper, tr$slope)
})

test_that("short series yields NA row", {
  df <- data.frame(well_id = "a", year = 1991:1995, mean_gwl = 1:5)
  tr <- lap_gw_trend(df, min_n = 10)
  expect_true(is.na(tr$slope))
  expect_equal(tr$n, NA_integer_)
})

test_that("Date time column is accepted", {
  d <- seq(as.Date("1991-01-01"), as.Date("2020-01-01"), by = "1 year")
  df <- data.frame(well_id = "a", t = d, v = seq_along(d) * -0.2 + 100)
  tr <- lap_gw_trend(df, value = "v", time = "t")
  expect_equal(tr$slope, -0.2, tolerance = 0.01)
})
