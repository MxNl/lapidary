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

test_that('lap_indicator_change resolves "all" once, for every period alike', {
  x <- lap_normalise_gwl(new_gwl_ts(make_two_period_ts()), "sgi")
  periods <- list(reference = c(1991, 2010), recent = c(2011, 2022))
  # resolved against the whole series, so the message is emitted a single time
  expect_message(
    chg <- suppressWarnings(lap_indicator_change(x, "all", periods = periods)),
    "also ran"
  )
  expect_true(all(c("ind_drought_severity", "ind_drought_recovery_weeks") %in% names(chg)))
  expect_equal(nrow(chg), 4L)
  # both periods are present, carrying the same (single) set of columns
  expect_setequal(as.character(chg$period), c("reference", "recent"))
  reg <- lap_indicator_registry()
  expect_setequal(
    grep("^ind_", names(chg), value = TRUE),
    unlist(strsplit(reg$columns[reg$key != "climate_signal"], ", "))
  )
})

test_that("a window far from zero is a drought, not an unusable series", {
  # well "a" declines steeply after 2010, so its SGI over the recent window
  # sits well below zero. That is a drought - the whole point of the metric -
  # and must not be mistaken for "this column is not a standardised index".
  x <- lap_normalise_gwl(new_gwl_ts(make_two_period_ts()), "sgi")
  periods <- list(reference = c(1991, 2010), recent = c(2011, 2022))
  expect_no_warning(
    chg <- suppressMessages(lap_indicator_change(x, "all", periods = periods))
  )
  expect_true(all(is.finite(chg$ind_drought_frequency)))
  # the declining well is drier in the recent window than in the reference one
  a <- chg[chg$well_id == "a", ]
  expect_gt(
    a$ind_drought_frequency[a$period == "recent"],
    a$ind_drought_frequency[a$period == "reference"]
  )
  # the index really was off-centre there - the old check would have rejected it
  sgi <- x$gwl_norm[x$well_id == "a" & format(as.Date(x$date), "%Y") >= "2011"]
  expect_false(is_standardised(sgi))
})

test_that("requesting drought by key still checks, unless check = FALSE", {
  x <- lap_normalise_gwl(new_gwl_ts(make_two_period_ts()), "sgi")
  recent <- x[format(as.Date(x$date), "%Y") >= "2011" & x$well_id == "a", ]
  expect_error(
    lap_indicators(recent, "drought", value = gwl_norm),
    "standardised index"
  )
  ind <- lap_indicators(recent, "drought", value = gwl_norm, check = FALSE)
  expect_true(is.finite(ind$ind_drought_frequency))
})
