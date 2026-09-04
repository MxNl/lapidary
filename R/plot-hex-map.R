# Status-quo maps: choropleth on a hex grid, or coloured well points.
# See docs/adr/0012 for the builder contract.

#' lapidary map builders
#'
#' Two "status quo" builders that show one value per well over the whole
#' record on a map of Germany:
#'
#' * `lap_plot_hex_map()` - a choropleth of a hex grid from
#'   [lap_aggregate_to_hex()] (or `germany_hex_sample`). If a POINT layer is
#'   passed it dispatches to `lap_plot_point_map()`.
#' * `lap_plot_point_map()` - one coloured mark per monitoring well.
#'
#' Both return a bare [ggplot2::ggplot]; both end with [theme_lapidary()], a
#' single `scale_*_lapidary_c()` and a how-to-read `plot.caption` (see
#' `annotate`).
#'
#' @param data For `lap_plot_hex_map()` an `sf` polygon layer (a hex grid); for
#'   `lap_plot_point_map()` an `sf` POINT layer with the value column.
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the column to
#'   colour by.
#' @param ... Passed to the underlying `scale_*_lapidary_c()` (e.g. `limits`,
#'   `breaks`).
#' @param role Palette role (see [lap_pal_roles()]). Default: `"months"` for a
#'   circular-month column, `"anomaly"` when `midpoint` is set, else
#'   `"magnitude"`.
#' @param direction,midpoint,binned,bins,robust,range Passed to the scale.
#' @param hull,hull_shadow (`hex_map`) Draw the dissolved grid outline behind
#'   the hexes, with a drop shadow (needs \pkg{ggfx}; degrades to no shadow).
#' @param na_guide (`hex_map`) Add a [lap_na_guide()] "no data" key when the
#'   value column has `NA`s.
#' @param margin,margin_side (`hex_map`) Attach a marginal distribution of the
#'   mapped values (`"histogram"` / `"density"` / `"raincloud"`) on the
#'   `"bottom"` (default) or `"right"`; with `margin != "none"` the return is a
#'   [patchwork::patchwork]. Ignored for a circular-month column. See
#'   [lap_attach_margin()].
#' @param basemap (`point_map`) Draw [lap_germany_border()] behind the points
#'   (needs \pkg{rnaturalearth}).
#' @param size (`point_map`) Point size.
#' @param border_colour (`hex_map`) Hex border colour; default the background.
#' @param variant `"light"` / `"dark"`; defaults to [lap_variant()].
#' @param lang Language code; defaults to [lap_lang()].
#' @param annotate How-to-read explainer: `"caption"` (default), `"callout"`,
#'   `NA` to suppress, or a literal string. Default
#'   `getOption("lapidary.annotate", "caption")`.
#' @param base_size,preset Base font size, or a [lap_preset_names()] value that
#'   supplies it (e.g. `preset = "a1"` for poster-size text).
#' @param title,subtitle,caption Plot labels; `NULL` leaves them unset.
#'
#' @return A [ggplot2::ggplot], or a [patchwork::patchwork] when
#'   `lap_plot_hex_map(margin = )` is set.
#' @name lap_plot_map
#' @seealso [lap_aggregate_to_hex()], [lap_annotate_howto()]
#' @examples
#' \dontrun{
#' data(germany_hex_sample, package = "lapidary")
#' lap_plot_hex_map(germany_hex_sample, mean_gwl)
#' lap_plot_hex_map(germany_hex_sample, n_wells, role = "density")
#' }
NULL

#' @rdname lap_plot_map
#' @export
lap_plot_hex_map <- function(data, value, ...,
                             role = NULL, direction = 1, midpoint = NULL,
                             binned = TRUE, bins = 8,
                             robust = getOption("lapidary.scale_robust", FALSE),
                             range = getOption("lapidary.scale_range", FALSE),
                             hull = TRUE, hull_shadow = TRUE, na_guide = TRUE,
                             border_colour = NULL,
                             margin = c("none", "histogram", "density", "raincloud"),
                             margin_side = c("bottom", "right"),
                             variant = lap_variant(), lang = NULL,
                             annotate = getOption("lapidary.annotate", "caption"),
                             base_size = NULL, preset = NULL,
                             title = NULL, subtitle = NULL, caption = NULL) {
  rlang::check_installed(c("ggplot2", "sf"), "for `lap_plot_hex_map()`")
  margin <- rlang::arg_match(margin)
  margin_side <- rlang::arg_match(margin_side)

  if (inherits(data, "sf") &&
    all(grepl("POINT", as.character(sf::st_geometry_type(data, by_geometry = FALSE))))) {
    return(lap_plot_point_map(
      data, {{ value }}, ...,
      role = role %||% "magnitude", direction = direction,
      robust = robust, range = range,
      variant = variant, lang = lang, annotate = annotate,
      base_size = base_size, preset = preset,
      title = title, subtitle = subtitle, caption = caption
    ))
  }
  check_hex_layer(data)

  a <- resolve_builder_args(variant, lang, base_size, preset)
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")

  is_month <- identical(column_range(value), "(0.5, 12.5]") ||
    value %in% c("ind_min_month", "ind_max_month")
  role <- role %||% if (is_month) {
    "months"
  } else if (!is.null(midpoint)) {
    "anomaly"
  } else {
    "magnitude"
  }
  border_colour <- border_colour %||% a$tokens$colour$background

  p <- ggplot2::ggplot(data)

  if (isTRUE(hull)) {
    hull_layer <- ggplot2::geom_sf(
      data = sf::st_sf(geometry = sf::st_union(sf::st_geometry(data))),
      fill = a$tokens$colour$panel, colour = NA
    )
    if (isTRUE(hull_shadow) && requireNamespace("ggfx", quietly = TRUE)) {
      hull_layer <- ggfx::with_shadow(
        hull_layer,
        sigma = a$tokens$effect$shadow_sigma,
        colour = a$tokens$effect$shadow_colour,
        x_offset = a$tokens$effect$shadow_offset,
        y_offset = a$tokens$effect$shadow_offset
      )
    }
    p <- p + hull_layer
  }

  p <- p +
    ggplot2::geom_sf(
      ggplot2::aes(fill = .data[[value]]),
      colour = border_colour, linewidth = 0.1
    ) +
    ggplot2::coord_sf(datum = NA)

  if (is_month) {
    p <- p + scale_fill_lapidary_c(
      "months",
      binned = FALSE, direction = direction,
      limits = c(0.5, 12.5), breaks = 1:12,
      labels = lap_tr("months_short", a$lang), ...
    )
  } else {
    p <- p + scale_fill_lapidary_c(
      role,
      binned = binned, bins = bins, direction = direction,
      midpoint = midpoint, robust = robust, range = range,
      guide = lap_coloursteps_guide(variant = a$variant), ...
    )
  }
  if (isTRUE(na_guide) && anyNA(data[[value]])) {
    p <- p + lap_na_guide(variant = a$variant)
  }

  p <- p +
    ggplot2::labs(
      title = title, subtitle = subtitle, caption = caption,
      fill = lap_prettify_label(value)
    ) +
    theme_lapidary(a$variant, base_size = a$base_size, panel = "map")

  p <- apply_howto(p, annotate, "hex_map", a$lang, a$variant, a$tokens)

  if (margin != "none" && !is_month) {
    p <- lap_attach_margin(
      p, data, dplyr::all_of(value),
      side = margin_side, type = margin,
      role = role, direction = direction, robust = robust, range = range,
      variant = a$variant, lang = a$lang
    )
  }
  p
}

#' @rdname lap_plot_map
#' @export
lap_plot_point_map <- function(data, value, ...,
                               role = "magnitude", direction = 1, size = 1.6,
                               robust = getOption("lapidary.scale_robust", FALSE),
                               range = getOption("lapidary.scale_range", FALSE),
                               basemap = TRUE,
                               variant = lap_variant(), lang = NULL,
                               annotate = getOption("lapidary.annotate", "caption"),
                               base_size = NULL, preset = NULL,
                               title = NULL, subtitle = NULL, caption = NULL) {
  rlang::check_installed(c("ggplot2", "sf"), "for `lap_plot_point_map()`")
  check_point_layer(data)

  a <- resolve_builder_args(variant, lang, base_size, preset)
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")

  p <- ggplot2::ggplot()
  if (isTRUE(basemap) && requireNamespace("rnaturalearth", quietly = TRUE)) {
    p <- p + ggplot2::geom_sf(
      data = lap_germany_border(),
      fill = a$tokens$colour$panel, colour = a$tokens$colour$grid, linewidth = 0.3
    )
  }
  p <- p +
    ggplot2::geom_sf(
      data = data, ggplot2::aes(colour = .data[[value]]), size = size
    ) +
    ggplot2::coord_sf(datum = NA) +
    scale_colour_lapidary_c(
      role,
      binned = TRUE, direction = direction,
      robust = robust, range = range,
      guide = lap_coloursteps_guide(variant = a$variant), ...
    ) +
    ggplot2::labs(
      title = title, subtitle = subtitle, caption = caption,
      colour = lap_prettify_label(value)
    ) +
    theme_lapidary(a$variant, base_size = a$base_size, panel = "map")

  apply_howto(p, annotate, "point_map", a$lang, a$variant, a$tokens)
}

# Assert `data` is an sf POINT layer.
check_point_layer <- function(data, arg = "data", call = rlang::caller_env()) {
  ok <- inherits(data, "sf") &&
    all(grepl("POINT", as.character(sf::st_geometry_type(data, by_geometry = FALSE))))
  if (!ok) {
    cli::cli_abort(c(
      "{.arg {arg}} must be an {.cls sf} POINT layer.",
      i = "e.g. from {.fn lap_read_gems_ger_wells}, or {.code gems_ger_wells_sample}."
    ), call = call)
  }
  invisible(data)
}
