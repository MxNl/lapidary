#' Non-parametric trend of groundwater time series
#'
#' Computes the Theil-Sen slope estimator together with the Mann-Kendall trend
#' test (with tie correction) for each series. This non-parametric pairing is a
#' standard choice for hydrological trend analysis: robust to outliers and
#' making no assumption of normal residuals.
#'
#' Input is typically an annual series - e.g. the `mean_gwl` column of
#' [lap_summarise_wells()] grouped by `c(well_id, year)` - but any regular-ish
#' series works.
#'
#' @param x A data frame with a time column, a value column and grouping
#'   column(s).
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the single value
#'   column. Default `mean_gwl`.
#' @param time <[`tidy-select`][dplyr::dplyr_tidy_select]> the single time
#'   column (numeric years, or Date). Default `year`.
#' @param by <[`tidy-select`][dplyr::dplyr_tidy_select]> grouping column(s).
#'   Default `well_id`.
#' @param min_n Minimum number of finite observations required per group.
#' @param conf_level Confidence level for the slope confidence interval.
#'
#' @return A tibble with one row per group: `n`, `slope` (value units per year),
#'   `slope_lower`, `slope_upper`, `intercept`, `tau`, `p_value`,
#'   `significant` (logical at `1 - conf_level`), `direction`.
#' @export
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   well_id = rep(c("a", "b"), each = 30),
#'   year = rep(1991:2020, 2),
#'   mean_gwl = c(
#'     50 - 0.1 * (0:29) + rnorm(30, 0, 0.2),
#'     20 + rnorm(30, 0, 0.2)
#'   )
#' )
#' lap_gw_trend(df)
lap_gw_trend <- function(x,
                     value = mean_gwl,
                     time = year,
                     by = well_id,
                     min_n = 10L,
                     conf_level = 0.95) {
  value <- lap_eval_select_one(x, rlang::enquo(value), arg = "value")
  time <- lap_eval_select_one(x, rlang::enquo(time), arg = "time")
  by <- lap_eval_select(x, rlang::enquo(by), arg = "by")
  x <- tibble::as_tibble(x)
  grp <- interaction(x[by], drop = TRUE, lex.order = TRUE)
  splits <- split(x, grp)
  rows <- lapply(splits, function(part) {
    tt <- part[[time]]
    if (inherits(tt, "Date")) {
      tt <- as.numeric(format(tt, "%Y")) +
        (as.numeric(tt - as.Date(paste0(format(tt, "%Y"), "-01-01"))) / 365.25)
    }
    tt <- as.numeric(tt)
    vv <- as.numeric(part[[value]])
    ok <- is.finite(tt) & is.finite(vv)
    tt <- tt[ok]
    vv <- vv[ok]
    key <- part[1, by, drop = FALSE]
    if (length(vv) < min_n) {
      return(cbind(key, trend_na_row()))
    }
    ord <- order(tt)
    res <- theil_sen_mann_kendall(tt[ord], vv[ord], conf_level = conf_level)
    cbind(key, as.data.frame(res))
  })
  out <- tibble::as_tibble(do.call(rbind, rows))
  out[["direction"]] <- ifelse(is.na(out[["slope"]]), NA_character_,
    ifelse(out[["slope"]] > 0, "increasing",
      ifelse(out[["slope"]] < 0, "decreasing", "none")
    )
  )
  rownames(out) <- NULL
  out
}

trend_na_row <- function() {
  data.frame(
    n = NA_integer_, slope = NA_real_, slope_lower = NA_real_,
    slope_upper = NA_real_, intercept = NA_real_, tau = NA_real_,
    p_value = NA_real_, significant = NA
  )
}

# Core estimator. Assumes x sorted ascending, no NAs.
theil_sen_mann_kendall <- function(x, y, conf_level = 0.95) {
  n <- length(y)
  # Pairwise slopes (Theil-Sen).
  idx <- utils::combn(n, 2)
  dx <- x[idx[2, ]] - x[idx[1, ]]
  dy <- y[idx[2, ]] - y[idx[1, ]]
  keep <- dx != 0
  slopes <- (dy[keep] / dx[keep])
  slope <- stats::median(slopes, na.rm = TRUE)
  intercept <- stats::median(y - slope * x, na.rm = TRUE)

  # Mann-Kendall S and variance with tie correction.
  s <- sum(sign(dy))
  ties_y <- table(y)
  ties_x <- table(x)
  var_s <- (n * (n - 1) * (2 * n + 5) -
    sum(ties_y * (ties_y - 1) * (2 * ties_y + 5)) -
    sum(ties_x * (ties_x - 1) * (2 * ties_x + 5))) / 18
  z <- if (s > 0) {
    (s - 1) / sqrt(var_s)
  } else if (s < 0) {
    (s + 1) / sqrt(var_s)
  } else {
    0
  }
  p_value <- 2 * stats::pnorm(-abs(z))
  tau <- s / (0.5 * n * (n - 1))

  # Confidence interval on the slope (Sen 1968).
  c_alpha <- stats::qnorm(1 - (1 - conf_level) / 2) * sqrt(var_s)
  m <- length(slopes)
  sorted <- sort(slopes)
  lower_rank <- floor((m - c_alpha) / 2)
  upper_rank <- ceiling((m + c_alpha) / 2) + 1
  slope_lower <- if (lower_rank >= 1 && lower_rank <= m) sorted[lower_rank] else NA_real_
  slope_upper <- if (upper_rank >= 1 && upper_rank <= m) sorted[upper_rank] else NA_real_

  list(
    n = n, slope = slope, slope_lower = slope_lower, slope_upper = slope_upper,
    intercept = intercept, tau = tau, p_value = p_value,
    significant = isTRUE(p_value < (1 - conf_level))
  )
}
