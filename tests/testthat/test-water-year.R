test_that("lap_use_water_year assigns the November-start hydrological year", {
  df <- data.frame(date = as.Date(c(
    "2019-10-15", "2019-11-15", "2019-12-31", "2020-01-15", "2020-10-31"
  )))
  out <- lap_use_water_year(df)
  expect_equal(out$water_year, c(2019, 2020, 2020, 2020, 2020))
  expect_equal(out$water_month, c(12, 1, 2, 3, 12))
})

test_that("start_month = 1 makes water year equal calendar year", {
  df <- data.frame(date = as.Date(c("2020-01-01", "2020-12-31")))
  out <- lap_use_water_year(df, start_month = 1)
  expect_equal(out$water_year, c(2020, 2020))
  expect_equal(out$water_month, c(1, 12))
})

test_that("bad inputs error", {
  expect_error(lap_use_water_year(data.frame(x = 1)), "date")
  expect_error(lap_use_water_year(data.frame(date = Sys.Date()), start_month = 13), "1:12")
})

test_that("date_col accepts a bare name or a string", {
  df <- data.frame(measured_on = as.Date(c("2020-01-15", "2020-11-15")))
  expect_identical(
    lap_use_water_year(df, date_col = measured_on),
    lap_use_water_year(df, date_col = "measured_on")
  )
})
