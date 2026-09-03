#' Per-well (and per-period) groundwater summaries
#'
#' Collapses a groundwater time series to one row per group, where the grouping
#' is usually the well and optionally the (water) year. Works both on an
#' in-memory `gwl_ts` / data frame and on a lazy `dplyr` table backed by DuckDB
#' (see [lap_gwl_tbl()]); in the lazy case the aggregation is pushed down to the
#' database and you get a lazy result back unless `collect = TRUE`.
#'
#' `coverage` is the fraction of the expected number of observations that are
#' actually present, using `expected_per_year` as the nominal count for a full
#' year (52 for weekly GEMS-GER data, 12 for monthly series). For groupings
#' without a year component `coverage` is `NA`.
#'
#' @param x A `gwl_ts`, data frame, or lazy `dplyr` tbl.
#' @param by <[`tidy-select`][dplyr::dplyr_tidy_select]> grouping columns:
#'   bare names, strings, or helpers. Defaults to `c(well_id, year)`; a `year`
#'   column is derived from `date` if it is requested but absent.
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the single column to
#'   summarise. Defaults to `gwl`.
#' @param expected_per_year Nominal observations per full year, for `coverage`.
#' @param collect If `x` is lazy, whether to [dplyr::collect()] the result.
#' @param indicators Optional `lap_ind_*()` function or list of them
#'   ([lap_indicators()]) to compute from the same time series and join onto the
#'   result. Only valid for a well-level grouping (no `year` in `by`); forces an
#'   in-memory computation if `x` is lazy.
#'
#' @return A tibble (or lazy tbl) with the grouping columns plus `min_gwl`,
#'   `max_gwl`, `mean_gwl`, `median_gwl`, `sd_gwl`, `n_obs`, `coverage`, and any
#'   `ind_*` columns from `indicators`.
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' lap_summarise_wells(gems_ger_sample, by = c(well_id, year))
#' lap_summarise_wells(gems_ger_sample, by = "well_id", value = gwl)
#' lap_summarise_wells(
#'   gems_ger_sample,
#'   by = well_id, indicators = c(lap_ind_amplitude, lap_ind_trend)
#' )
lap_summarise_wells <- function(x,
                            by = c(well_id, year),
                            value = gwl,
                            expected_per_year = 52,
                            collect = TRUE,
                            indicators = NULL) {
  is_lazy <- inherits(x, "tbl_lazy") || inherits(x, "tbl_sql")

  by <- lap_eval_select(x, rlang::enquo(by), extra = "year", arg = "by")
  value <- lap_eval_select_one(x, rlang::enquo(value), arg = "value")
  has_year <- "year" %in% by

  if (!is.null(indicators)) {
    if (has_year) {
      cli::cli_abort(c(
        "{.arg indicators} needs a well-level grouping.",
        i = "Drop {.field year} from {.arg by}: indicators are one value per well."
      ))
    }
    if (is_lazy) {
      cli::cli_inform("Collecting {.arg x} to compute indicators in memory.")
      x <- dplyr::collect(x)
      is_lazy <- FALSE
    }
  }

  if (has_year && !"year" %in% lap_col_vocab(x)) {
    if (!"date" %in% lap_col_vocab(x)) {
      cli::cli_abort("Grouping by {.field year} needs a {.field year} or {.field date} column.")
    }
    x <- dplyr::mutate(x, year = as.integer(lubridate::year(.data$date)))
  }

  val <- rlang::sym(value)
  summarise_grouped <- function() {
    x |>
      dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
      dplyr::summarise(
        min_gwl = min(!!val, na.rm = TRUE),
        max_gwl = max(!!val, na.rm = TRUE),
        mean_gwl = mean(!!val, na.rm = TRUE),
        median_gwl = stats::median(!!val, na.rm = TRUE),
        sd_gwl = stats::sd(!!val, na.rm = TRUE),
        n_obs = dplyr::n(),
        .groups = "drop"
      )
  }
  # An all-NA group makes base `min()/max()` return +/-Inf with a warning
  # (the DuckDB path already yields NULL). Muffle that specific warning here;
  # the non-finite values are turned into NA below.
  out <- withCallingHandlers(
    summarise_grouped(),
    warning = function(w) {
      if (grepl("no non-missing arguments", conditionMessage(w), fixed = TRUE)) {
        invokeRestart("muffleWarning")
      }
    }
  )

  if (has_year) {
    out <- dplyr::mutate(
      out,
      coverage = .data$n_obs / .env$expected_per_year
    )
  } else {
    out <- dplyr::mutate(out, coverage = NA_real_)
  }

  if (is_lazy && collect) {
    out <- dplyr::collect(out)
  }
  if (!is_lazy || collect) {
    out <- tibble::as_tibble(out)
    # base min()/max()/sd() on all-NA groups -> Inf / -Inf / NaN; normalise to NA
    stat_cols <- c("min_gwl", "max_gwl", "mean_gwl", "median_gwl", "sd_gwl")
    out[stat_cols] <- lapply(out[stat_cols], function(v) {
      v[!is.finite(v)] <- NA_real_
      v
    })
  }

  if (!is.null(indicators)) {
    ind <- lap_indicators(x, .funs = indicators, by = dplyr::all_of(by), value = dplyr::all_of(value))
    out <- dplyr::left_join(out, ind, by = by)
  }
  out
}

#' Keep only wells with enough temporal coverage
#'
#' @param summary A tibble from [lap_summarise_wells()] grouped by
#'   `c("well_id", "year")`.
#' @param min_years Minimum number of years a well must have.
#' @param min_coverage Minimum per-year `coverage` for a year to count.
#'
#' @return A character vector of `well_id`s that pass.
#' @export
lap_wells_with_coverage <- function(summary, min_years = 20, min_coverage = 0.9) {
  if (!all(c("well_id", "coverage") %in% names(summary))) {
    cli::cli_abort("{.arg summary} needs {.field well_id} and {.field coverage} columns.")
  }
  summary |>
    dplyr::filter(.data$coverage >= .env$min_coverage) |>
    dplyr::count(.data$well_id, name = "n_good_years") |>
    dplyr::filter(.data$n_good_years >= .env$min_years) |>
    dplyr::pull(.data$well_id)
}
