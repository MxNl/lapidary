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
#'
#' @return A tibble: the `by` column(s) plus one column per indicator output
#'   (all `ind_`-prefixed).
#' @seealso [lap_indicator_registry()], [lap_add_indicators()]
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' lap_indicators(gems_ger_sample, "all")
#' lap_indicators(gems_ger_sample, c("amplitude", "extreme_months"))
lap_indicators <- function(x, .funs, by = well_id, value = gwl, date = "date") {
  funs <- resolve_ind_funs(if (missing(.funs)) NULL else .funs)
  by <- lap_eval_select(x, rlang::enquo(by), arg = "by")
  value <- lap_eval_select_one(x, rlang::enquo(value), arg = "value")
  date_col <- lap_eval_select_one(x, rlang::enquo(date), arg = "date", null_ok = TRUE)

  x <- tibble::as_tibble(x)
  grp <- interaction(x[by], drop = TRUE, lex.order = TRUE)
  parts <- split(x, grp, drop = TRUE)

  rows <- lapply(parts, function(part) {
    key <- part[1, by, drop = FALSE]
    vals <- lapply(funs, function(f) {
      out <- f(part, value = value, date = date_col)
      if (!is.data.frame(out) || nrow(out) != 1L) {
        cli::cli_abort("Every {.fn lap_ind_*} must return a one-row data frame.")
      }
      out
    })
    dplyr::bind_cols(key, !!!vals)
  })
  out <- tibble::as_tibble(do.call(rbind, rows))
  rownames(out) <- NULL
  out
}

# The indicator catalogue. A function (not a top-level list) so the `lap_ind_*`
# closures already exist when it runs. Add an entry when you add an indicator.
lap_ind_registry <- function() {
  list(
    amplitude = list(
      fn = lap_ind_amplitude,
      columns = "ind_amplitude",
      needs_date = FALSE,
      description = "max - min of the level over the whole record"
    ),
    extreme_months = list(
      fn = lap_ind_extreme_months,
      columns = c("ind_min_month", "ind_max_month"),
      needs_date = TRUE,
      description = "circular-mean month of the annual minimum / maximum level"
    ),
    trend = list(
      fn = lap_ind_trend,
      columns = c("ind_trend_slope", "ind_trend_p_value", "ind_trend_significant"),
      needs_date = TRUE,
      description = "Theil-Sen slope + Mann-Kendall test on annual mean levels"
    )
  )
}

#' The available time-series indicators
#'
#' Lists what [lap_indicators()] can compute, so you do not have to memorise the
#' `lap_ind_*` function names.
#'
#' @return A tibble with one row per indicator: `key` (use it in `.funs`),
#'   `columns` (the `ind_*` columns it emits), `needs_date` and `description`.
#' @export
#' @examples
#' lap_indicator_registry()
lap_indicator_registry <- function() {
  reg <- lap_ind_registry()
  tibble::tibble(
    key = names(reg),
    columns = vapply(reg, function(e) toString(e$columns), character(1)),
    needs_date = vapply(reg, function(e) e$needs_date, logical(1)),
    description = vapply(reg, function(e) e$description, character(1))
  )
}

# Resolve the `.funs` argument to a list of indicator functions.
resolve_ind_funs <- function(.funs, call = rlang::caller_env()) {
  reg <- lap_ind_registry()
  if (is.null(.funs)) {
    cli::cli_abort(c(
      "{.arg .funs} is required.",
      i = 'Use {.val all}, a subset of {.code lap_indicator_registry()$key}, \\
           or {.fn lap_ind_*} functions.'
    ), call = call)
  }
  if (identical(.funs, "all")) {
    return(lapply(reg, `[[`, "fn"))
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
#'
#' @return `data` with the indicator columns added.
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' lap_summarise_wells(gems_ger_sample, by = well_id) |>
#'   lap_add_indicators(gems_ger_sample, "all")
lap_add_indicators <- function(data, x, .funs, by = well_id,
                               value = gwl, date = "date") {
  by_nm <- lap_eval_select(data, rlang::enquo(by), arg = "by")
  ind <- lap_indicators(
    x,
    .funs = if (missing(.funs)) NULL else .funs, by = dplyr::all_of(by_nm),
    value = {{ value }}, date = {{ date }}
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

# --- indicator functions --------------------------------------------------
#
# Contract: `lap_ind_<name>(data, value = gwl, date = "date", ...)` where `data`
# is a one-series slice. Return a one-row tibble with `ind_`-prefixed columns.
# `value` / `date` are tidy-select (bare name, string, or a name held in a
# variable - which is how `lap_indicators()` forwards them).

#' Groundwater-level amplitude
#'
#' `ind_amplitude` = max - min of the level over the whole record.
#'
#' @param data A one-series data frame.
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> level column.
#' @param date Unused; present for a uniform indicator signature.
#'
#' @return A one-row tibble: `ind_amplitude`.
#' @family indicators
#' @export
lap_ind_amplitude <- function(data, value = gwl, date = "date") {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  v <- data[[value]]
  amp <- if (all(is.na(v))) NA_real_ else diff(range(v, na.rm = TRUE))
  tibble::tibble(ind_amplitude = amp)
}

#' Timing of the annual groundwater extremes
#'
#' For each calendar year the month of the annual minimum and of the annual
#' maximum level is found; `ind_min_month` / `ind_max_month` are the
#' [circular means][lap_circular_mean_month] of those months across years
#' (values in `(0.5, 12.5]`). These mark, roughly, the end of the discharge and
#' the end of the recharge period.
#'
#' @param data A one-series data frame.
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> level column.
#' @param date <[`tidy-select`][dplyr::dplyr_tidy_select]> date column.
#'
#' @return A one-row tibble: `ind_min_month`, `ind_max_month`.
#' @family indicators
#' @export
lap_ind_extreme_months <- function(data, value = gwl, date = "date") {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  d <- data[!is.na(data[[value]]) & !is.na(data[[date]]), , drop = FALSE]
  if (!nrow(d)) {
    return(tibble::tibble(ind_min_month = NA_real_, ind_max_month = NA_real_))
  }
  dd <- as.Date(d[[date]])
  yr <- as.integer(format(dd, "%Y"))
  mo <- as.integer(format(dd, "%m"))
  v <- d[[value]]
  per_year <- lapply(split(seq_along(v), yr), function(ix) {
    c(min_m = mo[ix][which.min(v[ix])], max_m = mo[ix][which.max(v[ix])])
  })
  per_year <- do.call(rbind, per_year)
  tibble::tibble(
    ind_min_month = lap_circular_mean_month(per_year[, "min_m"]),
    ind_max_month = lap_circular_mean_month(per_year[, "max_m"])
  )
}

#' Long-term trend as an indicator
#'
#' Fits a Theil-Sen slope with a Mann-Kendall test to the series of annual mean
#' levels (see [lap_gw_trend()] for the full trend table with confidence
#' intervals). `ind_trend_slope` is in level units per year.
#'
#' @param data A one-series data frame.
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> level column.
#' @param date <[`tidy-select`][dplyr::dplyr_tidy_select]> date column.
#' @param min_years Minimum number of years; below this the outputs are `NA`.
#' @param alpha Significance level for `ind_trend_significant`.
#'
#' @return A one-row tibble: `ind_trend_slope`, `ind_trend_p_value`,
#'   `ind_trend_significant`.
#' @family indicators
#' @export
lap_ind_trend <- function(data, value = gwl, date = "date",
                          min_years = 10L, alpha = 0.05) {
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  date <- lap_eval_select_one(data, rlang::enquo(date), arg = "date")
  na_row <- tibble::tibble(
    ind_trend_slope = NA_real_, ind_trend_p_value = NA_real_,
    ind_trend_significant = NA
  )
  d <- data[!is.na(data[[value]]) & !is.na(data[[date]]), , drop = FALSE]
  if (!nrow(d)) {
    return(na_row)
  }
  yr <- as.integer(format(as.Date(d[[date]]), "%Y"))
  annual <- tapply(d[[value]], yr, mean, na.rm = TRUE)
  years <- as.numeric(names(annual))
  annual <- as.numeric(annual)
  ok <- is.finite(years) & is.finite(annual)
  if (sum(ok) < min_years) {
    return(na_row)
  }
  ord <- order(years[ok])
  res <- theil_sen_mann_kendall(years[ok][ord], annual[ok][ord])
  tibble::tibble(
    ind_trend_slope = res$slope,
    ind_trend_p_value = res$p_value,
    ind_trend_significant = isTRUE(res$p_value < alpha)
  )
}
