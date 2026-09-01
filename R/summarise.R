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
#'
#' @return A tibble (or lazy tbl) with the grouping columns plus `min_gwl`,
#'   `max_gwl`, `mean_gwl`, `median_gwl`, `sd_gwl`, `n_obs`, `coverage`.
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' lap_summarise_wells(gems_ger_sample, by = c(well_id, year))
#' lap_summarise_wells(gems_ger_sample, by = "well_id", value = gwl)
lap_summarise_wells <- function(x,
                            by = c(well_id, year),
                            value = gwl,
                            expected_per_year = 52,
                            collect = TRUE) {
  is_lazy <- inherits(x, "tbl_lazy") || inherits(x, "tbl_sql")

  by <- lap_eval_select(x, rlang::enquo(by), extra = "year", arg = "by")
  value <- lap_eval_select_one(x, rlang::enquo(value), arg = "value")
  has_year <- "year" %in% by

  if (has_year && !"year" %in% lap_col_vocab(x)) {
    if (!"date" %in% lap_col_vocab(x)) {
      cli::cli_abort("Grouping by {.field year} needs a {.field year} or {.field date} column.")
    }
    x <- dplyr::mutate(x, year = as.integer(lubridate::year(.data$date)))
  }

  val <- rlang::sym(value)
  out <- x |>
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
