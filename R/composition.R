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

#' Sum event columns into a year x month/week calendar grid
#'
#' Turns one or more row-level numeric or logical columns (e.g.
#' [lap_add_record_flags()]'s `is_new_min` / `is_new_max`) into a long
#' `year | unit | name | n` table - the sum of each column, across *every*
#' row of `x` (not per well), in every calendar bucket. Feed the result to
#' [lap_plot_calendar()].
#'
#' @param x A data frame with a `date` column and the columns to sum.
#' @param ... <[`tidy-select`][dplyr::dplyr_tidy_select]> one or more
#'   numeric or logical columns to sum, e.g. `is_new_min, is_new_max`.
#' @param date <[`tidy-select`][dplyr::dplyr_tidy_select]> the date column.
#'   Default `date`.
#' @param period `"month"` (default, `unit` is 1-12) or `"week"` (`unit` is
#'   the ISO week number, paired with its ISO week-year so the Dec/Jan
#'   week-53 edge case lands in the right year).
#'
#' @return A tibble: `year`, `unit`, `name` (the summed column, with a
#'   leading `is_` stripped for a cleaner label) and `n` (its sum in that
#'   bucket). A `(year, unit)` only appears if `x` has at least one row then;
#'   a bucket with rows but no flagged event still gets a real `n = 0`.
#' @seealso [lap_add_record_flags()], [lap_plot_calendar()]
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' flagged <- lap_add_record_flags(gems_ger_sample)
#' # one column: the net balance of new-high vs new-low record years
#' lap_summarise_calendar(flagged, record_balance)
#' # or several at once: each series' own magnitude, kept separate
#' lap_summarise_calendar(flagged, is_new_min, is_new_max)
lap_summarise_calendar <- function(x, ..., date = "date",
                                   period = c("month", "week")) {
  period <- rlang::arg_match(period)
  cols <- lap_eval_select(x, rlang::quo(c(...)), arg = "...")
  if (!length(cols)) {
    cli::cli_abort("{.arg ...} must select at least one column to sum.")
  }
  date_col <- lap_eval_select_one(x, rlang::enquo(date), arg = "date")

  d <- as.Date(x[[date_col]])
  if (period == "week") {
    yr <- lubridate::isoyear(d)
    unit <- lubridate::isoweek(d)
  } else {
    yr <- lubridate::year(d)
    unit <- lubridate::month(d)
  }

  agg <- x |>
    dplyr::mutate(.year = yr, .unit = unit) |>
    dplyr::group_by(.data$.year, .data$.unit) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(cols), \(v) sum(v, na.rm = TRUE)),
      .groups = "drop"
    )

  out <- do.call(rbind, lapply(cols, function(nm) {
    data.frame(
      year = agg[[".year"]], unit = agg[[".unit"]],
      name = sub("^is_", "", nm), n = agg[[nm]]
    )
  }))
  out <- out[order(out$year, out$unit, out$name), ]
  tibble::as_tibble(out)
}
