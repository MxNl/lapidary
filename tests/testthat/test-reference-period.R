test_that("lap_add_reference_period tags years and can drop", {
  df <- data.frame(date = as.Date(paste0(1985:1995, "-06-15")))
  out <- lap_add_reference_period(df, periods = lap_reference_periods()[c("Z0", "Z1")])
  expect_s3_class(out$reference_period, "factor")
  expect_identical(levels(out$reference_period), c("Z0", "Z1"))
  expect_equal(as.character(out$reference_period[df$date < as.Date("1991-01-01")][1]), "Z0")
  expect_equal(sum(is.na(out$reference_period)), 0L)

  dropped <- lap_add_reference_period(df, periods = list(Z1 = c(1991, 1993)), drop = TRUE)
  expect_equal(nrow(dropped), 3L)
})

test_that("overlapping reference periods are rejected", {
  expect_error(
    lap_add_reference_period(
      data.frame(date = Sys.Date()),
      periods = list(A = c(1990, 2000), B = c(1999, 2010))
    ),
    "overlap"
  )
})

test_that("year_col is used when supplied", {
  df <- data.frame(year = c(1990L, 2000L))
  out <- lap_add_reference_period(df, periods = list(Z1 = c(1991, 2020)), year_col = "year")
  expect_equal(as.character(out$reference_period), c(NA, "Z1"))
})
