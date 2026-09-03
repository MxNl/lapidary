#' Standard climate reference periods
#'
#' Named list of `c(start_year, end_year)` pairs. `Z1` (1991-2020) is the
#' current WMO climate normal; `Z0` (1961-1990) is the previous one, and
#' `Z2` (2021-2050) / `Z3` (2071-2100) are the near- and far-future slices
#' commonly used in climate-projection work.
#'
#' @return A named list of length-2 integer vectors.
#' @export
#' @examples
#' lap_reference_periods()
lap_reference_periods <- function() {
  list(
    Z0 = c(1961L, 1990L),
    Z1 = c(1991L, 2020L),
    Z2 = c(2021L, 2050L),
    Z3 = c(2071L, 2100L)
  )
}

#' Derive comparison windows from a record's date range
#'
#' Builds a named `periods` list (the shape [lap_indicator_change()] and
#' [lap_add_reference_period()] expect) from the span of a groundwater record,
#' so you do not have to write year pairs by hand. Unlike
#' [lap_reference_periods()] (fixed WMO climate normals), these windows adapt to
#' the data.
#'
#' @param x A data frame with a date column, or a length-2 numeric vector
#'   `c(first_year, last_year)`.
#' @param scheme One of:
#'   \itemize{
#'     \item `"first_vs_last_decade"` - the first and last `width` years;
#'     \item `"first_vs_last_half"` - the record split at its midpoint;
#'     \item `"decade_per_decade"` - one window per 10-year block from the first
#'       year of the record, the last block clipped to the end. Names are the
#'       actual spans, e.g. `"1991-2000"`.
#'   }
#' @param date <[`tidy-select`][dplyr::dplyr_tidy_select]> the date column used
#'   to derive the year range when `x` is a data frame. Default `date`.
#' @param width Window length in years for `"first_vs_last_decade"`. Default 10.
#'
#' @return A named list of `c(start_year, end_year)` integer pairs in
#'   chronological order (`first` before `last`), validated for
#'   [lap_indicator_change()] (overlaps allowed).
#'
#' @details `"decade_per_decade"` can return more than two windows; pass any two
#'   of its labels to [lap_indicator_delta()]. The non-overlapping schemes
#'   (`"first_vs_last_half"` and `"decade_per_decade"`) also work as the
#'   `periods` argument of [lap_add_reference_period()].
#'
#' @seealso [lap_reference_periods()], [lap_indicator_change()],
#'   [lap_add_reference_period()]
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' lap_period_windows(gems_ger_sample, "first_vs_last_decade")
#' lap_period_windows(c(1991, 2022), "decade_per_decade")
#' lap_indicator_change(
#'   gems_ger_sample, c("amplitude", "trend"),
#'   periods = lap_period_windows(gems_ger_sample, "first_vs_last_half")
#' )
lap_period_windows <- function(x,
                               scheme = c(
                                 "first_vs_last_decade",
                                 "first_vs_last_half",
                                 "decade_per_decade"
                               ),
                               date = "date",
                               width = 10L) {
  scheme <- rlang::arg_match(scheme)
  yr <- period_window_year_range(x, rlang::enquo(date))
  y0 <- yr[[1]]
  y1 <- yr[[2]]

  periods <- switch(scheme,
    first_vs_last_decade = {
      w <- as.integer(width)
      if (length(w) != 1L || is.na(w) || w < 1L) {
        cli::cli_abort("{.arg width} must be a positive number of years.")
      }
      if (y1 - y0 + 1L < 2L * w) {
        cli::cli_inform(c(
          i = "Record spans {y1 - y0 + 1L} yr; {.val first} and {.val last} \\
               windows overlap."
        ))
      }
      list(first = c(y0, y0 + w - 1L), last = c(y1 - w + 1L, y1))
    },
    first_vs_last_half = {
      mid <- (y0 + y1) %/% 2L
      list(first = c(y0, mid), last = c(mid + 1L, y1))
    },
    decade_per_decade = {
      starts <- seq(y0, y1, by = 10L)
      wins <- lapply(starts, function(s) c(s, min(s + 9L, y1)))
      nm <- vapply(wins, function(w) paste(w[[1]], w[[2]], sep = "-"), character(1))
      stats::setNames(wins, nm)
    }
  )
  validate_periods(periods, allow_overlap = TRUE)
}

# c(first_year, last_year) from a data frame's date column, or a length-2
# numeric vector passed straight through.
period_window_year_range <- function(x, date_quo, call = rlang::caller_env()) {
  if (is.numeric(x) && !is.data.frame(x)) {
    if (length(x) != 2L || anyNA(x) || x[[1]] > x[[2]]) {
      cli::cli_abort(
        "A numeric {.arg x} must be {.code c(first_year, last_year)} with first <= last.",
        call = call
      )
    }
    return(as.integer(x))
  }
  date_col <- lap_eval_select_one(x, date_quo, arg = "date", call = call)
  yr <- as.integer(format(as.Date(x[[date_col]]), "%Y"))
  yr <- yr[!is.na(yr)]
  if (!length(yr)) {
    cli::cli_abort(
      "{.arg date} column {.val {date_col}} has no non-missing years.",
      call = call
    )
  }
  range(yr)
}

#' Tag rows with a reference-period label
#'
#' Adds a `reference_period` column marking which configured period each
#' observation falls into (by calendar year of `date_col`, or by `year_col`
#' if supplied). Rows outside every period get `NA`. Periods must not overlap.
#'
#' @param x A `gwl_ts` or data frame.
#' @param periods Named list of `c(start_year, end_year)` pairs. Defaults to
#'   `lap_reference_periods()["Z1"]`.
#' @param date_col <[`tidy-select`][dplyr::dplyr_tidy_select]> date column to
#'   derive the year from (bare name or string). Ignored if `year_col` is given.
#'   Defaults to `date`.
#' @param year_col <[`tidy-select`][dplyr::dplyr_tidy_select]> optional integer
#'   year column to use directly instead of `date_col`.
#' @param drop If `TRUE`, keep only rows that fall inside a period.
#'
#' @return `x` with a `reference_period` factor column (levels = `names(periods)`).
#' @export
#' @examples
#' df <- data.frame(date = as.Date(paste0(1985:1995, "-06-15")))
#' lap_add_reference_period(df)
#' lap_add_reference_period(df, periods = lap_reference_periods()[c("Z0", "Z1")], drop = TRUE)
lap_add_reference_period <- function(x,
                                 periods = lap_reference_periods()["Z1"],
                                 date_col = date,
                                 year_col = NULL,
                                 drop = FALSE) {
  periods <- validate_periods(periods)
  year_col <- lap_eval_select_one(x, rlang::enquo(year_col), arg = "year_col", null_ok = TRUE)
  if (!is.null(year_col)) {
    year <- as.integer(x[[year_col]])
  } else {
    date_col <- lap_eval_select_one(x, rlang::enquo(date_col), arg = "date_col")
    year <- as.integer(format(as.Date(x[[date_col]]), "%Y"))
  }
  label <- rep(NA_character_, length(year))
  for (nm in names(periods)) {
    rng <- periods[[nm]]
    hit <- !is.na(year) & year >= rng[[1]] & year <= rng[[2]]
    label[hit] <- nm
  }
  x[["reference_period"]] <- factor(label, levels = names(periods))
  if (drop) {
    x <- x[!is.na(x[["reference_period"]]), , drop = FALSE]
  }
  x
}

validate_periods <- function(periods, allow_overlap = FALSE,
                             call = rlang::caller_env()) {
  if (!is.list(periods) || is.null(names(periods)) || any(!nzchar(names(periods)))) {
    cli::cli_abort("{.arg periods} must be a fully named list.", call = call)
  }
  periods <- lapply(periods, function(p) {
    p <- as.integer(p)
    if (length(p) != 2 || anyNA(p) || p[[1]] > p[[2]]) {
      cli::cli_abort(
        "Each period must be {.code c(start_year, end_year)} with start <= end.",
        call = call
      )
    }
    p
  })
  if (!allow_overlap) {
    ord <- order(vapply(periods, `[[`, integer(1), 1))
    sorted <- periods[ord]
    for (i in seq_len(length(sorted) - 1)) {
      if (sorted[[i]][[2]] >= sorted[[i + 1]][[1]]) {
        cli::cli_abort(c(
          "Reference periods must not overlap.",
          x = "{.val {names(sorted)[i]}} and {.val {names(sorted)[i + 1]}} overlap."
        ), call = call)
      }
    }
  }
  periods
}
