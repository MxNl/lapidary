make_two_period_ts <- function() {
  wk <- seq(as.Date("1991-01-07"), as.Date("2022-12-28"), by = "1 week")
  t <- as.numeric(wk - wk[1]) / 365.25
  # well "a": stronger decline after 2010; well "b": flat
  do.call(rbind, list(
    data.frame(well_id = "a", date = wk,
      gwl = 50 - ifelse(t < 20, 0.02 * t, 0.4 + 0.15 * (t - 20)) +
        sin(2 * pi * t)),
    data.frame(well_id = "b", date = wk, gwl = 30 + sin(2 * pi * t))
  ))
}

test_that("lap_indicator_change stacks per period with an ordered factor", {
  x <- make_two_period_ts()
  chg <- lap_indicator_change(
    x, c("amplitude", "trend"),
    periods = list(full = c(1991, 2022), reference = c(1991, 2010), recent = c(2011, 2022))
  )
  expect_equal(nrow(chg), 6L) # 2 wells x 3 periods
  expect_s3_class(chg$period, "ordered")
  expect_identical(levels(chg$period), c("full", "reference", "recent"))
  expect_true("period" %in% names(chg))
  expect_true(all(c("well_id", "period") == names(chg)[1:2]))
})

test_that("lap_indicator_change allows overlapping periods", {
  x <- make_two_period_ts()
  expect_no_error(
    lap_indicator_change(x, "amplitude",
      periods = list(a = c(1991, 2022), b = c(2010, 2022))
    )
  )
})

test_that("lap_indicator_delta: one row per well, catalog-aware change columns", {
  x <- make_two_period_ts()
  chg <- lap_indicator_change(
    x, c("amplitude", "extreme_months", "trend"),
    periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
  )
  d <- lap_indicator_delta(chg, "reference", "recent")

  expect_equal(nrow(d), 2L)
  expect_true(all(c(
    "ind_amplitude_reference", "ind_amplitude_recent", "ind_amplitude_change"
  ) %in% names(d)))
  # circular month columns get a wrapped change in (-6, 6]
  expect_true("ind_min_month_change" %in% names(d))
  expect_true(all(d$ind_min_month_change > -6 & d$ind_min_month_change <= 6))
  # "none" columns (p-value, significance) get no _change column
  expect_false("ind_trend_p_value_change" %in% names(d))
  expect_false("ind_trend_significant_change" %in% names(d))
  # the steepening decline in well "a" shows up as a more negative recent slope
  a <- d[d$well_id == "a", ]
  expect_lt(a$ind_trend_slope_change, 0)
})

test_that("lap_indicator_delta errors on a bad period label / missing period col", {
  x <- make_two_period_ts()
  chg <- lap_indicator_change(x, "amplitude",
    periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
  )
  expect_error(lap_indicator_delta(chg, "reference", "nope"), "not in")
  expect_error(lap_indicator_delta(x, "a", "b"), "period")
})
