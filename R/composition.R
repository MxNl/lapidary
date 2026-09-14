# Share of wells per category, over time --------------------------------

#' Share of wells in each category, per time bucket
#'
#' Turns a row-level categorical column (e.g. [lap_add_quantile_class()]'s
#' `gwl_class`, or any other per-well state - drought / rising / falling, ...)
#' into a composition-over-time table: for each `period` bucket, how many
#' wells sat in each `category`, and what share of that bucket they were. Feed
#' the result to [lap_plot_stream()].
#'
#' If `x` has more than one row per well within a bucket (raw daily data, or a
#' `period` coarser than `x`'s own resolution), only the most recent row per
#' well per bucket counts - so a well contributes exactly once to each bucket
#' regardless of how finely `x` is sampled.
#'
#' @param x A data frame with `by`, `date` and `category` columns (e.g. the
#'   output of [lap_add_quantile_class()]).
#' @param category <[`tidy-select`][dplyr::dplyr_tidy_select]> the categorical
#'   column to tally (ideally a factor, so empty categories still get a `0`
#'   row rather than being silently dropped from a bucket).
#' @param date <[`tidy-select`][dplyr::dplyr_tidy_select]> the date column.
#'   Default `date`.
#' @param period Bucket width: `"week"` (default, ISO weeks, Monday start),
#'   `"month"` or `"year"`.
#' @param by <[`tidy-select`][dplyr::dplyr_tidy_select]> the well-identifying
#'   column(s). Default `well_id`.
#'
#' @return A tibble: `date` (the bucket start), `category`, `n` (well count)
#'   and `share` (`n` divided by the bucket total).
#' @seealso [lap_add_quantile_class()], [lap_plot_stream()]
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' gems_ger_sample |>
#'   lap_add_quantile_class() |>
#'   lap_summarise_composition(gwl_class)
lap_summarise_composition <- function(x, category, date = "date",
                                      period = c("week", "month", "year"),
                                      by = well_id) {
  period <- rlang::arg_match(period)
  category <- lap_eval_select_one(x, rlang::enquo(category), arg = "category")
  date_col <- lap_eval_select_one(x, rlang::enquo(date), arg = "date")
  by_nm <- lap_eval_select(x, rlang::enquo(by), arg = "by")

  x <- tibble::as_tibble(x)
  raw_date <- x[[date_col]]
  x[[date_col]] <- lubridate::floor_date(as.Date(raw_date), unit = period, week_start = 1)

  # one row per (well, bucket): the most recent, so finer-than-`period` input
  # (or a coarser `period` than x's own resolution) doesn't overcount a well
  x <- x[order(raw_date), ]
  x <- x |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(by_nm, date_col)))) |>
    dplyr::slice_tail(n = 1) |>
    dplyr::ungroup()

  x |>
    dplyr::count(
      dplyr::across(dplyr::all_of(c(date_col, category))),
      .drop = FALSE, name = "n"
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(date_col))) |>
    dplyr::mutate(share = .data$n / sum(.data$n)) |>
    dplyr::ungroup()
}
