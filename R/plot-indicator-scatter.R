# Status-quo builder: one indicator against another (well-level scatter).
# See docs/adr/0012 for the builder contract.

#' Two indicators against each other
#'
#' A well-level scatter of `x` vs `y` (columns from [lap_indicators()] /
#' [lap_summarise_wells()]), optionally coloured by a third indicator on the
#' lapidary palette. Axis labels carry the catalogue unit.
#'
#' @param data A plain data frame with the `x` / `y` (/ `colour`) columns.
#' @param x,y <[`tidy-select`][dplyr::dplyr_tidy_select]> the columns for the
#'   two axes.
#' @param colour <[`tidy-select`][dplyr::dplyr_tidy_select]> optional third
#'   column to colour points by.
#' @param ... Passed to the underlying `scale_colour_lapidary_c()` (only used
#'   when `colour` is given).
#' @param smooth Add a linear `geom_smooth()` fit.
#' @param rug Add marginal rugs.
#' @param role,direction,robust,range Passed to the colour scale.
#' @param variant,lang,annotate,base_size,preset,title,subtitle,caption See
#'   [lap_plot_map].
#'
#' @return A [ggplot2::ggplot].
#' @seealso [lap_plot_map], [lap_plot_distribution()]
#' @export
#' @examples
#' \dontrun{
#' ind <- lap_indicators(gems_ger_sample, c("memory", "flashiness"))
#' lap_plot_indicator_scatter(ind, ind_memory_weeks, ind_flashiness, smooth = TRUE)
#' }
lap_plot_indicator_scatter <- function(data, x, y, colour = NULL, ...,
                                       smooth = FALSE, rug = FALSE,
                                       role = "magnitude", direction = 1,
                                       robust = getOption("lapidary.scale_robust", FALSE),
                                       range = getOption("lapidary.scale_range", FALSE),
                                       variant = lap_variant(), lang = NULL,
                                       annotate = getOption("lapidary.annotate", "caption"),
                                       base_size = NULL, preset = NULL,
                                       title = NULL, subtitle = NULL, caption = NULL) {
  rlang::check_installed("ggplot2", "for `lap_plot_indicator_scatter()`")
  check_table(data)
  a <- resolve_builder_args(variant, lang, base_size, preset)
  x <- lap_eval_select_one(data, rlang::enquo(x), arg = "x")
  y <- lap_eval_select_one(data, rlang::enquo(y), arg = "y")
  colour <- lap_eval_select_one(data, rlang::enquo(colour), arg = "colour", null_ok = TRUE)
  df <- tibble::as_tibble(data)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[[x]], y = .data[[y]]))
  if (is.null(colour)) {
    p <- p + ggplot2::geom_point(
      colour = a$tokens$colour$recharge, alpha = 0.7, size = 1.6, na.rm = TRUE
    )
  } else {
    p <- p +
      ggplot2::geom_point(
        ggplot2::aes(colour = .data[[colour]]), alpha = 0.85, size = 1.6, na.rm = TRUE
      ) +
      scale_colour_lapidary_c(
        role,
        binned = TRUE, direction = direction, robust = robust, range = range,
        guide = lap_coloursteps_guide(variant = a$variant), ...
      )
  }
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
      x = lap_axis_label(x), y = lap_axis_label(y),
      colour = if (is.null(colour)) NULL else lap_prettify_label(colour),
      title = title, subtitle = subtitle, caption = caption
    ) +
    theme_lapidary(a$variant, base_size = a$base_size, panel = "xy")

  apply_howto(p, annotate, "indicator_scatter", a$lang, a$variant, a$tokens)
}
