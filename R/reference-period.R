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

validate_periods <- function(periods, call = rlang::caller_env()) {
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
  # Overlap check.
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
  periods
}
