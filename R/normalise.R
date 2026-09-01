#' Normalise groundwater levels for cross-region comparison
#'
#' Absolute groundwater levels (m above sea level, or depth below ground) are
#' not comparable between wells. `lap_normalise_gwl()` adds a `gwl_norm` column
#' holding a per-well normalised series, so that dynamics rather than absolute
#' magnitude can be compared and plotted.
#'
#' Methods:
#' \describe{
#'   \item{`"range"`}{Rescale each well to `[0, 1]` using its own min/max.}
#'   \item{`"zscore"`}{Subtract each well's mean and divide by its SD.}
#'   \item{`"sgi"`}{Standardised Groundwater Index (Bloomfield & Marchant,
#'     2013): a non-parametric normal-scores transform applied within each
#'     calendar month of each well, yielding an approximately standard-normal,
#'     deseasonalised index.}
#' }
#'
#' @param x A `gwl_ts` (or data frame with `well_id`, `date`, `gwl`).
#' @param method One of `"range"`, `"zscore"`, `"sgi"`.
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the single column to
#'   normalise. Default `gwl`.
#' @param group <[`tidy-select`][dplyr::dplyr_tidy_select]> columns identifying
#'   an independent series. Default `well_id`.
#'
#' @return `x` with a `gwl_norm` column added.
#' @references Bloomfield, J. P. and Marchant, B. P. (2013). Analysis of
#'   groundwater drought building on the standardised precipitation index
#'   approach. Hydrology and Earth System Sciences, 17, 4769-4787.
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' head(lap_normalise_gwl(gems_ger_sample, "sgi"))
lap_normalise_gwl <- function(x,
                          method = c("range", "zscore", "sgi"),
                          value = gwl,
                          group = well_id) {
  method <- rlang::arg_match(method)
  value <- lap_eval_select_one(x, rlang::enquo(value), arg = "value")
  group <- lap_eval_select(x, rlang::enquo(group), arg = "group")

  v <- x[[value]]
  grp <- interaction(x[group], drop = TRUE, lex.order = TRUE)

  if (method == "sgi") {
    if (is.null(x[["date"]])) {
      cli::cli_abort("{.val sgi} needs a {.field date} column.")
    }
    month <- as.integer(format(as.Date(x[["date"]]), "%m"))
    grp <- interaction(grp, month, drop = TRUE, lex.order = TRUE)
    x[["gwl_norm"]] <- ave_by(v, grp, normal_scores)
  } else if (method == "range") {
    x[["gwl_norm"]] <- ave_by(v, grp, function(z) {
      rng <- range(z, na.rm = TRUE)
      if (diff(rng) == 0) {
        return(rep(0.5, length(z)))
      }
      (z - rng[[1]]) / diff(rng)
    })
  } else {
    x[["gwl_norm"]] <- ave_by(v, grp, function(z) {
      s <- stats::sd(z, na.rm = TRUE)
      if (is.na(s) || s == 0) {
        return(z - mean(z, na.rm = TRUE))
      }
      (z - mean(z, na.rm = TRUE)) / s
    })
  }
  x
}

# Apply f() to each group of x defined by g, returning a vector aligned to x.
ave_by <- function(x, g, f) {
  out <- x
  for (lev in levels(g)) {
    idx <- which(g == lev)
    if (length(idx)) out[idx] <- f(x[idx])
  }
  out
}

# Non-parametric normal-scores (van der Waerden) transform. NA-safe.
normal_scores <- function(z) {
  out <- rep(NA_real_, length(z))
  ok <- which(!is.na(z))
  n <- length(ok)
  if (n == 0) {
    return(out)
  }
  if (n == 1) {
    out[ok] <- 0
    return(out)
  }
  r <- rank(z[ok], ties.method = "average")
  out[ok] <- stats::qnorm(r / (n + 1))
  out
}
