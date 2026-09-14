# Per-well percentile-band classification ("Grundwasserstandsklassen") -----

#' Classify groundwater levels into per-well percentile bands
#'
#' Tags every row with which percentile band of *that well's own* distribution
#' it falls into - the German hydrological-service groundwater-level
#' classification ("Grundwasserstandsklassen") used in weekly LfU / BGR / HLNUG
#' bulletins: very low / low / below normal / normal / above normal / high /
#' very high, split at the 5th, 10th, 25th, 75th, 90th and 95th percentile.
#'
#' The breakpoints are computed independently for each well (a well's own
#' history is the yardstick for what counts as "normal" for it), then every
#' row of that well is classified against them - so the result is comparable
#' across wells with very different absolute levels.
#'
#' @param x A `gwl_ts` (or data frame with `well_id`, `date`, `gwl`).
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the column to
#'   classify. Default `gwl`.
#' @param group <[`tidy-select`][dplyr::dplyr_tidy_select]> columns identifying
#'   an independent series (breakpoints are computed once per group). Default
#'   `well_id`.
#' @param date <[`tidy-select`][dplyr::dplyr_tidy_select]> the date column,
#'   used only when `reference` is given. Default `date`.
#' @param breaks Percentile cut points, `[0, 1]`, increasing. Default
#'   `c(0, .05, .10, .25, .75, .90, .95, 1)` (7 bands).
#' @param labels Band labels, one shorter than `breaks`. `NULL` (default) uses
#'   the built-in bilingual `gwl_class_labels` (see `lang`); pass your own
#'   7-vector to override.
#' @param lang Language for the default `labels`; defaults to [lap_lang()].
#'   Ignored if `labels` is given.
#' @param reference `NULL` (default) computes breakpoints from a well's whole
#'   record. Or `c(start_year, end_year)` (or a single named period, e.g.
#'   `lap_reference_periods()["Z1"]`): breakpoints are computed from only the
#'   rows in that window, then *every* row (in or out of it) is classified
#'   against them - a fixed "normal" the way a climate normal works.
#' @param into Name of the column to add. Default `"<value>_class"`.
#'
#' @return `x` with the `into` column added: an ordered factor, levels from
#'   low to high. A group whose reference values are all identical (nothing to
#'   split into bands) gets `NA` for every row, with a warning.
#' @references Bloomfield, J. P. and Marchant, B. P. (2013) as for
#'   [lap_normalise_gwl()]; the band scheme follows the German state
#'   groundwater services' weekly bulletin convention (e.g. Bayerisches
#'   Landesamt fuer Umwelt, "Grundwasserstandsklassen").
#' @seealso [lap_summarise_composition()], [lap_plot_stream()]
#' @export
#' @examples
#' data(gems_ger_sample, package = "lapidary", envir = environment())
#' head(lap_add_quantile_class(gems_ger_sample))
lap_add_quantile_class <- function(x,
                               value = gwl,
                               group = well_id,
                               date = "date",
                               breaks = c(0, .05, .10, .25, .75, .90, .95, 1),
                               labels = NULL,
                               lang = NULL,
                               reference = NULL,
                               into = NULL) {
  value <- lap_eval_select_one(x, rlang::enquo(value), arg = "value")
  group <- lap_eval_select(x, rlang::enquo(group), arg = "group")
  into <- into %||% paste0(value, "_class")
  labels <- labels %||% lap_tr("gwl_class_labels", lang)
  if (length(labels) != length(breaks) - 1L) {
    cli::cli_abort("{.arg labels} must have one fewer element than {.arg breaks}.")
  }
  ref_years <- resolve_reference_years(reference)

  v <- x[[value]]
  yr <- if (is.null(ref_years)) {
    NULL
  } else {
    date <- lap_eval_select_one(x, rlang::enquo(date), arg = "date")
    as.integer(format(as.Date(x[[date]]), "%Y"))
  }
  grp <- interaction(x[group], drop = TRUE, lex.order = TRUE)

  codes <- rep(NA_integer_, length(v))
  degenerate <- character(0)
  for (lev in levels(grp)) {
    idx <- which(grp == lev)
    z <- v[idx]
    z_ref <- if (is.null(yr)) {
      z
    } else {
      z[yr[idx] >= ref_years[[1]] & yr[idx] <= ref_years[[2]]]
    }
    rng <- range(z_ref, na.rm = TRUE)
    if (!is.finite(diff(rng)) || diff(rng) == 0) {
      degenerate <- c(degenerate, lev)
      next
    }
    qs <- stats::quantile(z_ref, probs = breaks, type = 7, na.rm = TRUE)
    # open-ended tails: a value outside the reference window's observed range
    # is still "very low" / "very high", not unclassifiable
    if (breaks[[1]] == 0) qs[[1]] <- -Inf
    if (breaks[[length(breaks)]] == 1) qs[[length(qs)]] <- Inf
    qs <- strictly_increasing(qs)
    codes[idx] <- as.integer(cut(z, breaks = qs, include.lowest = TRUE, labels = FALSE))
  }
  if (length(degenerate)) {
    cli::cli_warn(c(
      "{cli::qty(length(degenerate))}{.field {group}} group{?s} \\
       {.val {degenerate}} {?has/have} no spread in {.arg value} \\
       (over the reference window) and {?is/are} left {.val NA}.",
      i = "Nothing to split into bands when every value is the same."
    ))
  }
  x[[into]] <- factor(codes, levels = seq_along(labels), labels = labels, ordered = TRUE)
  x
}

# Nudge any non-increasing adjacent breakpoints strictly upward (ties happen
# with discretised / rounded data) so cut() always returns length(qs) - 1
# bands, keeping codes aligned to `labels` regardless of ties.
strictly_increasing <- function(qs) {
  for (i in seq_along(qs)[-1]) {
    if (qs[[i]] <= qs[[i - 1L]]) {
      qs[[i]] <- qs[[i - 1L]] + .Machine$double.eps * max(1, abs(qs[[i - 1L]]))
    }
  }
  qs
}

# c(start_year, end_year) from a length-2 vector or a single named period
# (e.g. lap_reference_periods()["Z1"]); NULL passes through.
resolve_reference_years <- function(reference, call = rlang::caller_env()) {
  if (is.null(reference)) {
    return(NULL)
  }
  if (is.list(reference)) {
    reference <- reference[[1]]
  }
  reference <- as.integer(reference)
  if (length(reference) != 2L || anyNA(reference) || reference[[1]] > reference[[2]]) {
    cli::cli_abort(
      "{.arg reference} must be {.code c(start_year, end_year)} (or a single named period).",
      call = call
    )
  }
  reference
}
