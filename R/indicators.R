# Time-series indicators ----------------------------------------------------
#
# An "indicator" (or property) is a scalar - or a few scalars - computed from a
# well's *time series* that characterises its behaviour: amplitude, the timing
# of the annual extremes, a long-term trend, seasonality strength, ...
#
# Design (see docs/adr/0009):
#  * Each `lap_ind_*()` is a pure function of a time-series slice for ONE
#    series. It returns a one-row tibble whose columns are prefixed `ind_`.
#    It never sees a summary table.
#  * `lap_indicators()` is the collector: time series in once, a selection of
#    indicators (`"all"`, registry keys, or `lap_ind_*` functions), one row per
#    well out. `lap_indicator_registry()` lists what is available.
#  * `lap_add_indicators()` takes a well-level table + the time series and
#    left-joins the indicators on - for building a feature table step by step.
#  * Per-well-year summaries (`lap_summarise_wells()`) and per-well indicators
#    are deliberately separate tables; join them on `well_id` when you want both.

#' Compute time-series indicators per well
#'
#' Applies a selection of `lap_ind_*()` indicator functions to each series in
#' `x` and column-binds the results into a well-level table.
#'
#' @param x A `gwl_ts` / data frame of time series (one row per well x date).
#' @param .funs Which indicators to compute. Required. One of:
#'   \itemize{
#'     \item `"all"` - every indicator in [lap_indicator_registry()];
#'     \item a character vector of registry keys, e.g. `c("amplitude", "trend")`;
#'     \item one or more `lap_ind_*` functions, e.g. `c(lap_ind_amplitude, lap_ind_trend)`;
#'     \item a mix of keys and functions.
#'   }
#' @param by <[`tidy-select`][dplyr::dplyr_tidy_select]> the series-identifying
#'   column(s). Default `well_id`.
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the level column.
#'   Default `gwl`.
#' @param date <[`tidy-select`][dplyr::dplyr_tidy_select]> the date column, or
#'   `NULL` for a series with no dates. Default `date`.
#' @param ... Extra arguments forwarded to every `lap_ind_*()` (e.g.
#'   `threshold`, `min_len`, `driver`). Indicators ignore what they do not use.
#'
#' @return A tibble: the `by` column(s) plus one column per indicator output
#'   (all `ind_`-prefixed).
#' @seealso [lap_indicator_registry()], [lap_add_indicators()]
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' lap_indicators(gems_ger_sample, "all")
#' lap_indicators(gems_ger_sample, c("amplitude", "extreme_months"))
lap_indicators <- function(x, .funs, by = well_id, value = gwl, date = "date", ...) {
  funs <- resolve_ind_funs(if (missing(.funs)) NULL else .funs)
  by <- lap_eval_select(x, rlang::enquo(by), arg = "by")
  value <- lap_eval_select_one(x, rlang::enquo(value), arg = "value")
  date_col <- lap_eval_select_one(x, rlang::enquo(date), arg = "date", null_ok = TRUE)

  x <- tibble::as_tibble(x)
  grp <- interaction(x[by], drop = TRUE, lex.order = TRUE)
  parts <- split(x, grp, drop = TRUE)

  one_indicator <- function(f, part, ...) {
    # inject `value` / `date` as string literals so each indicator's tidy-select
    # sees a plain column name, not an external vector
    out <- rlang::inject(f(part, value = !!value, date = !!date_col, ...))
    if (!is.data.frame(out) || nrow(out) != 1L) {
      cli::cli_abort("Every {.fn lap_ind_*} must return a one-row data frame.")
    }
    out
  }
  rows <- lapply(parts, function(part) {
    key <- part[1, by, drop = FALSE]
    vals <- lapply(funs, one_indicator, part = part, ...)
    dplyr::bind_cols(key, !!!vals)
  })
  out <- tibble::as_tibble(do.call(rbind, rows))
  rownames(out) <- NULL
  out
}

# The indicator catalogue. A function (not a top-level list) so the `lap_ind_*`
# closures (R/ind-catalog.R) already exist when it runs. Add an entry when you
# add an indicator.
#
#   fn         - the lap_ind_* function
#   columns    - the ind_* column(s) it emits
#   needs_date - whether it needs a date column
#   in_all     - whether `.funs = "all"` runs it (drought needs an SGI column,
#                so it is opt-in)
#   delta_kind - per output column, how lap_indicator_delta() differences it:
#                "diff" (b - a), "circular" (signed month diff), "none" (skip)
#   range      - per output column, its theoretical value range in interval
#                notation ("[0, 1]", "(-Inf, Inf)", "{FALSE, TRUE}"); NA where
#                there is no meaningful fixed range. Surfaced in the registry.
#   units      - per output column, the physical unit ("m", "months", "weeks",
#                "m/year", "month", "year") or "-" for a dimensionless quantity.
#                "m" / "m/year" assume the level column is in metres.
#   description
#   reference  - short literature citation for the metric (surfaced in the
#                registry; the long form is vignette("indicators"))
indicator_catalog <- function() {
  d <- function(cols, kind = "diff") stats::setNames(rep(kind, length(cols)), cols)
  r <- function(cols, str) stats::setNames(rep(str, length(cols)), cols)
  list(
    amplitude = list(
      fn = lap_ind_amplitude, columns = "ind_amplitude",
      needs_date = FALSE, in_all = TRUE, delta_kind = d("ind_amplitude"),
      range = r("ind_amplitude", "[0, Inf)"),
      units = r("ind_amplitude", "m"),
      description = "max - min of the level over the slice",
      reference = "descriptive"
    ),
    seasonal_amplitude = list(
      fn = lap_ind_seasonal_amplitude, columns = "ind_seasonal_amplitude",
      needs_date = TRUE, in_all = TRUE, delta_kind = d("ind_seasonal_amplitude"),
      range = r("ind_seasonal_amplitude", "[0, Inf)"),
      units = r("ind_seasonal_amplitude", "m"),
      description = "mean over years of the annual (max - min)",
      reference = "descriptive"
    ),
    seasonality_strength = list(
      fn = lap_ind_seasonality_strength, columns = "ind_seasonality_strength",
      needs_date = TRUE, in_all = TRUE, delta_kind = d("ind_seasonality_strength"),
      range = r("ind_seasonality_strength", "[0, 1]"),
      units = r("ind_seasonality_strength", "-"),
      description = "STL variance ratio in [0, 1] on monthly means",
      reference = "Wang, Smith & Hyndman (2006) Data Min. Knowl. Discov. 13, 335"
    ),
    recharge_discharge = list(
      fn = lap_ind_recharge_discharge,
      columns = c("ind_recharge_months", "ind_discharge_months"),
      needs_date = TRUE, in_all = TRUE,
      delta_kind = d(c("ind_recharge_months", "ind_discharge_months")),
      range = c(ind_recharge_months = "[1, 12]", ind_discharge_months = "[0, 11]"),
      units = r(c("ind_recharge_months", "ind_discharge_months"), "months"),
      description = "length of the mean rising vs falling limb, in months",
      reference = "descriptive"
    ),
    phase_regularity = list(
      fn = lap_ind_phase_regularity, columns = "ind_min_month_sd",
      needs_date = TRUE, in_all = TRUE, delta_kind = d("ind_min_month_sd"),
      range = r("ind_min_month_sd", "[0, Inf)"),
      units = r("ind_min_month_sd", "months"),
      description = "circular SD (months) of the annual-minimum month",
      reference = "Mardia & Jupp (2000) Directional Statistics"
    ),
    extreme_months = list(
      fn = lap_ind_extreme_months, columns = c("ind_min_month", "ind_max_month"),
      needs_date = TRUE, in_all = TRUE,
      delta_kind = d(c("ind_min_month", "ind_max_month"), "circular"),
      range = r(c("ind_min_month", "ind_max_month"), "(0.5, 12.5]"),
      units = r(c("ind_min_month", "ind_max_month"), "month"),
      description = "circular-mean month of the annual minimum / maximum level",
      reference = "Mardia & Jupp (2000) Directional Statistics"
    ),
    flashiness = list(
      fn = lap_ind_flashiness, columns = "ind_flashiness",
      needs_date = FALSE, in_all = TRUE, delta_kind = d("ind_flashiness"),
      range = r("ind_flashiness", "[1, Inf)"),
      units = r("ind_flashiness", "-"),
      description = "sum(|diff(level)|) / range - path length per span",
      reference = "Baker et al. (2004) J. Am. Water Resour. Assoc. 40, 503"
    ),
    memory = list(
      fn = lap_ind_memory, columns = c("ind_acf1", "ind_memory_weeks"),
      needs_date = TRUE, in_all = TRUE,
      delta_kind = d(c("ind_acf1", "ind_memory_weeks")),
      range = c(ind_acf1 = "[-1, 1]", ind_memory_weeks = "[1, Inf)"),
      units = c(ind_acf1 = "-", ind_memory_weeks = "weeks"),
      description = "lag-1 autocorr + e-folding lag of the deseasonalised series",
      reference = "Rinaldo et al. (2015); Barker et al. (2016) HESS 20, 2483"
    ),
    rise_fall = list(
      fn = lap_ind_rise_fall, columns = c("ind_rise_rate", "ind_fall_rate"),
      needs_date = FALSE, in_all = TRUE,
      delta_kind = d(c("ind_rise_rate", "ind_fall_rate")),
      range = r(c("ind_rise_rate", "ind_fall_rate"), "(0, Inf)"),
      units = r(c("ind_rise_rate", "ind_fall_rate"), "m per step"),
      description = "median rate of rising vs falling steps",
      reference = "descriptive (cf. hydrograph rise/recession analysis)"
    ),
    trend = list(
      fn = lap_ind_trend,
      columns = c("ind_trend_slope", "ind_trend_p_value", "ind_trend_significant"),
      needs_date = TRUE, in_all = TRUE,
      delta_kind = c(
        ind_trend_slope = "diff", ind_trend_p_value = "none",
        ind_trend_significant = "none"
      ),
      range = c(
        ind_trend_slope = "(-Inf, Inf)", ind_trend_p_value = "[0, 1]",
        ind_trend_significant = "{FALSE, TRUE}"
      ),
      units = c(ind_trend_slope = "m/year", ind_trend_p_value = "-", ind_trend_significant = "-"),
      description = "Theil-Sen slope + Mann-Kendall test on annual mean levels",
      reference = "Sen (1968) JASA 63, 1379; Mann (1945); Kendall (1975)"
    ),
    trend_extremes = list(
      fn = lap_ind_trend_extremes,
      columns = c("ind_trend_min_slope", "ind_trend_max_slope"),
      needs_date = TRUE, in_all = TRUE,
      delta_kind = d(c("ind_trend_min_slope", "ind_trend_max_slope")),
      range = r(c("ind_trend_min_slope", "ind_trend_max_slope"), "(-Inf, Inf)"),
      units = r(c("ind_trend_min_slope", "ind_trend_max_slope"), "m/year"),
      description = "Theil-Sen slope of the annual minima / maxima",
      reference = "Sen (1968) JASA 63, 1379"
    ),
    step_change = list(
      fn = lap_ind_step_change,
      columns = c("ind_step_year", "ind_step_magnitude", "ind_step_p_value"),
      needs_date = TRUE, in_all = TRUE,
      delta_kind = c(
        ind_step_year = "none", ind_step_magnitude = "diff",
        ind_step_p_value = "none"
      ),
      range = c(
        ind_step_year = NA_character_, ind_step_magnitude = "(-Inf, Inf)",
        ind_step_p_value = "[0, 1]"
      ),
      units = c(ind_step_year = "year", ind_step_magnitude = "m", ind_step_p_value = "-"),
      description = "Pettitt change-point year + magnitude on annual means",
      reference = "Pettitt (1979) J. R. Stat. Soc. C 28, 126"
    ),
    trend_acceleration = list(
      fn = lap_ind_trend_acceleration, columns = "ind_trend_accel",
      needs_date = TRUE, in_all = TRUE, delta_kind = d("ind_trend_accel"),
      range = r("ind_trend_accel", "(-Inf, Inf)"),
      units = r("ind_trend_accel", "m/year"),
      description = "Sen slope(2nd half) - Sen slope(1st half) of annual means",
      reference = "descriptive (piecewise Theil-Sen)"
    ),
    drought = list(
      fn = lap_ind_drought,
      columns = c(
        "ind_drought_frequency", "ind_frac_below_normal", "ind_index_min",
        "ind_drought_n_events", "ind_drought_duration_weeks",
        "ind_drought_max_weeks", "ind_drought_severity", "ind_drought_intensity"
      ),
      needs_date = FALSE, in_all = FALSE,
      delta_kind = d(c(
        "ind_drought_frequency", "ind_frac_below_normal", "ind_index_min",
        "ind_drought_n_events", "ind_drought_duration_weeks",
        "ind_drought_max_weeks", "ind_drought_severity", "ind_drought_intensity"
      )),
      range = c(
        ind_drought_frequency = "[0, 1]", ind_frac_below_normal = "[0, 1]",
        ind_index_min = "(-Inf, Inf)", ind_drought_n_events = "[0, Inf)",
        ind_drought_duration_weeks = "[1, Inf)", ind_drought_max_weeks = "[0, Inf)",
        ind_drought_severity = "(0, Inf)", ind_drought_intensity = "(0, Inf)"
      ),
      units = c(ind_drought_frequency = "-", ind_frac_below_normal = "-", ind_index_min = "-",
        ind_drought_n_events = "-", ind_drought_duration_weeks = "weeks",
        ind_drought_max_weeks = "weeks", ind_drought_severity = "-", ind_drought_intensity = "-"),
      description = "run-theory drought stats from a standardised index (needs an SGI column)",
      reference = "Bloomfield & Marchant (2013) HESS 17, 4769; Yevjevich (1967); Ebeling et al. (2025) HESS 29, 2925"
    ),
    drought_recovery = list(
      fn = lap_ind_drought_recovery,
      columns = c("ind_drought_recovery_weeks", "ind_drought_n_unrecovered"),
      needs_date = FALSE, in_all = FALSE,
      delta_kind = d(c("ind_drought_recovery_weeks", "ind_drought_n_unrecovered")),
      range = r(c("ind_drought_recovery_weeks", "ind_drought_n_unrecovered"), "[0, Inf)"),
      units = c(ind_drought_recovery_weeks = "weeks", ind_drought_n_unrecovered = "-"),
      description = "recovery time from drought minima on a standardised index (needs an SGI column)",
      reference = "Peterson, Saft & Peel (2021) Nature 591, 597"
    ),
    climate_signal = list(
      fn = lap_ind_climate_signal,
      columns = c(
        "ind_accum_months", "ind_climate_lag_months", "ind_response_months",
        "ind_climate_cc", "ind_residual_trend_slope",
        "ind_residual_trend_p_value", "ind_residual_trend_significant"
      ),
      needs_date = TRUE, in_all = FALSE,
      delta_kind = c(
        ind_accum_months = "diff", ind_climate_lag_months = "diff",
        ind_response_months = "diff", ind_climate_cc = "diff",
        ind_residual_trend_slope = "diff", ind_residual_trend_p_value = "none",
        ind_residual_trend_significant = "none"
      ),
      range = c(
        ind_accum_months = "[1, Inf)", ind_climate_lag_months = "[0, Inf)",
        ind_response_months = "(0, Inf)", ind_climate_cc = "[-1, 1]",
        ind_residual_trend_slope = "(-Inf, Inf)", ind_residual_trend_p_value = "[0, 1]",
        ind_residual_trend_significant = "{FALSE, TRUE}"
      ),
      units = c(ind_accum_months = "months", ind_climate_lag_months = "months",
        ind_response_months = "months", ind_climate_cc = "-",
        ind_residual_trend_slope = "SGI/year", ind_residual_trend_p_value = "-",
        ind_residual_trend_significant = "-"),
      description = "climate response time + climate-removed trend (needs an SGI column and a driver)",
      reference = "Ebeling et al. (2025) HESS 29, 2925; Retike et al. (2020) HESS 24, 501"
    ),
    recession = list(
      fn = lap_ind_recession,
      columns = c("ind_recession_weeks", "ind_recession_n_segments"),
      needs_date = FALSE, in_all = TRUE,
      delta_kind = d(c("ind_recession_weeks", "ind_recession_n_segments")),
      range = c(ind_recession_weeks = "(0, Inf)", ind_recession_n_segments = "[0, Inf)"),
      units = c(ind_recession_weeks = "weeks", ind_recession_n_segments = "-"),
      description = "master-recession-curve e-folding time from falling segments",
      reference = "Posavec, Bacani & Nakic (2006) Ground Water 44, 764; Fiorillo (2014) Water Resour. Manag. 28, 1919"
    )
  )
}

#' The available time-series indicators
#'
#' Lists what [lap_indicators()] can compute, so you do not have to memorise the
#' `lap_ind_*` function names.
#'
#' @param long If `FALSE` (default) one row per indicator key, with the emitted
#'   columns, ranges and units `" | "`-separated and positionally aligned. If
#'   `TRUE`, one row per emitted `ind_*` column (`key`, `column`, `range`,
#'   `units`, `delta_kind`, `needs_date`, `in_all`, `description`, `reference`).
#'
#' @return A tibble. Wide (`long = FALSE`): `key`, `columns`, `range`, `units`,
#'   `needs_date`, `in_all`, `description`, `reference`. Long (`long = TRUE`):
#'   one row per `ind_*` column with `column`, `range`, `units` and `delta_kind`
#'   (how [lap_indicator_delta()] differences it). Units are `"m"`, `"months"`,
#'   `"weeks"`, `"m/year"`, `"month"`, `"year"`, ... or `"-"` for a
#'   dimensionless quantity (`"m"` assumes a level column in metres).
#'   Value ranges use interval notation; the long form is `vignette("indicators")`.
#' @export
#' @examples
#' lap_indicator_registry()
#' lap_indicator_registry(long = TRUE)
lap_indicator_registry <- function(long = FALSE) {
  reg <- indicator_catalog()

  if (isTRUE(long)) {
    rows <- lapply(names(reg), function(k) {
      e <- reg[[k]]
      tibble::tibble(
        key = k,
        column = e$columns,
        range = unname(e$range[e$columns]),
        units = unname(e$units[e$columns]),
        delta_kind = unname(e$delta_kind[e$columns]),
        needs_date = e$needs_date,
        in_all = e$in_all,
        description = e$description,
        reference = e$reference %||% NA_character_
      )
    })
    return(dplyr::bind_rows(rows))
  }

  joined <- function(field, sep) {
    vapply(reg, function(e) {
      paste(unname(e[[field]][e$columns]), collapse = sep)
    }, character(1), USE.NAMES = FALSE)
  }
  tibble::tibble(
    key = names(reg),
    columns = vapply(reg, function(e) toString(e$columns), character(1), USE.NAMES = FALSE),
    range = joined("range", " | "),
    units = joined("units", " | "),
    needs_date = vapply(reg, function(e) e$needs_date, logical(1), USE.NAMES = FALSE),
    in_all = vapply(reg, function(e) e$in_all, logical(1), USE.NAMES = FALSE),
    description = vapply(reg, function(e) e$description, character(1), USE.NAMES = FALSE),
    reference = vapply(
      reg, function(e) e$reference %||% NA_character_, character(1),
      USE.NAMES = FALSE
    )
  )
}

# Look up how lap_indicator_delta() should difference an `ind_*` column.
column_delta_kind <- function(col) {
  for (e in indicator_catalog()) {
    if (col %in% names(e$delta_kind)) {
      return(unname(e$delta_kind[[col]]))
    }
  }
  "diff"
}

# An `ind_*` column's theoretical value range (interval-notation string);
# NA when the column is not catalogued. Vectorised over `col`.
column_range <- function(col) {
  catalog_lookup("range", col)
}

# An `ind_*` column's physical unit ("m", "weeks", "-", ...); NA when the
# column is not catalogued. Vectorised over `col`.
column_units <- function(col) {
  catalog_lookup("units", col)
}

# Look up a per-column catalogue field, unnamed, vectorised over `col`.
catalog_lookup <- function(field, col) {
  lookup <- unlist(lapply(indicator_catalog(), `[[`, field))
  names(lookup) <- sub("^[^.]*\\.", "", names(lookup))
  unname(lookup[col])
}

# Resolve the `.funs` argument to a list of indicator functions.
resolve_ind_funs <- function(.funs, call = rlang::caller_env()) {
  reg <- indicator_catalog()
  if (is.null(.funs)) {
    cli::cli_abort(c(
      "{.arg .funs} is required.",
      i = 'Use {.val all}, a subset of {.code lap_indicator_registry()$key}, \\
           or {.fn lap_ind_*} functions.'
    ), call = call)
  }
  if (identical(.funs, "all")) {
    return(lapply(Filter(function(e) e$in_all, reg), `[[`, "fn"))
  }
  items <- if (is.function(.funs)) list(.funs) else as.list(.funs)
  lapply(items, function(it) {
    if (is.function(it)) {
      return(it)
    }
    if (is.character(it) && length(it) == 1L) {
      entry <- reg[[it]]
      if (is.null(entry)) {
        cli::cli_abort(c(
          "Unknown indicator key {.val {it}}.",
          i = "Keys: {.val {names(reg)}} (or {.val all})."
        ), call = call)
      }
      return(entry$fn)
    }
    cli::cli_abort(
      "{.arg .funs} entries must be indicator keys or {.fn lap_ind_*} functions.",
      call = call
    )
  })
}

#' Append time-series indicators to a well-level table
#'
#' For building an indicator set step by step: takes an existing well-level
#' table, computes the requested indicators from the time series, and left-joins
#' them on `by`.
#'
#' @param data A well-level table (e.g. from [lap_summarise_wells()] grouped by
#'   `well_id`, or a `gwl_wells` layer).
#' @param x The time series the indicators are computed from.
#' @param .funs Which indicators to compute; see [lap_indicators()].
#' @param by <[`tidy-select`][dplyr::dplyr_tidy_select]> join key(s), present in
#'   both `data` and `x`. Default `well_id`.
#' @param value,date Passed to [lap_indicators()].
#' @param ... Extra arguments forwarded to each `lap_ind_*()` (e.g. `threshold`,
#'   `driver`).
#'
#' @return `data` with the indicator columns added.
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' lap_summarise_wells(gems_ger_sample, by = well_id) |>
#'   lap_add_indicators(gems_ger_sample, "all")
lap_add_indicators <- function(data, x, .funs, by = well_id,
                               value = gwl, date = "date", ...) {
  by_nm <- lap_eval_select(data, rlang::enquo(by), arg = "by")
  ind <- lap_indicators(
    x,
    .funs = if (missing(.funs)) NULL else .funs, by = dplyr::all_of(by_nm),
    value = {{ value }}, date = {{ date }}, ...
  )
  is_sf <- inherits(data, "sf")
  out <- dplyr::left_join(
    if (is_sf) sf::st_drop_geometry(data) else data,
    ind,
    by = by_nm
  )
  if (is_sf) {
    out <- sf::st_sf(out, geometry = sf::st_geometry(data))
  }
  out
}


# --- indicators over multiple periods -----------------------------------

# Rows of `x` whose calendar year (from `date_col`) is within `range`.
slice_years <- function(x, date_col, range) {
  yr <- as.integer(format(as.Date(x[[date_col]]), "%Y"))
  x[!is.na(yr) & yr >= range[[1]] & yr <= range[[2]], , drop = FALSE]
}

#' Compute indicators over several time windows
#'
#' Runs [lap_indicators()] once per named period and stacks the results, so the
#' change in a well's behaviour between (say) a reference decade and a recent one
#' is visible. Unlike [lap_add_reference_period()], the periods **may overlap**
#' (e.g. a full-record window alongside a recent one).
#'
#' @inheritParams lap_indicators
#' @param periods A **named** list of `c(start_year, end_year)` pairs, e.g.
#'   `list(reference = c(1991, 2010), recent = c(2011, 2022))`.
#' @param ... Extra arguments forwarded to each `lap_ind_*()` (e.g. `threshold`,
#'   `driver`). For `climate_signal` the driver column must already be in `x`
#'   (join it with [lap_join_meteo()] before slicing into periods).
#'
#' @return A long tibble: the `by` column(s), a `period` **ordered factor**
#'   (levels in the order of `periods`), and the `ind_*` columns.
#' @seealso [lap_indicator_delta()] to turn this into one row per well with
#'   change columns.
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' lap_indicator_change(
#'   gems_ger_sample, c("amplitude", "trend"),
#'   periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
#' )
lap_indicator_change <- function(x, .funs, periods, by = well_id,
                                 value = gwl, date = "date", ...) {
  funs <- resolve_ind_funs(if (missing(.funs)) NULL else .funs)
  periods <- validate_periods(periods, allow_overlap = TRUE)
  date_col <- lap_eval_select_one(x, rlang::enquo(date), arg = "date")
  x <- tibble::as_tibble(x)

  rows <- lapply(names(periods), function(nm) {
    sl <- slice_years(x, date_col, periods[[nm]])
    if (!nrow(sl)) {
      return(NULL)
    }
    res <- rlang::inject(lap_indicators(
      sl,
      .funs = funs, by = {{ by }}, value = {{ value }}, date = !!date_col, ...
    ))
    res[["period"]] <- factor(nm, levels = names(periods), ordered = TRUE)
    res
  })
  out <- dplyr::bind_rows(rows)
  dplyr::relocate(out, "period", .before = dplyr::starts_with("ind_"))
}

#' Difference indicators between two periods
#'
#' Takes the long output of [lap_indicator_change()] and returns one row per
#' well with, for each indicator column, its value in `from`, its value in `to`,
#' and the change - differenced according to the indicator's kind (a plain
#' difference; a signed month difference in `(-6, 6]` for the circular month
#' columns; nothing for p-values and `ind_step_year`).
#'
#' @param change The long tibble from [lap_indicator_change()].
#' @param from,to Period labels present in `change$period`.
#' @param by <[`tidy-select`][dplyr::dplyr_tidy_select]> the well-identifying
#'   column(s). Default `well_id`.
#'
#' @return A tibble, one row per `by`, with `<col>_<from>`, `<col>_<to>` and
#'   (where meaningful) `<col>_change` for each `ind_*` column.
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' chg <- lap_indicator_change(
#'   gems_ger_sample, c("amplitude", "extreme_months"),
#'   periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
#' )
#' lap_indicator_delta(chg, "reference", "recent")
lap_indicator_delta <- function(change, from, to, by = well_id) {
  by_nm <- lap_eval_select(change, rlang::enquo(by), arg = "by")
  if (!"period" %in% names(change)) {
    cli::cli_abort("{.arg change} needs a {.field period} column (from {.fn lap_indicator_change}).")
  }
  have <- as.character(unique(change[["period"]]))
  bad <- setdiff(c(from, to), have)
  if (length(bad)) {
    cli::cli_abort(c(
      "{cli::qty(bad)}Period{?s} {.val {bad}} not in {.arg change}.",
      i = "Available periods: {.val {have}}."
    ))
  }
  ind_cols <- grep("^ind_", names(change), value = TRUE)

  a <- change[as.character(change[["period"]]) == from, c(by_nm, ind_cols), drop = FALSE]
  b <- change[as.character(change[["period"]]) == to, c(by_nm, ind_cols), drop = FALSE]
  names(a)[match(ind_cols, names(a))] <- paste0(ind_cols, "_", from)
  names(b)[match(ind_cols, names(b))] <- paste0(ind_cols, "_", to)
  out <- dplyr::full_join(a, b, by = by_nm)

  ordered <- by_nm
  for (col in ind_cols) {
    av <- out[[paste0(col, "_", from)]]
    bv <- out[[paste0(col, "_", to)]]
    cols_here <- c(paste0(col, "_", from), paste0(col, "_", to))
    kind <- column_delta_kind(col)
    if (kind == "diff") {
      out[[paste0(col, "_change")]] <- bv - av
      cols_here <- c(cols_here, paste0(col, "_change"))
    } else if (kind == "circular") {
      out[[paste0(col, "_change")]] <- circular_month_diff(av, bv)
      cols_here <- c(cols_here, paste0(col, "_change"))
    }
    ordered <- c(ordered, cols_here)
  }
  tibble::as_tibble(out[, ordered, drop = FALSE])
}
