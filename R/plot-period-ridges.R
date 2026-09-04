# Change-over-periods builder: one indicator's distribution, period by period.
# See docs/adr/0012 for the builder contract.

#' Stacked period distributions (ridgelines)
#'
#' Takes the long output of [lap_indicator_change()] (`by` column(s), an
#' ordered `period` factor, and `ind_*` columns) and draws one density ridge
#' per period, stacked, so you can see a distribution shift as the periods
#' advance. Each ridge is filled by its median value on the map palette.
#'
#' @param data The long tibble from [lap_indicator_change()].
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the `ind_*` column
#'   to plot.
#' @param ... Passed to the underlying `scale_fill_lapidary_c()`.
#' @param height Ridge height as a multiple of the row spacing. Default 1.6
#'   (ridges overlap a little).
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
#'   periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
#' )
#' lap_plot_period_ridges(chg, ind_amplitude)
#' }
lap_plot_period_ridges <- function(data, value, ...,
                                   height = 1.6,
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

  periods <- levels(as.factor(data[["period"]]))
  ridges <- lapply(seq_along(periods), function(i) {
    v <- data[[value]][as.character(data[["period"]]) == periods[[i]]]
    v <- v[is.finite(v)]
    if (length(v) < 2L) {
      return(NULL)
    }
    d <- stats::density(v)
    tibble::tibble(
      period = periods[[i]], row = i - 1L,
      x = d$x, dens = d$y, med = stats::median(v)
    )
  })
  ridges <- dplyr::bind_rows(ridges)
  if (!nrow(ridges)) {
    cli::cli_abort("No period has 2 or more finite {.field {value}} values to plot.")
  }
  ridges[["ymax"]] <- ridges[["row"]] +
    ridges[["dens"]] / max(ridges[["dens"]]) * height

  p <- ggplot2::ggplot(ridges, ggplot2::aes(x = .data$x, group = .data$period)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$row, ymax = .data$ymax, fill = .data$med),
      colour = a$tokens$colour$ink_muted, linewidth = 0.3
    ) +
    scale_fill_lapidary_c(
      role,
      binned = FALSE, direction = direction, robust = robust, range = range,
      guide = "none", ...
    ) +
    ggplot2::scale_y_continuous(
      breaks = seq_along(periods) - 1L, labels = periods,
      expand = ggplot2::expansion(mult = c(0.02, 0), add = c(0, height + 0.5))
    ) +
    ggplot2::labs(
      x = lap_axis_label(value), y = NULL,
      title = title, subtitle = subtitle, caption = caption
    ) +
    theme_lapidary(a$variant, base_size = a$base_size, panel = "ridge")

  apply_howto(p, annotate, "period_ridges", a$lang, a$variant, a$tokens)
}
