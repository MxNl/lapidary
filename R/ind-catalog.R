# Indicator catalogue -----------------------------------------------------
#
# Each `lap_ind_<name>()` is a pure function of a one-series slice: it returns a
# one-row tibble with `ind_`-prefixed columns and NA-guards short / empty input.
# `value` / `date` are tidy-select (a bare name, a string, or a name held in a
# variable - which is how `lap_indicators()` forwards them). Register a new one
# in `indicator_catalog()` (R/indicators.R).

# Resolve `value` / `date` and return the cleaned, date-sorted series plus the
# calendar year / month of each point. `date = NULL` -> rows kept in input order,
# `yr` / `mo` are NULL.
ind_series <- function(data, value, date = NULL) {
  v <- data[[value]]
  dd <- if (!is.null(date) && !is.na(date) && date %in% names(data)) {
    as.Date(data[[date]])
  } else {
    NULL
  }
  keep <- !is.na(v)
  if (!is.null(dd)) keep <- keep & !is.na(dd)
  v <- v[keep]
  if (!is.null(dd)) {
    dd <- dd[keep]
    o <- order(dd)
    v <- v[o]
    dd <- dd[o]
  }
  list(
    v = v, dd = dd,
    yr = if (is.null(dd)) NULL else as.integer(format(dd, "%Y")),
    mo = if (is.null(dd)) NULL else as.integer(format(dd, "%m"))
  )
}

# Theil-Sen slope only (NA if too few points). Wraps the shared estimator.
sen_slope <- function(t, y, min_n = 10L) {
  ok <- is.finite(t) & is.finite(y)
  t <- t[ok]
  y <- y[ok]
  if (length(y) < min_n) {
    return(NA_real_)
  }
  o <- order(t)
  theil_sen_mann_kendall(t[o], y[o])$slope
}

# Seasonality strength (feasts convention) via base STL on a monthly aggregate.
stl_strength <- function(v, dd) {
  if (is.null(dd) || length(v) < 24) {
    return(NA_real_)
  }
  ym <- format(dd, "%Y-%m")
  monthly <- tapply(v, ym, mean, na.rm = TRUE)
  grid <- format(
    seq(as.Date(paste0(min(ym), "-01")), as.Date(paste0(max(ym), "-01")), by = "month"),
    "%Y-%m"
  )
  m <- as.numeric(monthly[grid])
  if (sum(!is.na(m)) < 24) {
    return(NA_real_)
  }
  if (anyNA(m)) {
    m <- stats::approx(seq_along(m), m, seq_along(m), rule = 2)$y
  }
  fit <- tryCatch(
    stats::stl(stats::ts(m, frequency = 12), s.window = "periodic", robust = TRUE),
    error = function(e) NULL
  )
  if (is.null(fit)) {
    return(NA_real_)
  }
  comp <- fit$time.series
  denom <- stats::var(comp[, "seasonal"] + comp[, "remainder"])
  if (!is.finite(denom) || denom == 0) {
    return(NA_real_)
  }
  max(0, 1 - stats::var(comp[, "remainder"]) / denom)
}

# Pettitt change-point on a numeric series `y` observed at times `t`.
pettitt_change_point <- function(t, y) {
  n <- length(y)
  out <- list(year = NA_real_, magnitude = NA_real_, p_value = NA_real_)
  if (n < 10) {
    return(out)
  }
  u <- cumsum(vapply(y, function(yi) sum(sign(yi - y)), numeric(1)))
  k <- which.max(abs(u))
  kk <- abs(u[k])
  list(
    year = t[k],
    magnitude = mean(y[(k + 1):n]) - mean(y[1:k]),
    p_value = min(1, 2 * exp(-6 * kk^2 / (n^3 + n^2)))
  )
}

# Longest run of TRUE.
run_length_max <- function(x) {
  if (!any(x, na.rm = TRUE)) {
    return(0L)
  }
  r <- rle(as.logical(x))
  max(r$lengths[!is.na(r$values) & r$values])
}

# Abort unless `x` looks like an approximately standard-normal index (SGI etc.).
check_standardised <- function(x, value, call = rlang::caller_env()) {
  sdv <- stats::sd(x, na.rm = TRUE)
  if (abs(stats::median(x, na.rm = TRUE)) > 0.75 || !is.finite(sdv) ||
    sdv < 0.4 || sdv > 2.5) {
    cli::cli_abort(c(
      "{.arg value} ({.field {value}}) does not look like a standardised index.",
      i = 'Add one first: {.code lap_normalise_gwl("sgi")}, then {.code value = gwl_norm}.'
    ), call = call)
  }
  invisible(TRUE)
}

# Run theory (Yevjevich 1967) on a standardised index `x`: one row per maximal
# run of `x < threshold`. `severity` is the cumulative deficit (sum of -x over
# the run); `recovery` is the number of steps from the run's minimum forward to
# the first `x >= 0` (NA if the series ends first).
drought_runs <- function(x, threshold = -1) {
  below <- !is.na(x) & x < threshold
  r <- rle(below)
  ends <- cumsum(r$lengths)
  starts <- ends - r$lengths + 1L
  ev <- which(r$values)
  if (!length(ev)) {
    return(data.frame(
      start = integer(), end = integer(), len = integer(),
      severity = numeric(), i_min = integer(),
      recovery = numeric(), recovered = logical()
    ))
  }
  do.call(rbind, lapply(ev, function(k) {
    ix <- starts[k]:ends[k]
    i_min <- ix[which.min(x[ix])]
    fwd <- which(!is.na(x[i_min:length(x)]) & x[i_min:length(x)] >= 0)
    data.frame(
      start = starts[k], end = ends[k], len = length(ix),
      severity = sum(-x[ix]), i_min = i_min,
      recovery = if (length(fwd)) fwd[[1]] - 1L else NA_real_,
      recovered = length(fwd) > 0
    )
  }))
}

# Segments of sustained recession (falling/flat), each >= `min_len` steps, single
# up-steps tolerated. Returns start/end index pairs.
recession_segments <- function(v, min_len = 8L, up_tol = 1L) {
  n <- length(v)
  if (n < min_len + 1L) {
    return(list())
  }
  rising <- c(FALSE, diff(v) > 0)
  # a segment breaks only after `up_tol` consecutive up-steps
  up_run <- 0L
  seg_id <- integer(n)
  cur <- 1L
  for (i in seq_len(n)) {
    if (rising[i]) {
      up_run <- up_run + 1L
      if (up_run > up_tol) {
        cur <- cur + 1L
        up_run <- 0L
      }
    } else {
      up_run <- 0L
    }
    seg_id[i] <- cur
  }
  segs <- split(seq_len(n), seg_id)
  segs <- segs[vapply(segs, function(ix) {
    length(ix) >= min_len && v[ix[1]] - v[ix[length(ix)]] > 0
  }, logical(1))]
  unname(segs)
}

# Master-recession e-folding time (weeks) from `recession_segments`: per segment
# fit log(v - asymptote) ~ step; e-folding = -1 / slope for a decaying fit.
recession_efold <- function(v, min_len = 8L) {
  segs <- recession_segments(v, min_len = min_len)
  taus <- vapply(segs, function(ix) {
    y <- v[ix]
    asym <- min(y) - 0.01 * (max(y) - min(y)) - 1e-9
    fit <- stats::lm(log(y - asym) ~ seq_along(y))
    b <- stats::coef(fit)[[2]]
    if (is.finite(b) && b < 0) -1 / b else NA_real_
  }, numeric(1))
  taus <- taus[is.finite(taus)]
  list(tau = if (length(taus)) stats::median(taus) else NA_real_, n = length(taus))
}

# Aggregate a daily/weekly series to a regular monthly series (mean per calendar
# month), returning the values and their month-of-year.
to_monthly <- function(v, dd) {
  ym <- format(dd, "%Y-%m")
  m <- tapply(v, ym, mean, na.rm = TRUE)
  grid <- format(
    seq(as.Date(paste0(min(ym), "-01")), as.Date(paste0(max(ym), "-01")), by = "month"),
    "%Y-%m"
  )
  vals <- as.numeric(m[grid])
  list(v = vals, mo = as.integer(substr(grid, 6, 7)), ym = grid)
}

# Cross-correlation search of SGI (monthly) against an accumulated, standardised
# climate driver. Returns the accumulation / lag of maximum positive correlation
# plus the aligned SPI-analog series and the SGI series.
climate_coupling <- function(sgi_v, drv_v, dd, max_acc = 48L, max_lag = 24L) {
  sm <- to_monthly(sgi_v, dd)
  dm <- to_monthly(drv_v, dd)
  n <- length(sm$v)
  na_out <- list(acc = NA_real_, lag = NA_real_, cc = NA_real_, spi = NULL, sgi = sm$v)
  if (n < 60L || all(is.na(dm$v))) {
    return(na_out)
  }
  best <- na_out
  for (acc in seq_len(min(max_acc, n - 1L))) {
    ad <- as.numeric(stats::filter(dm$v, rep(1 / acc, acc), sides = 1))
    spi <- ave_by(ad, factor(dm$mo), normal_scores)
    for (lag in 0:min(max_lag, n - 1L)) {
      a <- sm$v[(lag + 1L):n]
      b <- spi[1:(n - lag)]
      ok <- is.finite(a) & is.finite(b)
      if (sum(ok) < 36L) next
      cc <- suppressWarnings(stats::cor(a[ok], b[ok]))
      if (is.finite(cc) && (is.na(best$cc) || cc > best$cc)) {
        aligned <- rep(NA_real_, n)
        aligned[(lag + 1L):n] <- spi[1:(n - lag)]
        best <- list(acc = acc, lag = lag, cc = cc, spi = aligned, sgi = sm$v)
      }
    }
  }
  best
}


# --- A. Seasonality & phase ------------------------------------------------

#' Groundwater-level amplitude
#'
#' `ind_amplitude` = max - min of the level over the whole slice.
#'
#' @param data A one-series data frame.
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> level column.
#' @param date Unused; present for a uniform indicator signature.
#' @param ... Ignored; absorbs arguments forwarded to other indicators by
#'   [lap_indicators()].
#'
#' @return A one-row tibble: `ind_amplitude`.
#' @family indicators
#' @export
lap_ind_amplitude <- function(data, value = gwl, date = "date", ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  v <- data[[value]]
  tibble::tibble(
    ind_amplitude = if (all(is.na(v))) NA_real_ else diff(range(v, na.rm = TRUE))
  )
}

#' Mean within-year (seasonal) amplitude
#'
#' `ind_seasonal_amplitude` = the mean, over calendar years, of the annual
#' `max - min`. Unlike [lap_ind_amplitude()] this is not inflated by a long-term
#' trend.
#'
#' @inheritParams lap_ind_amplitude
#' @param date <[`tidy-select`][dplyr::dplyr_tidy_select]> date column.
#' @return A one-row tibble: `ind_seasonal_amplitude`.
#' @family indicators
#' @export
lap_ind_seasonal_amplitude <- function(data, value = gwl, date = "date", ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  s <- ind_series(data, value, date)
  if (length(s$v) < 12) {
    return(tibble::tibble(ind_seasonal_amplitude = NA_real_))
  }
  rng <- tapply(s$v, s$yr, function(z) diff(range(z, na.rm = TRUE)))
  rng <- rng[is.finite(rng)]
  tibble::tibble(
    ind_seasonal_amplitude = if (length(rng)) mean(rng) else NA_real_
  )
}

#' Strength of the seasonal cycle
#'
#' `ind_seasonality_strength` in `[0, 1]`: `max(0, 1 - var(remainder) /
#' var(seasonal + remainder))` from an STL decomposition ([stats::stl()]) of the
#' series aggregated to monthly means. 0 = no seasonal signal (typical of deep
#' confined systems), ~1 = the dynamics are almost purely seasonal.
#'
#' @inheritParams lap_ind_seasonal_amplitude
#' @return A one-row tibble: `ind_seasonality_strength`.
#' @family indicators
#' @export
lap_ind_seasonality_strength <- function(data, value = gwl, date = "date", ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  s <- ind_series(data, value, date)
  tibble::tibble(ind_seasonality_strength = stl_strength(s$v, s$dd))
}

#' Length of the annual recharge and discharge periods
#'
#' From the 12 climatological monthly means, `ind_recharge_months` is the number
#' of months from the annual trough to the annual peak (the mean rising limb)
#' and `ind_discharge_months = 12 - ind_recharge_months` (the falling limb). `NA`
#' for a series with no discernible annual cycle.
#'
#' @inheritParams lap_ind_seasonal_amplitude
#' @return A one-row tibble: `ind_recharge_months`, `ind_discharge_months`.
#' @family indicators
#' @export
lap_ind_recharge_discharge <- function(data, value = gwl, date = "date", ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  s <- ind_series(data, value, date)
  na_row <- tibble::tibble(ind_recharge_months = NA_real_, ind_discharge_months = NA_real_)
  if (length(s$v) < 24) {
    return(na_row)
  }
  clim <- tapply(s$v, s$mo, mean, na.rm = TRUE)
  if (length(clim) < 12 || diff(range(clim)) < 1e-8) {
    return(na_row)
  }
  clim <- clim[order(as.integer(names(clim)))]
  rech <- unname((which.max(clim) - which.min(clim)) %% 12)
  if (rech == 0) rech <- 12
  tibble::tibble(
    ind_recharge_months = as.numeric(rech),
    ind_discharge_months = 12 - as.numeric(rech)
  )
}

#' Year-to-year regularity of the seasonal timing
#'
#' `ind_min_month_sd` is the circular standard deviation (in months) of the
#' month in which each year's minimum level falls. Near 0 = a metronomic seasonal
#' cycle; large = event-driven / irregular timing.
#'
#' @inheritParams lap_ind_seasonal_amplitude
#' @return A one-row tibble: `ind_min_month_sd`.
#' @family indicators
#' @export
lap_ind_phase_regularity <- function(data, value = gwl, date = "date", ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  s <- ind_series(data, value, date)
  if (length(s$v) < 24) {
    return(tibble::tibble(ind_min_month_sd = NA_real_))
  }
  min_month <- tapply(seq_along(s$v), s$yr, function(ix) s$mo[ix][which.min(s$v[ix])])
  tibble::tibble(ind_min_month_sd = circular_month_sd(as.numeric(min_month)))
}


# --- B. Dynamics & aquifer signature -------------------------------------

#' Timing of the annual groundwater extremes
#'
#' For each calendar year the month of the annual minimum and of the annual
#' maximum level is found; `ind_min_month` / `ind_max_month` are the
#' [circular means][lap_circular_mean_month] of those months across years
#' (values in `(0.5, 12.5]`). They mark, roughly, the end of the discharge and
#' the end of the recharge period.
#'
#' @inheritParams lap_ind_seasonal_amplitude
#' @return A one-row tibble: `ind_min_month`, `ind_max_month`.
#' @family indicators
#' @export
lap_ind_extreme_months <- function(data, value = gwl, date = "date", ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  s <- ind_series(data, value, date)
  if (!length(s$v)) {
    return(tibble::tibble(ind_min_month = NA_real_, ind_max_month = NA_real_))
  }
  per_year <- lapply(split(seq_along(s$v), s$yr), function(ix) {
    c(min_m = s$mo[ix][which.min(s$v[ix])], max_m = s$mo[ix][which.max(s$v[ix])])
  })
  per_year <- do.call(rbind, per_year)
  tibble::tibble(
    ind_min_month = lap_circular_mean_month(per_year[, "min_m"]),
    ind_max_month = lap_circular_mean_month(per_year[, "max_m"])
  )
}

#' Flashiness of the hydrograph
#'
#' `ind_flashiness` = `sum(|diff(level)|) / (max - min)` - the total path length
#' the series travels, per unit of its overall span. High for flashy shallow
#' unconfined systems, low for smooth deep / confined ones.
#'
#' @inheritParams lap_ind_amplitude
#' @param date <[`tidy-select`][dplyr::dplyr_tidy_select]> optional date column
#'   (used only to order the series).
#' @return A one-row tibble: `ind_flashiness`.
#' @family indicators
#' @export
lap_ind_flashiness <- function(data, value = gwl, date = "date", ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date", null_ok = TRUE)
  s <- ind_series(data, value, date)
  span <- if (length(s$v) >= 3) diff(range(s$v)) else NA_real_
  tibble::tibble(
    ind_flashiness = if (isTRUE(span > 0)) sum(abs(diff(s$v))) / span else NA_real_
  )
}

#' Aquifer memory (persistence)
#'
#' On the month-deseasonalised series: `ind_acf1` is the lag-1 autocorrelation
#' and `ind_memory_weeks` is the first lag at which the autocorrelation drops
#' below `1/e`. Long memory (many weeks / months) indicates a deep or confined
#' system that integrates recharge slowly.
#'
#' @inheritParams lap_ind_seasonal_amplitude
#' @return A one-row tibble: `ind_acf1`, `ind_memory_weeks`.
#' @family indicators
#' @export
lap_ind_memory <- function(data, value = gwl, date = "date", ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  s <- ind_series(data, value, date)
  na_row <- tibble::tibble(ind_acf1 = NA_real_, ind_memory_weeks = NA_real_)
  if (length(s$v) < 52) {
    return(na_row)
  }
  clim <- tapply(s$v, s$mo, mean, na.rm = TRUE)
  ds <- s$v - as.numeric(clim[as.character(s$mo)])
  lag_max <- min(260L, length(ds) - 1L)
  a <- tryCatch(
    stats::acf(ds, lag.max = lag_max, plot = FALSE, demean = TRUE)$acf[, 1, 1],
    error = function(e) NULL
  )
  if (is.null(a)) {
    return(na_row)
  }
  below <- which(a[-1] < exp(-1))
  tibble::tibble(
    ind_acf1 = a[2],
    ind_memory_weeks = if (length(below)) below[[1]] else NA_real_
  )
}

#' Rising- vs falling-limb rates
#'
#' `ind_rise_rate` / `ind_fall_rate` are the median magnitudes of the positive
#' and negative step-to-step changes. A large rise rate with a small fall rate
#' is a system driven by sharp recharge pulses that then drain slowly.
#'
#' @inheritParams lap_ind_flashiness
#' @return A one-row tibble: `ind_rise_rate`, `ind_fall_rate`.
#' @family indicators
#' @export
lap_ind_rise_fall <- function(data, value = gwl, date = "date", ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date", null_ok = TRUE)
  s <- ind_series(data, value, date)
  d <- if (length(s$v) >= 3) diff(s$v) else numeric()
  rise <- d[d > 0]
  fall <- -d[d < 0]
  tibble::tibble(
    ind_rise_rate = if (length(rise)) stats::median(rise) else NA_real_,
    ind_fall_rate = if (length(fall)) stats::median(fall) else NA_real_
  )
}


# --- C. Long-term change ------------------------------------------------

#' Long-term trend (mean level)
#'
#' Theil-Sen slope + Mann-Kendall test on the annual-mean series (see
#' [lap_gw_trend()] for the full table with confidence intervals).
#' `ind_trend_slope` is in level units per year.
#'
#' @inheritParams lap_ind_seasonal_amplitude
#' @param min_years Minimum number of years; below this the outputs are `NA`.
#' @param alpha Significance level for `ind_trend_significant`.
#' @return A one-row tibble: `ind_trend_slope`, `ind_trend_p_value`,
#'   `ind_trend_significant`.
#' @family indicators
#' @export
lap_ind_trend <- function(data, value = gwl, date = "date",
                          min_years = 10L, alpha = 0.05, ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  s <- ind_series(data, value, date)
  na_row <- tibble::tibble(
    ind_trend_slope = NA_real_, ind_trend_p_value = NA_real_,
    ind_trend_significant = NA
  )
  if (!length(s$v)) {
    return(na_row)
  }
  annual <- tapply(s$v, s$yr, mean, na.rm = TRUE)
  years <- as.numeric(names(annual))
  annual <- as.numeric(annual)
  ok <- is.finite(years) & is.finite(annual)
  if (sum(ok) < min_years) {
    return(na_row)
  }
  o <- order(years[ok])
  res <- theil_sen_mann_kendall(years[ok][o], annual[ok][o])
  tibble::tibble(
    ind_trend_slope = res$slope,
    ind_trend_p_value = res$p_value,
    ind_trend_significant = isTRUE(res$p_value < alpha)
  )
}

#' Trend of the annual minima and maxima
#'
#' Theil-Sen slope (level units per year) of the series of annual minimum and of
#' annual maximum levels. Comparing `ind_trend_min_slope` with the mean trend
#' shows whether the *drought floor* is dropping faster than the average.
#'
#' @inheritParams lap_ind_trend
#' @return A one-row tibble: `ind_trend_min_slope`, `ind_trend_max_slope`.
#' @family indicators
#' @export
lap_ind_trend_extremes <- function(data, value = gwl, date = "date",
                                   min_years = 10L, ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  s <- ind_series(data, value, date)
  if (!length(s$v)) {
    return(tibble::tibble(ind_trend_min_slope = NA_real_, ind_trend_max_slope = NA_real_))
  }
  mn <- tapply(s$v, s$yr, min, na.rm = TRUE)
  mx <- tapply(s$v, s$yr, max, na.rm = TRUE)
  tibble::tibble(
    ind_trend_min_slope = sen_slope(as.numeric(names(mn)), as.numeric(mn), min_years),
    ind_trend_max_slope = sen_slope(as.numeric(names(mx)), as.numeric(mx), min_years)
  )
}

#' Step change (Pettitt change-point)
#'
#' `ind_step_year` is the year of the most likely single shift in the
#' annual-mean level (Pettitt test), `ind_step_magnitude` the mean level after
#' minus before, and `ind_step_p_value` the approximate significance. Captures
#' the abrupt post-drought regime shifts (e.g. 2003, 2018).
#'
#' @inheritParams lap_ind_trend_extremes
#' @return A one-row tibble: `ind_step_year`, `ind_step_magnitude`,
#'   `ind_step_p_value`.
#' @family indicators
#' @export
lap_ind_step_change <- function(data, value = gwl, date = "date",
                                min_years = 10L, ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  s <- ind_series(data, value, date)
  na_row <- tibble::tibble(
    ind_step_year = NA_real_, ind_step_magnitude = NA_real_, ind_step_p_value = NA_real_
  )
  if (!length(s$v)) {
    return(na_row)
  }
  am <- tapply(s$v, s$yr, mean, na.rm = TRUE)
  years <- as.numeric(names(am))
  am <- as.numeric(am)
  ok <- is.finite(years) & is.finite(am)
  if (sum(ok) < min_years) {
    return(na_row)
  }
  o <- order(years[ok])
  pt <- pettitt_change_point(years[ok][o], am[ok][o])
  tibble::tibble(
    ind_step_year = pt$year,
    ind_step_magnitude = pt$magnitude,
    ind_step_p_value = pt$p_value
  )
}

#' Trend acceleration
#'
#' `ind_trend_accel` = Theil-Sen slope over the second half of the record minus
#' the slope over the first half (level units per year). Positive = the level is
#' rising faster / falling slower than before; negative = an accelerating
#' decline.
#'
#' @inheritParams lap_ind_trend_extremes
#' @return A one-row tibble: `ind_trend_accel`.
#' @family indicators
#' @export
lap_ind_trend_acceleration <- function(data, value = gwl, date = "date",
                                       min_years = 16L, ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  s <- ind_series(data, value, date)
  if (!length(s$v)) {
    return(tibble::tibble(ind_trend_accel = NA_real_))
  }
  am <- tapply(s$v, s$yr, mean, na.rm = TRUE)
  years <- as.numeric(names(am))
  am <- as.numeric(am)
  ok <- is.finite(years) & is.finite(am)
  years <- years[ok]
  am <- am[ok]
  n <- length(years)
  if (n < min_years) {
    return(tibble::tibble(ind_trend_accel = NA_real_))
  }
  h <- floor(n / 2)
  tibble::tibble(
    ind_trend_accel = sen_slope(years[(h + 1):n], am[(h + 1):n], 5L) -
      sen_slope(years[1:h], am[1:h], 5L)
  )
}


# --- D. Drought / low-water --------------------------------------------

#' Drought characterisation from a standardised index
#'
#' Expects `value` to be an approximately standard-normal index such as the SGI
#' (add one with [lap_normalise_gwl()] `method = "sgi"` and pass
#' `value = gwl_norm`). Errors if the column does not look standardised.
#' A **drought event** is a maximal run of `value < threshold` (run theory,
#' Yevjevich 1967).
#'
#' \describe{
#'   \item{`ind_drought_frequency`}{fraction of timesteps below `threshold`}
#'   \item{`ind_frac_below_normal`}{fraction of timesteps below 0}
#'   \item{`ind_index_min`}{the most negative value in the slice}
#'   \item{`ind_drought_n_events`}{number of drought events}
#'   \item{`ind_drought_duration_weeks`}{mean event duration (timesteps)}
#'   \item{`ind_drought_max_weeks`}{longest single event}
#'   \item{`ind_drought_severity`}{mean cumulative deficit per event (sum of
#'     `-value` over the event)}
#'   \item{`ind_drought_intensity`}{mean deficit per timestep (severity /
#'     duration)}
#' }
#'
#' @inheritParams lap_ind_flashiness
#' @param threshold Drought threshold on the index. Default `-1`.
#' @param ... Ignored (uniform indicator signature).
#' @return A one-row tibble with the columns above.
#' @references Bloomfield, J.P. & Marchant, B.P. (2013) *HESS* 17, 4769.
#'   Yevjevich, V. (1967) *Hydrol. Pap.* 23, Colorado State Univ.
#'   Ebeling, P. et al. (2025) *HESS* 29, 2925.
#' @family indicators
#' @export
lap_ind_drought <- function(data, value = gwl_norm, date = "date",
                            threshold = -1, ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date", null_ok = TRUE)
  x <- ind_series(data, value, date)$v
  na_row <- tibble::tibble(
    ind_drought_frequency = NA_real_, ind_frac_below_normal = NA_real_,
    ind_index_min = NA_real_, ind_drought_n_events = NA_real_,
    ind_drought_duration_weeks = NA_real_, ind_drought_max_weeks = NA_real_,
    ind_drought_severity = NA_real_, ind_drought_intensity = NA_real_
  )
  if (length(x) < 12) {
    return(na_row)
  }
  check_standardised(x, value)
  ev <- drought_runs(x, threshold)
  tibble::tibble(
    ind_drought_frequency = mean(x < threshold),
    ind_frac_below_normal = mean(x < 0),
    ind_index_min = min(x),
    ind_drought_n_events = nrow(ev),
    ind_drought_duration_weeks = if (nrow(ev)) mean(ev$len) else NA_real_,
    ind_drought_max_weeks = if (nrow(ev)) max(ev$len) else 0,
    ind_drought_severity = if (nrow(ev)) mean(ev$severity) else NA_real_,
    ind_drought_intensity = if (nrow(ev)) mean(ev$severity / ev$len) else NA_real_
  )
}

#' Recovery from groundwater drought
#'
#' On a standardised index (see [lap_ind_drought()]): for each drought event
#' (run of `value < threshold`), the number of timesteps from the event's
#' minimum forward to the first `value >= 0`.
#'
#' \describe{
#'   \item{`ind_drought_recovery_weeks`}{mean recovery time over events that do
#'     recover}
#'   \item{`ind_drought_n_unrecovered`}{number of events whose recovery is not
#'     completed within the slice}
#' }
#'
#' @inheritParams lap_ind_drought
#' @return A one-row tibble with the two columns above.
#' @references Peterson, T.J. et al. (2021) *Nature* 591, 597 (groundwater
#'   drought that may not recover). USGS groundwater-drought metrics.
#' @family indicators
#' @export
lap_ind_drought_recovery <- function(data, value = gwl_norm, date = "date",
                                     threshold = -1, ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date", null_ok = TRUE)
  x <- ind_series(data, value, date)$v
  na_row <- tibble::tibble(
    ind_drought_recovery_weeks = NA_real_, ind_drought_n_unrecovered = NA_real_
  )
  if (length(x) < 12) {
    return(na_row)
  }
  check_standardised(x, value)
  ev <- drought_runs(x, threshold)
  rec <- ev$recovery[ev$recovered]
  tibble::tibble(
    ind_drought_recovery_weeks = if (length(rec)) mean(rec) else NA_real_,
    ind_drought_n_unrecovered = sum(!ev$recovered)
  )
}


# --- F+G. Climate coupling & anthropogenic imprint --------------------

#' Climate response time and the climate-removed (anthropogenic) trend
#'
#' Cross-correlates the well's SGI (`value`, standardised - see
#' [lap_ind_drought()]) against a co-located climate `driver` (precipitation,
#' or P - PET), standardised as an SPI/SPEI-analog over accumulation windows.
#' Add the driver with [lap_join_meteo()].
#'
#' \describe{
#'   \item{`ind_accum_months`}{driver accumulation window of maximum correlation}
#'   \item{`ind_climate_lag_months`}{lag at maximum correlation}
#'   \item{`ind_response_months`}{`ind_accum_months / 2 + ind_climate_lag_months`
#'     - the "peak-to-peak" propagation delay (Ebeling et al. 2025)}
#'   \item{`ind_climate_cc`}{that maximum cross-correlation - how climate-driven
#'     the well is}
#'   \item{`ind_residual_trend_slope`, `ind_residual_trend_p_value`,
#'     `ind_residual_trend_significant`}{Theil-Sen slope + Mann-Kendall test on
#'     the annual-mean residual of `lm(SGI ~ SPI)` - the long-term change *not*
#'     explained by climate. Compare with `ind_trend_slope`.}
#' }
#'
#' @inheritParams lap_ind_drought
#' @param driver <[`tidy-select`][dplyr::dplyr_tidy_select]> the climate driver
#'   column (e.g. precipitation).
#' @param max_acc,max_lag Largest accumulation window / lag to search, in months.
#' @param alpha Significance level for `ind_residual_trend_significant`.
#' @return A one-row tibble with the seven columns above.
#' @references Ebeling, P. et al. (2025) *HESS* 29, 2925. Retike, K. et al.
#'   (2020) *HESS* 24, 501 (residual screening for anthropogenic effects).
#' @family indicators
#' @export
lap_ind_climate_signal <- function(data, value = gwl_norm, date = "date",
                                   driver = precip, max_acc = 48L, max_lag = 24L,
                                   alpha = 0.05, ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  driver <- lap_eval_select_one(data, rlang::enquo(driver), arg = "driver")
  na_row <- tibble::tibble(
    ind_accum_months = NA_real_, ind_climate_lag_months = NA_real_,
    ind_response_months = NA_real_, ind_climate_cc = NA_real_,
    ind_residual_trend_slope = NA_real_, ind_residual_trend_p_value = NA_real_,
    ind_residual_trend_significant = NA
  )
  keep <- !is.na(data[[value]]) & !is.na(data[[date]]) & !is.na(data[[driver]])
  d <- data[keep, , drop = FALSE]
  if (nrow(d) < 60) {
    return(na_row)
  }
  dd <- as.Date(d[[date]])
  o <- order(dd)
  fit <- climate_coupling(
    d[[value]][o], d[[driver]][o], dd[o],
    max_acc = max_acc, max_lag = max_lag
  )
  if (is.na(fit$cc)) {
    return(na_row)
  }
  ok <- is.finite(fit$sgi) & is.finite(fit$spi)
  res_trend <- na_row[, c(
    "ind_residual_trend_slope", "ind_residual_trend_p_value",
    "ind_residual_trend_significant"
  )]
  if (sum(ok) >= 36) {
    resid <- fit$sgi[ok] - stats::fitted(stats::lm(fit$sgi[ok] ~ fit$spi[ok]))
    # annual-mean the residuals by 12-month blocks -> Theil-Sen slope per year
    blk <- ((seq_along(fit$sgi) - 1L) %/% 12L)[ok]
    am <- tapply(resid, blk, mean)
    if (length(am) >= 10) {
      tk <- theil_sen_mann_kendall(as.numeric(names(am)), as.numeric(am))
      res_trend <- tibble::tibble(
        ind_residual_trend_slope = tk$slope,
        ind_residual_trend_p_value = tk$p_value,
        ind_residual_trend_significant = isTRUE(tk$p_value < alpha)
      )
    }
  }
  tibble::tibble(
    ind_accum_months = fit$acc,
    ind_climate_lag_months = fit$lag,
    ind_response_months = fit$acc / 2 + fit$lag,
    ind_climate_cc = fit$cc,
    ind_residual_trend_slope = res_trend$ind_residual_trend_slope,
    ind_residual_trend_p_value = res_trend$ind_residual_trend_p_value,
    ind_residual_trend_significant = res_trend$ind_residual_trend_significant
  )
}


# --- H. Aquifer physics ------------------------------------------------

#' Master-recession-curve e-folding time
#'
#' Identifies sustained recession segments (falling / flat runs of at least
#' `min_len` steps, tolerating a single up-step), fits `log(level - asymptote)`
#' against time per segment and reports the median e-folding time. Short for
#' fast, unconfined systems; long (many months) for slow, confined ones. Can
#' lengthen as storage is depleted.
#'
#' \describe{
#'   \item{`ind_recession_weeks`}{median segment e-folding time}
#'   \item{`ind_recession_n_segments`}{number of segments that contributed}
#' }
#'
#' @inheritParams lap_ind_flashiness
#' @param min_len Minimum recession-segment length, in timesteps.
#' @return A one-row tibble with the two columns above.
#' @references Posavec, K. et al. (2017) *Groundwater* 55, 891 (master recession
#'   curve). Fiorillo, F. (2014) *Water Resour. Manag.* 28, 1919.
#' @family indicators
#' @export
lap_ind_recession <- function(data, value = gwl, date = "date",
                              min_len = 8L, ...) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date", null_ok = TRUE)
  s <- ind_series(data, value, date)
  if (length(s$v) < 3L * min_len) {
    return(tibble::tibble(ind_recession_weeks = NA_real_, ind_recession_n_segments = 0))
  }
  r <- recession_efold(s$v, min_len = min_len)
  tibble::tibble(ind_recession_weeks = r$tau, ind_recession_n_segments = r$n)
}
