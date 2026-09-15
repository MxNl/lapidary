# Per-well annual-record detection ---------------------------------------

#' Flag new all-time annual low / high records
#'
#' Tags, for each well, the single timestep of each calendar year that is
#' that year's minimum / maximum - but only when that annual extreme is
#' itself a new all-time record for the well, beating every *prior* year's
#' annual extreme. A well can set at most one new-low and one new-high record
#' per year (possibly both, possibly neither); every other row is `FALSE`.
#' Aggregate the flags across wells (see [lap_summarise_calendar()]) to see
#' whether record-setting years cluster in particular periods.
#'
#' A well's first year is not evaluated for records at all: there is no real
#' prior year to compare against, so flagging its own annual min/max would
#' either look like a genuine record (misleading) or, left `FALSE`, look
#' identical to a genuine non-record year (also misleading - indistinguishable
#' from "no baseline yet"). Its `into_min` / `into_max` / `into_balance` are
#' `NA` instead for every row of that year, and [lap_summarise_calendar()]
#' excludes (does not zero-fill) `NA` contributions - so a well's first year
#' produces no tile at all in a [lap_plot_calendar()] grid, rather than a
#' misleading blank/neutral one. The first year's own min/max still silently
#' seed the running record that its second year is compared against.
#' Ties are not records - a year's annual extreme equal to the running record
#' neither sets nor breaks it, mirroring the usual "record broken" vs "record
#' tied" distinction. If a year's own annual extreme is tied across more than
#' one timestep, only the first chronologically is flagged, so a well never
#' gets more than one `TRUE` per year per direction. `NA` values are excluded
#' from a year's min/max; a well-year with only `NA` values contributes
#' nothing (neither sets a record nor updates the running one).
#'
#' This has no correction for two things that can confound a "records over
#' time" comparison: a well added to the network later shows an elevated
#' record rate in its own early years purely for lacking a long baseline, and
#' a growing monitoring network means more wells are at risk of setting a
#' record in later years than in earlier ones. Feed a dataset with a stable
#' set of wells over the period you are comparing if that matters for your
#' conclusion; this function does not do it for you.
#'
#' @param x A `gwl_ts` (or data frame with `well_id`, `date`, `gwl`).
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the column to
#'   evaluate. Default `gwl`.
#' @param group <[`tidy-select`][dplyr::dplyr_tidy_select]> columns identifying
#'   an independent series. Default `well_id`.
#' @param date <[`tidy-select`][dplyr::dplyr_tidy_select]> the date column,
#'   used to derive the calendar year and to order each group chronologically.
#'   Default `date`.
#' @param into_min,into_max,into_balance Names of the columns to add. Default
#'   `"is_new_min"` / `"is_new_max"` / `"record_balance"`. `record_balance` is
#'   `into_max - into_min` as an integer (`+1` on a new-high row, `-1` on a
#'   new-low row, `0` everywhere else) - summing it in
#'   [lap_summarise_calendar()] gives the *net* balance of highs vs lows per
#'   bucket directly (summation is linear, so this is identical to summing
#'   the two flags separately and subtracting), letting [lap_plot_calendar()]
#'   draw one divergent panel instead of two separate ones.
#'
#' @return `x` with the `into_min` / `into_max` logical columns and the
#'   `into_balance` integer column added.
#' @seealso [lap_summarise_calendar()], [lap_plot_calendar()]
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' head(lap_add_record_flags(gems_ger_sample))
lap_add_record_flags <- function(x,
                             value = gwl,
                             group = well_id,
                             date = "date",
                             into_min = NULL,
                             into_max = NULL,
                             into_balance = NULL) {
  value <- lap_eval_select_one(x, rlang::enquo(value), arg = "value")
  group <- lap_eval_select(x, rlang::enquo(group), arg = "group")
  date <- lap_eval_select_one(x, rlang::enquo(date), arg = "date")
  into_min <- into_min %||% "is_new_min"
  into_max <- into_max %||% "is_new_max"
  into_balance <- into_balance %||% "record_balance"

  v <- x[[value]]
  d <- as.Date(x[[date]])
  yr <- lubridate::year(d)
  grp <- interaction(x[group], drop = TRUE, lex.order = TRUE)

  is_min <- logical(length(v))
  is_max <- logical(length(v))
  for (lev in levels(grp)) {
    idx <- which(grp == lev)
    ord <- idx[order(d[idx])]
    z <- v[ord]
    y <- yr[ord]

    min_flag <- logical(length(z))
    max_flag <- logical(length(z))
    running_min <- NA_real_
    running_max <- NA_real_

    ok <- !is.na(z)
    years <- sort(unique(y[ok]))
    for (this_year in years) {
      rows <- which(y == this_year & ok) # chronologically ordered already
      year_min <- min(z[rows])
      year_max <- max(z[rows])
      if (is.na(running_min)) {
        # first year for this well: nothing prior to compare against - not a
        # real record either way, and leaving it FALSE would look identical
        # to a genuine non-record year, so mark it NA instead (see
        # lap_summarise_calendar(), which excludes rather than zero-fills NA)
        min_flag[rows] <- NA
        max_flag[rows] <- NA
      } else {
        if (year_min < running_min) min_flag[rows[which.min(z[rows])]] <- TRUE
        if (year_max > running_max) max_flag[rows[which.max(z[rows])]] <- TRUE
      }
      running_min <- if (is.na(running_min)) year_min else min(running_min, year_min)
      running_max <- if (is.na(running_max)) year_max else max(running_max, year_max)
    }
    is_min[ord] <- min_flag
    is_max[ord] <- max_flag
  }

  x[[into_min]] <- is_min
  x[[into_max]] <- is_max
  x[[into_balance]] <- as.integer(is_max) - as.integer(is_min)
  x
}
