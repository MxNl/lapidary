# Change-over-periods builder: one indicator's distribution, period by period.
# See docs/adr/0012 for the builder contract.

#' Stacked period distributions (ridgelines)
#'
#' Takes the long output of [lap_indicator_change()] (`by` column(s), an
#' ordered `period` factor, and `ind_*` columns) and draws one density ridge
#' per period, stacked earliest-on-top so reading down the plot follows time.
#' Each ridge is filled with the continuous lapidary palette along the value
#' axis (as the maps and [lap_plot_distribution()] are), outlined in the
#' background colour so overlapping ridges stay legible.
#'
#' Needs \pkg{ggridges}.
#'
#' @param data The long tibble from [lap_indicator_change()].
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the `ind_*` column
#'   to plot.
#' @param ... Passed to the underlying `scale_fill_lapidary_c()`.
#' @param overlap Ridge overlap, passed to `ggridges` as `scale`: `1` makes the
#'   tallest ridge just reach the next baseline; the default `1.4` overlaps the
#'   ridges (the background-colour outline keeps them readable), `> 2` is a
#'   dense "Joy Division" stack.
#' @param interpret For the common indicators, label the value axis with what a
#'   low vs a high value means (`"<low>  <-  Indicator  ->  <high>"`). `TRUE` by
#'   default; has no effect for a column without a stored interpretation.
#'   `low_label` / `high_label` set or override the wording for any column.
#' @param low_label,high_label Words for the low / high end of the value axis.
#'   Both must resolve (from here or the registry) for the directional label to
#'   appear.
#' @param role,direction,robust,range Passed to the fill scale.
#' @param variant,lang,annotate,base_size,preset,title,subtitle,caption See
#'   [lap_plot_map].
#'
#' @return A [ggplot2::ggplot].
#' @seealso [lap_indicator_change()], [lap_plot_delta_map()],
#'   [lap_plot_distribution()]
#' @export
#' @examples
#' \dontrun{
#' chg <- lap_indicator_change(
#'   gems_ger_sample, "amplitude",
#'   periods = lap_period_windows(gems_ger_sample, "decade_per_decade")
#' )
#' lap_plot_period_ridges(chg, ind_amplitude)
#' lap_plot_period_ridges(chg, ind_trend_slope,
#'   low_label = "falling levels", high_label = "rising levels"
#' )
#' }
lap_plot_period_ridges <- function(data, value, ...,
                                   overlap = 1.4,
                                   interpret = TRUE,
                                   low_label = NULL, high_label = NULL,
                                   role = "magnitude", direction = 1,
                                   robust = getOption("lapidary.scale_robust", FALSE),
                                   range = getOption("lapidary.scale_range", FALSE),
                                   variant = lap_variant(), lang = NULL,
                                   annotate = getOption("lapidary.annotate", "caption"),
                                   base_size = NULL, preset = NULL,
                                   title = NULL, subtitle = NULL, caption = NULL) {
  rlang::check_installed("ggplot2", "for `lap_plot_period_ridges()`")
  check_table(data)
  if (!"period" %in% names(data)) {
    cli::cli_abort(c(
      "{.arg data} needs a {.field period} column.",
      i = "Use the long output of {.fn lap_indicator_change}."
    ))
  }
  a <- resolve_builder_args(variant, lang, base_size, preset)
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  rlang::check_installed("ggridges", "for `lap_plot_period_ridges()`")

  df <- data.frame(
    .period = as.character(data[["period"]]),
    .value = data[[value]]
  )
  df <- df[is.finite(df[[".value"]]), , drop = FALSE]
  chrono <- levels(as.factor(data[["period"]]))
  keep <- chrono[vapply(
    chrono, function(p) sum(df[[".period"]] == p) >= 2L, logical(1)
  )]
  if (!length(keep)) {
    cli::cli_abort("No period has 2 or more finite {.field {value}} values to plot.")
  }
  df <- df[df[[".period"]] %in% keep, , drop = FALSE]
  df[[".period"]] <- factor(df[[".period"]], levels = rev(keep))

  # Replicate ggridges' joint-bandwidth pick so it doesn't `message()` about it.
  bws <- vapply(split(df[[".value"]], df[[".period"]]), function(v) {
    if (length(v) > 1L) stats::bw.nrd0(v) else NA_real_
  }, numeric(1))
  bw <- mean(bws, na.rm = TRUE)
  if (!isTRUE(is.finite(bw) && bw > 0)) bw <- NULL

  # ggridges scales every ridge to the panel's tallest, so the top row rises
  # `overlap * (its peak / the tallest peak)` above its baseline. Size the top
  # expansion to that, not to a loose `overlap` upper bound, or an empty band
  # of gridlines sits above the top ridge.
  peak <- vapply(split(df[[".value"]], df[[".period"]]), function(v) {
    d <- if (is.null(bw)) stats::density(v) else stats::density(v, bw = bw)
    max(d$y)
  }, numeric(1))
  top_head <- overlap * (peak[[length(peak)]] / max(peak)) + 0.2

  reg <- indicator_interpretation(value, a$lang)
  lo <- low_label %||% (if (isTRUE(interpret)) reg[["low"]] else NULL)
  hi <- high_label %||% (if (isTRUE(interpret)) reg[["high"]] else NULL)
  x_lab <- if (!is.null(lo) && !is.null(hi) && nzchar(lo) && nzchar(hi)) {
    paste0(lo, "  \u2190   ", lap_axis_label(value), "   \u2192  ", hi)
  } else {
    lap_axis_label(value)
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data$.value, y = .data$.period,
    fill = ggplot2::after_stat(.data$x)
  )) +
    ggridges::geom_density_ridges_gradient(
      scale = overlap, rel_min_height = 0.02, bandwidth = bw,
      colour = a$tokens$colour$background, linewidth = 0.4,
      gradient_lwd = 0.8, na.rm = TRUE
    ) +
    scale_fill_lapidary_c(
      role,
      binned = FALSE, direction = direction, robust = robust, range = range,
      guide = "none", ...
    ) +
    ggplot2::scale_y_discrete(
      expand = ggplot2::expansion(add = c(0.3, top_head))
    ) +
    ggplot2::labs(
      x = x_lab, y = NULL,
      title = title, subtitle = subtitle, caption = caption
    ) +
    theme_lapidary(a$variant, base_size = a$base_size, panel = "ridge")

  apply_howto(p, annotate, "period_ridges", a$lang, a$variant, a$tokens)
}
