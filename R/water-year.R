#' Add hydrological (water) year and month columns
#'
#' The hydrological year in Germany conventionally starts on 1 November. This
#' helper adds a `water_year` integer column (the calendar year in which the
#' hydrological year *ends*) and a `water_month` column (1 = first month of the
#' hydrological year).
#'
#' @param x A `gwl_ts` (or any data frame with a date column).
#' @param start_month Integer 1-12, the calendar month the hydrological year
#'   begins. Defaults to `11` (November).
#' @param date_col <[`tidy-select`][dplyr::dplyr_tidy_select]> the date column
#'   (bare name or string). Defaults to `date`.
#'
#' @return `x` with `water_year` and `water_month` columns added.
#' @export
#' @examples
#' df <- data.frame(date = as.Date(c("2019-10-15", "2019-11-15", "2020-05-15")))
#' lap_use_water_year(df)
lap_use_water_year <- function(x, start_month = 11L, date_col = date) {
  date_col <- lap_eval_select_one(x, rlang::enquo(date_col), arg = "date_col")
  start_month <- as.integer(start_month)
  if (length(start_month) != 1 || is.na(start_month) ||
    start_month < 1 || start_month > 12) {
    cli::cli_abort("{.arg start_month} must be a single integer in 1:12.")
  }
  d <- as.Date(x[[date_col]])
  cal_year <- as.integer(format(d, "%Y"))
  cal_month <- as.integer(format(d, "%m"))
  # water_year is the calendar year in which the hydrological year ends. With
  # start_month == 1 the hydrological year coincides with the calendar year.
  x[["water_year"]] <- ifelse(
    start_month != 1L & cal_month >= start_month,
    cal_year + 1L, cal_year
  )
  x[["water_month"]] <- ((cal_month - start_month) %% 12L) + 1L
  x
}
