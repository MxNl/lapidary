# Chart-level enrichment: attach a marginal distribution to a builder plot.
# See docs/adr/0012 (cross-cutting `margin =`).

#' Attach a marginal distribution to a plot
#'
#' Adds a thin histogram / density / raincloud of `value` alongside `plot`,
#' sharing the same fill scale, and returns the pair as a [patchwork::patchwork].
#' The map builders call this for their `margin` argument; call it directly to
#' put a marginal on any plot whose fill is on a `scale_*_lapidary_c()`.
#'
#' @param plot A ggplot (typically a map from [lap_plot_hex_map()]).
#' @param data The data the marginal is computed from (the same layer / table).
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the column to
#'   summarise (the one `plot` is coloured by).
#' @param side `"bottom"` (default) or `"right"`.
#' @param type `"histogram"` (default), `"density"` or `"raincloud"`
#'   (`"raincloud"` needs \pkg{ggdist}).
#' @param size Marginal thickness as a fraction of the main plot. Default 0.18.
#' @param bins Histogram bin count.
#' @param role,direction,robust,range,limits Fill-scale parameters - pass the
#'   same values the main plot used so the gradients match.
#' @param variant,lang See [lap_plot_map].
#'
#' @return A [patchwork::patchwork].
#' @seealso [lap_plot_hex_map()]
#' @export
lap_attach_margin <- function(plot, data, value,
                              side = c("bottom", "right"),
                              type = c("histogram", "density", "raincloud"),
                              size = 0.18, bins = 30,
                              role = "magnitude", direction = 1,
                              robust = FALSE, range = FALSE, limits = NULL,
                              variant = NULL, lang = NULL) {
  rlang::check_installed(c("ggplot2", "patchwork"), "for `lap_attach_margin()`")
  side <- rlang::arg_match(side)
  type <- rlang::arg_match(type)
  a <- resolve_builder_args(variant, lang, NULL, NULL)
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")

  vals <- if (inherits(data, "sf")) {
    sf::st_drop_geometry(data)[[value]]
  } else {
    data[[value]]
  }
  df <- data.frame(.v = vals[is.finite(vals)])

  m <- ggplot2::ggplot(df, ggplot2::aes(x = .data$.v))
  m <- m + switch(type,
    histogram = ggplot2::geom_histogram(
      ggplot2::aes(fill = ggplot2::after_stat(.data$x)),
      bins = bins, colour = NA, na.rm = TRUE
    ),
    density = ggplot2::geom_density(
      ggplot2::aes(fill = ggplot2::after_stat(.data$x)), colour = NA, na.rm = TRUE
    ),
    raincloud = {
      rlang::check_installed("ggdist", "for `type = \"raincloud\"`")
      ggdist::stat_slab(
        ggplot2::aes(fill = ggplot2::after_stat(.data$x)), colour = NA, na.rm = TRUE
      )
    }
  )

  sc_args <- list(
    role, binned = FALSE, direction = direction, robust = robust, range = range,
    guide = "none"
  )
  if (!is.null(limits)) sc_args$limits <- limits
  m <- m + do.call(scale_fill_lapidary_c, sc_args) +
    ggplot2::labs(x = NULL, y = NULL) +
    theme_lapidary(a$variant, panel = "xy") +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(0, 0, 0, 0)
    )
  if (side == "right") m <- m + ggplot2::coord_flip()

  if (side == "bottom") {
    patchwork::wrap_plots(plot, m, ncol = 1, heights = c(1, size))
  } else {
    patchwork::wrap_plots(plot, m, nrow = 1, widths = c(1, size))
  }
}
