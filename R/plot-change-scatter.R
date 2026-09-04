# Change-over-periods builder: is the change level-dependent?
# See docs/adr/0012 for the builder contract.

#' Starting value against its change
#'
#' A well-level scatter of an indicator's value in the `from` period (x)
#' against how much it changed by the `to` period (y), from the wide output of
#' [lap_indicator_delta()]. A tilted cloud means wells that started high
#' changed differently from wells that started low.
#'
#' `data` carries the wide `<value>_<from>` / `<value>_change` columns; `value`
#' is the **base** indicator column name (e.g. `ind_amplitude`).
#'
#' @param data The wide tibble from [lap_indicator_delta()].
#' @param value The base indicator column, as a bare name or string.
#' @param ... Passed to the underlying `scale_colour_lapidary_c()`.
#' @param smooth Add a linear `geom_smooth()` fit. Default `TRUE`.
#' @param rug Add marginal rugs.
#' @param direction,binned,robust,range Passed to the colour scale.
#' @param variant,lang,annotate,base_size,preset,title,subtitle,caption See
#'   [lap_plot_map].
#'
#' @return A [ggplot2::ggplot].
#' @seealso [lap_indicator_delta()], [lap_plot_delta_map()]
#' @export
#' @examples
#' \dontrun{
#' chg <- lap_indicator_change(
#'   gems_ger_sample, "amplitude",
#'   periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
#' )
#' dl <- lap_indicator_delta(chg, "reference", "recent")
#' lap_plot_change_scatter(dl, ind_amplitude)
#' }
lap_plot_change_scatter <- function(data, value, ...,
                                    smooth = TRUE, rug = FALSE,
                                    direction = 1, binned = TRUE,
                                    robust = getOption("lapidary.scale_robust", FALSE),
                                    range = getOption("lapidary.scale_range", FALSE),
                                    variant = lap_variant(), lang = NULL,
                                    annotate = getOption("lapidary.annotate", "caption"),
                                    base_size = NULL, preset = NULL,
                                    title = NULL, subtitle = NULL, caption = NULL) {
  rlang::check_installed("ggplot2", "for `lap_plot_change_scatter()`")
  check_table(data)
  a <- resolve_builder_args(variant, lang, base_size, preset)
  value <- rlang::as_string(rlang::ensym(value))
  dc <- resolve_delta_columns(data, value)
  if (is.na(dc$change)) delta_change_abort(value)

  base_label <- lap_prettify_label(value)
  u <- column_units(value)
  unit_sfx <- if (length(u) == 1L && !is.na(u) && nzchar(u) && u != "-") {
    paste0(" (", u, ")")
  } else {
    ""
  }
  df <- tibble::as_tibble(data)

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[[dc$from]], y = .data[[dc$change]]
  )) +
    ggplot2::geom_hline(
      yintercept = 0, colour = a$tokens$colour$grid, linewidth = 0.3
    ) +
    ggplot2::geom_point(
      ggplot2::aes(colour = .data[[dc$change]]),
      alpha = 0.85, size = 1.6, na.rm = TRUE
    ) +
    scale_colour_lapidary_c(
      "anomaly",
      binned = binned, direction = direction, midpoint = 0,
      robust = robust, range = range,
      guide = lap_coloursteps_guide(variant = a$variant), ...
    )
  if (isTRUE(smooth)) {
    p <- p + ggplot2::geom_smooth(
      method = "lm", formula = y ~ x, se = FALSE,
      colour = a$tokens$colour$ink_muted, linewidth = 0.6, na.rm = TRUE
    )
  }
  if (isTRUE(rug)) {
    p <- p + ggplot2::geom_rug(
      alpha = 0.25, colour = a$tokens$colour$ink_muted, na.rm = TRUE
    )
  }

  p <- p +
    ggplot2::labs(
      x = paste0(base_label, ", ", dc$labels[[1]], unit_sfx),
      y = paste0(base_label, ", change", unit_sfx),
      colour = paste0(base_label, " \u0394"),
      title = title, subtitle = subtitle, caption = caption
    ) +
    theme_lapidary(a$variant, base_size = a$base_size, panel = "xy")

  apply_howto(p, annotate, "change_scatter", a$lang, a$variant, a$tokens)
}
