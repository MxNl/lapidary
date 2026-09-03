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

# --- lap_period_windows -------------------------------------------------

test_that("lap_period_windows: first_vs_last_decade honours width and range", {
  df <- data.frame(date = as.Date(paste0(1991:2022, "-06-15")))
  w <- lap_period_windows(df, "first_vs_last_decade")
  expect_identical(w$first, c(1991L, 2000L))
  expect_identical(w$last, c(2013L, 2022L))
  expect_identical(
    lap_period_windows(df, "first_vs_last_decade", width = 5)$last,
    c(2018L, 2022L)
  )
})

test_that("lap_period_windows: first_vs_last_half splits at the midpoint", {
  w <- lap_period_windows(c(1991, 2022), "first_vs_last_half")
  expect_identical(w$first, c(1991L, 2006L))
  expect_identical(w$last, c(2007L, 2022L))
})

test_that("lap_period_windows: decade_per_decade is record-aligned and clipped", {
  w <- lap_period_windows(c(1991, 2022), "decade_per_decade")
  expect_identical(
    names(w), c("1991-2000", "2001-2010", "2011-2020", "2021-2022")
  )
  expect_identical(w[["1991-2000"]], c(1991L, 2000L))
  expect_identical(w[["2021-2022"]], c(2021L, 2022L))
  # aligned to the first year, not the calendar decade
  expect_identical(lap_period_windows(c(1987, 2020), "decade_per_decade")[[1]], c(1987L, 1996L))
})

test_that("lap_period_windows accepts a 2-vector and rejects junk", {
  expect_type(lap_period_windows(c(2000, 2019), "first_vs_last_half"), "list")
  expect_error(lap_period_windows(c(2019, 2000), "first_vs_last_half"), "first <= last")
  expect_error(
    lap_period_windows(data.frame(date = as.Date(NA)), "first_vs_last_half"),
    "no non-missing years"
  )
  expect_error(lap_period_windows(c(2000, 2019), "nope"))
})

test_that("lap_period_windows messages when first/last decades overlap", {
  expect_message(
    lap_period_windows(c(2015, 2022), "first_vs_last_decade"), "overlap"
  )
})

test_that("lap_period_windows output feeds lap_indicator_change", {
  data(gems_ger_sample, package = "lapidary", envir = environment())
  w <- lap_period_windows(gems_ger_sample, "decade_per_decade")
  chg <- lap_indicator_change(gems_ger_sample, "amplitude", periods = w)
  expect_identical(levels(chg$period), names(w))
})
