test_that("lap_ind_amplitude is max - min of the level", {
  df <- data.frame(
    well_id = "a", date = as.Date("2000-01-01") + 0:9,
    gwl = c(10, 12, 9, 15, 11, 8, 13, 14, 10, 9)
  )
  out <- lap_ind_amplitude(df)
  expect_named(out, "ind_amplitude")
  expect_equal(out$ind_amplitude, 15 - 8)
})

test_that("lap_ind_extreme_months finds the annual extreme months (circular)", {
  # min in December, max in June, two years -> circular means land there
  df <- do.call(rbind, lapply(2000:2002, function(y) {
    data.frame(
      well_id = "a",
      date = as.Date(sprintf("%d-%02d-15", y, 1:12)),
      gwl = c(5, 5, 5, 5, 5, 20, 5, 5, 5, 5, 5, 1)
    )
  }))
  out <- lap_ind_extreme_months(df)
  expect_equal(out$ind_min_month, 12, tolerance = 1e-6)
  expect_equal(out$ind_max_month, 6, tolerance = 1e-6)
})

test_that("lap_ind_trend recovers a known slope and NA-guards short series", {
  set.seed(1)
  weeks <- seq(as.Date("1991-01-07"), as.Date("2020-12-28"), by = "1 week")
  df <- data.frame(
    well_id = "a", date = weeks,
    gwl = 100 - 0.05 * as.numeric(weeks - weeks[1]) / 365.25 + rnorm(length(weeks), 0, 0.1)
  )
  out <- lap_ind_trend(df)
  expect_named(out, c("ind_trend_slope", "ind_trend_p_value", "ind_trend_significant"))
  expect_equal(out$ind_trend_slope, -0.05, tolerance = 0.02)
  expect_true(out$ind_trend_significant)

  short <- df[df$date < as.Date("1995-01-01"), ]
  expect_true(is.na(lap_ind_trend(short, min_years = 10)$ind_trend_slope))
})

test_that("lap_indicators binds one row per well with ind_ columns", {
  x <- new_gwl_ts(make_ts_fixture(1991:1995))
  ind <- lap_indicators(x, c(lap_ind_amplitude, lap_ind_extreme_months))
  expect_equal(nrow(ind), 2L)
  expect_setequal(ind$well_id, c("a", "b"))
  expect_true(all(startsWith(setdiff(names(ind), "well_id"), "ind_")))
})

test_that(".funs accepts functions, a single function, a list, string keys and 'all'", {
  x <- new_gwl_ts(make_ts_fixture())
  one <- lap_indicators(x, lap_ind_amplitude)
  many <- lap_indicators(x, list(lap_ind_amplitude))
  key <- lap_indicators(x, "amplitude")
  expect_equal(one, many)
  expect_equal(one, key)

  by_key <- lap_indicators(x, c("amplitude", "trend"))
  by_fun <- lap_indicators(x, c(lap_ind_amplitude, lap_ind_trend))
  expect_equal(by_key, by_fun)

  reg <- lap_indicator_registry()
  all <- lap_indicators(new_gwl_ts(make_ts_fixture(1991:2000)), "all")
  in_all_cols <- unlist(strsplit(reg$columns[reg$in_all], ", "))
  expect_setequal(setdiff(names(all), "well_id"), in_all_cols)
  # "drought" is a catalogue entry but not part of "all"
  expect_false("drought" %in% reg$key[reg$in_all])
})

test_that(".funs is required and unknown keys are rejected", {
  x <- new_gwl_ts(make_ts_fixture())
  expect_error(lap_indicators(x), "required")
  expect_error(lap_indicators(x, "nope"), "Unknown indicator key")
  expect_error(lap_indicators(x, 42), "keys or")
})

test_that("lap_indicator_registry lists one row per registered indicator", {
  reg <- lap_indicator_registry()
  expect_s3_class(reg, "tbl_df")
  expect_true(all(c("amplitude", "extreme_months", "trend", "drought") %in% reg$key))
  expect_gte(nrow(reg), 12L)
  expect_type(reg$needs_date, "logical")
  expect_type(reg$in_all, "logical")
  expect_true(all(nzchar(reg$columns)))
  expect_true(all(nzchar(reg$description)))
  expect_true("range" %in% names(reg))
  expect_true(all(nzchar(reg$range)))
  # every catalogued column is unique across indicators
  cols <- unlist(strsplit(reg$columns, ", "))
  expect_equal(anyDuplicated(cols), 0L)
})

test_that("the registry carries a theoretical range aligned with every column", {
  reg <- lap_indicator_registry()
  expect_equal(
    lengths(strsplit(reg$range, " | ", fixed = TRUE)),
    lengths(strsplit(reg$columns, ", "))
  )
  expect_identical(column_range("ind_trend_slope"), "(-Inf, Inf)")
  expect_identical(column_range("ind_seasonality_strength"), "[0, 1]")
  expect_identical(column_range("ind_trend_significant"), "{FALSE, TRUE}")
  expect_true(is.na(column_range("ind_step_year")))       # a year, no fixed range
  expect_true(is.na(column_range("not_an_indicator")))
  expect_identical(column_range(c("ind_acf1", "bogus")), c("[-1, 1]", NA))
})

test_that("a date-needing indicator on a frame without a date column errors cleanly", {
  df <- data.frame(well_id = c("a", "a"), gwl = c(1, 2))
  expect_error(lap_indicators(df, "extreme_months"), "date")
  expect_error(lap_ind_trend(df), "date")
})

test_that("lap_add_indicators left-joins onto an existing table (and keeps sf)", {
  x <- new_gwl_ts(make_ts_fixture(1991:1995))
  base <- lap_summarise_wells(x, by = well_id)
  out <- base |>
    lap_add_indicators(x, "amplitude") |>
    lap_add_indicators(x, lap_ind_trend)
  expect_true(all(c("ind_amplitude", "ind_trend_slope") %in% names(out)))
  expect_equal(nrow(out), nrow(base))
  expect_error(lap_add_indicators(base, x), "required")

  wells <- sf::st_as_sf(
    data.frame(well_id = c("a", "b"), x = c(9, 10), y = c(50, 51)),
    coords = c("x", "y"), crs = 4326
  )
  wsf <- lap_add_indicators(wells, x, "all")
  expect_s3_class(wsf, "sf")
  expect_true("ind_amplitude" %in% names(wsf))
})

# --- new catalogue entries ------------------------------------------------

# a well-behaved synthetic weekly series: seasonal sine + linear trend + noise
synth_series <- function(years = 1991:2020, slope_per_yr = 0, amp = 1,
                         seed = 1, noise = 0.03) {
  set.seed(seed)
  wk <- seq(as.Date(paste0(min(years), "-01-07")),
            as.Date(paste0(max(years), "-12-28")), by = "1 week")
  t_yr <- as.numeric(wk - wk[1]) / 365.25
  data.frame(
    well_id = "a", date = wk,
    gwl = 50 + slope_per_yr * t_yr +
      amp * sin(2 * pi * (t_yr - 0.25)) + rnorm(length(wk), 0, noise)
  )
}

test_that("lap_ind_seasonal_amplitude ~ 2 * sine amplitude", {
  out <- lap_ind_seasonal_amplitude(synth_series(amp = 1.5))
  expect_equal(out$ind_seasonal_amplitude, 3, tolerance = 0.15)
})

test_that("lap_ind_seasonality_strength: ~1 for a pure cycle, low for noise", {
  strong <- lap_ind_seasonality_strength(synth_series(amp = 2, noise = 0.02))
  flat <- lap_ind_seasonality_strength(synth_series(amp = 0, noise = 1))
  expect_gt(strong$ind_seasonality_strength, 0.9)
  expect_lt(flat$ind_seasonality_strength, 0.3)
})

test_that("lap_ind_recharge_discharge sums to 12 and points the right way", {
  out <- lap_ind_recharge_discharge(synth_series(amp = 1))
  expect_equal(out$ind_recharge_months + out$ind_discharge_months, 12)
  expect_gte(out$ind_recharge_months, 1)
})

test_that("lap_ind_phase_regularity: ~0 for a metronomic cycle", {
  out <- lap_ind_phase_regularity(synth_series(amp = 2, noise = 0.01))
  expect_lt(out$ind_min_month_sd, 1)
})

test_that("lap_ind_flashiness > 1 and larger for noisier series", {
  smooth <- lap_ind_flashiness(synth_series(amp = 1, noise = 0.01))
  jumpy <- lap_ind_flashiness(synth_series(amp = 1, noise = 0.5))
  expect_gt(smooth$ind_flashiness, 1)
  expect_gt(jumpy$ind_flashiness, smooth$ind_flashiness)
})

test_that("lap_ind_memory: acf1 high for a persistent (AR) series, low for white noise", {
  set.seed(9)
  wk <- seq(as.Date("1995-01-07"), as.Date("2020-12-28"), by = "1 week")
  ar <- as.numeric(stats::filter(rnorm(length(wk)), 0.95, method = "recursive"))
  persistent <- lap_ind_memory(data.frame(well_id = "a", date = wk, gwl = 50 + ar))
  white <- lap_ind_memory(data.frame(well_id = "a", date = wk, gwl = 50 + rnorm(length(wk))))
  expect_gt(persistent$ind_acf1, 0.7)
  expect_gt(persistent$ind_memory_weeks, white$ind_memory_weeks)
})

test_that("lap_ind_trend_extremes recovers the imposed slope", {
  out <- lap_ind_trend_extremes(synth_series(slope_per_yr = -0.1, amp = 0.5))
  expect_equal(out$ind_trend_min_slope, -0.1, tolerance = 0.03)
  expect_equal(out$ind_trend_max_slope, -0.1, tolerance = 0.03)
})

test_that("lap_ind_step_change finds an injected step", {
  s <- synth_series(amp = 0.2, noise = 0.05)
  s$gwl[s$date >= as.Date("2008-01-01")] <- s$gwl[s$date >= as.Date("2008-01-01")] - 3
  out <- lap_ind_step_change(s)
  expect_equal(out$ind_step_year, 2007, tolerance = 1)
  expect_lt(out$ind_step_magnitude, -2)
  expect_lt(out$ind_step_p_value, 0.05)
})

test_that("lap_ind_trend_acceleration is negative for a steepening decline", {
  wk <- seq(as.Date("1991-01-07"), as.Date("2022-12-28"), by = "1 week")
  t <- as.numeric(wk - wk[1]) / 365.25
  s <- data.frame(well_id = "a", date = wk, gwl = 50 - 0.01 * t^2)
  out <- lap_ind_trend_acceleration(s)
  expect_lt(out$ind_trend_accel, 0)
})

test_that("lap_ind_drought counts runs below the threshold on a standardised index", {
  set.seed(3)
  wk <- seq(as.Date("2000-01-07"), as.Date("2019-12-28"), by = "1 week")
  idx <- rnorm(length(wk))
  idx[200:299] <- idx[200:299] - 5 # a 100-week dry spell, well below threshold
  s <- data.frame(well_id = "a", date = wk, gwl_norm = idx)
  out <- lap_ind_drought(s, value = gwl_norm)
  expect_gt(out$ind_drought_max_weeks, 90)
  expect_equal(out$ind_frac_below_normal, 0.5, tolerance = 0.1)
  expect_lt(out$ind_index_min, -4)
})

test_that("lap_ind_drought run-theory columns describe an injected event", {
  set.seed(11)
  wk <- seq(as.Date("2000-01-07"), as.Date("2015-12-28"), by = "1 week")
  idx <- rnorm(length(wk), 0, 0.3) # too small to cross the -1 threshold on its own
  idx[100:159] <- -3 # one clean 60-week event, severity ~ 60 * 3
  s <- data.frame(well_id = "a", date = wk, gwl_norm = idx)
  out <- lap_ind_drought(s, value = gwl_norm)
  expect_equal(out$ind_drought_n_events, 1)
  expect_equal(out$ind_drought_max_weeks, 60)
  expect_equal(out$ind_drought_duration_weeks, 60)
  expect_equal(out$ind_drought_severity, 180, tolerance = 0.02)
  expect_equal(out$ind_drought_intensity, 3, tolerance = 0.02)
})

test_that("lap_ind_drought_recovery: finite recovery, and counts an unrecovered tail", {
  wk <- seq(as.Date("2000-01-07"), as.Date("2015-12-28"), by = "1 week")
  idx <- rep(0.2, length(wk))
  idx[100:159] <- -2 # recovers (back to >= 0 afterwards)
  idx[(length(wk) - 40):length(wk)] <- -2 # never recovers within the slice
  s <- data.frame(well_id = "a", date = wk, gwl_norm = idx)
  out <- lap_ind_drought_recovery(s, value = gwl_norm)
  expect_true(is.finite(out$ind_drought_recovery_weeks))
  expect_gte(out$ind_drought_n_unrecovered, 1)
})

test_that("lap_ind_recession recovers the e-folding time of an exponential decay", {
  wk <- seq(as.Date("2001-01-07"), as.Date("2016-12-28"), by = "1 week")
  tau <- 12 # weeks
  # cycles of 40 weeks: a 2-week recharge ramp, then a 38-week exponential recession
  ph <- (seq_along(wk) - 1L) %% 40L
  v <- ifelse(ph < 2L, 10 + 2.5 * (ph + 1), 10 + 5 * exp(-(ph - 1L) / tau))
  s <- data.frame(well_id = "a", date = wk, gwl = v)
  out <- lap_ind_recession(s)
  expect_gt(out$ind_recession_n_segments, 3)
  expect_equal(out$ind_recession_weeks, tau, tolerance = 1)
})

test_that("lap_ind_climate_signal recovers a known lag and residual trend", {
  set.seed(5)
  mo <- seq(as.Date("1985-01-01"), as.Date("2020-12-01"), by = "month")
  n <- length(mo)
  driver <- rnorm(n) # monthly standardised-ish forcing
  lag <- 3L
  # SGI = lagged driver + a small imposed linear (anthropogenic) decline + noise
  sgi <- c(rep(0, lag), driver[seq_len(n - lag)]) -
    0.02 * (seq_len(n) / 12) + rnorm(n, 0, 0.2)
  sgi <- (sgi - mean(sgi)) / sd(sgi)
  s <- data.frame(well_id = "a", date = mo, gwl_norm = sgi, precip = driver)
  out <- lap_ind_climate_signal(s, value = gwl_norm, driver = precip, max_acc = 6L)
  expect_equal(out$ind_climate_lag_months, lag, tolerance = 1)
  expect_gt(out$ind_climate_cc, 0.5)
  expect_lt(out$ind_residual_trend_slope, 0)
})

test_that("lap_indicator_registry carries a reference column for every entry", {
  reg <- lap_indicator_registry()
  expect_true("reference" %in% names(reg))
  expect_equal(nrow(reg), 17L)
  expect_true(all(nzchar(reg$reference)))
  expect_true(all(c("drought_recovery", "climate_signal", "recession") %in% reg$key))
})
