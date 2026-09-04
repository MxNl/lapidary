# Status-quo builder: the distribution of one indicator across wells.
# See docs/adr/0012 for the builder contract.

#' Distribution of one indicator across wells
#'
#' A histogram, density, raincloud or dot plot of a single `ind_*` column
#' (from [lap_indicators()]), coloured on the same palette the maps use, so a
#' distribution panel reads consistently with a choropleth of the same metric.
#'
#' @param data A plain data frame with the value column (e.g. from
#'   [lap_indicators()] or [lap_summarise_wells()]).
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the column to plot.
#' @param ... Passed to the underlying `scale_*_lapidary_c()`.
#' @param group <[`tidy-select`][dplyr::dplyr_tidy_select]> optional split -
#'   facets for `"histogram"` / `"density"`, rows for `"raincloud"` / `"dots"`.
#' @param geom `"histogram"` (default), `"density"`, `"raincloud"` or `"dots"`.
#'   The last two need \pkg{ggdist}.
#' @param bins Histogram bin count. Default 30.
#' @param role,direction,robust,range Passed to the fill scale.
#' @param rug Add a marginal rug of the raw values.
#' @param variant,lang,annotate,base_size,preset,title,subtitle,caption See
#'   [lap_plot_map].
#'
#' @return A [ggplot2::ggplot].
#' @seealso [lap_plot_map], [lap_indicator_registry()]
#' @export
#' @examples
#' \dontrun{
#' ind <- lap_indicators(gems_ger_sample, "amplitude")
#' lap_plot_distribution(ind, ind_amplitude)
#' lap_plot_distribution(ind, ind_amplitude, geom = "raincloud")
#' }
lap_plot_distribution <- function(data, value, ...,
                                  group = NULL,
                                  geom = c("histogram", "density", "raincloud", "dots"),
                                  bins = 30,
                                  role = "magnitude", direction = 1,
                                  robust = getOption("lapidary.scale_robust", FALSE),
                                  range = getOption("lapidary.scale_range", FALSE),
                                  rug = FALSE,
                                  variant = lap_variant(), lang = NULL,
                                  annotate = getOption("lapidary.annotate", "caption"),
                                  base_size = NULL, preset = NULL,
                                  title = NULL, subtitle = NULL, caption = NULL) {
  rlang::check_installed("ggplot2", "for `lap_plot_distribution()`")
  check_table(data)
  geom <- rlang::arg_match(geom)
  a <- resolve_builder_args(variant, lang, base_size, preset)
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  group <- lap_eval_select_one(data, rlang::enquo(group), arg = "group", null_ok = TRUE)
  df <- tibble::as_tibble(data)

  scale_fill <- scale_fill_lapidary_c(
    role,
    binned = FALSE, direction = direction, robust = robust, range = range,
    guide = "none", ...
  )
  base <- theme_lapidary(a$variant, base_size = a$base_size, panel = "xy")
  x_lab <- lap_axis_label(value)

  if (geom %in% c("raincloud", "dots")) {
    rlang::check_installed("ggdist", "for `geom = \"raincloud\"` / `\"dots\"`")
    y <- if (is.null(group)) "" else NULL
    p <- ggplot2::ggplot(df, ggplot2::aes(
      x = .data[[value]],
      y = if (is.null(group)) "" else .data[[group]],
      fill = ggplot2::after_stat(.data$x)
    ))
    if (geom == "raincloud") {
      p <- p +
        ggdist::stat_slab(height = 0.7, colour = NA) +
        ggdist::stat_dots(
          side = "bottom", scale = 0.5, colour = NA,
          ggplot2::aes(fill = .data[[value]])
        ) +
        ggplot2::stat_summary(
          ggplot2::aes(fill = NULL), fun = stats::median, geom = "point",
          colour = a$tokens$colour$ink, size = 1.5
        )
    } else {
      p <- p + ggdist::stat_dots(colour = NA)
    }
    p <- p + scale_fill +
      ggplot2::labs(
        x = x_lab, y = if (is.null(group)) NULL else lap_prettify_label(group),
        title = title, subtitle = subtitle, caption = caption
      ) +
      base
    return(apply_howto(p, annotate, "distribution", a$lang, a$variant, a$tokens))
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[[value]]))
  p <- p + if (geom == "histogram") {
    ggplot2::geom_histogram(
      ggplot2::aes(fill = ggplot2::after_stat(.data$x)),
      bins = bins, colour = a$tokens$colour$background, linewidth = 0.15,
      na.rm = TRUE
    )
  } else {
    ggplot2::geom_density(
      ggplot2::aes(fill = ggplot2::after_stat(.data$x)),
      colour = a$tokens$colour$ink_muted, linewidth = 0.3, na.rm = TRUE
    )
  }
  if (isTRUE(rug)) {
    p <- p + ggplot2::geom_rug(
      alpha = 0.35, colour = a$tokens$colour$ink_muted, na.rm = TRUE
    )
  }
  if (!is.null(group)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data[[group]]))
  }
  p <- p + scale_fill +
    ggplot2::labs(
      x = x_lab, y = NULL, title = title, subtitle = subtitle, caption = caption
    ) +
    base

  apply_howto(p, annotate, "distribution", a$lang, a$variant, a$tokens)
}
