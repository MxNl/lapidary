# Change-over-periods builder: map how an indicator shifted between two periods.
# See docs/adr/0012 for the builder contract.

#' Map the change in an indicator between two periods
#'
#' Visualises the output of [lap_indicator_delta()] aggregated onto a hex grid:
#' the per-hexagon change in one indicator between a `from` and a `to` period.
#'
#' `data` is an `sf` hex layer carrying the wide `<value>_<from>`,
#' `<value>_<to>` and `<value>_change` columns - build it by joining
#' [lap_indicator_delta()] to the wells and passing it through
#' [lap_aggregate_to_hex()]. `value` is the **base** indicator column name
#' (without the period / `_change` suffix), e.g. `ind_amplitude`.
#'
#' @param data An `sf` polygon layer (a hex grid) with the delta columns.
#' @param value The base indicator column, as a bare name or string (e.g.
#'   `ind_amplitude`); the `_<from>` / `_<to>` / `_change` columns are resolved
#'   from it.
#' @param ... Passed to the underlying `scale_fill_lapidary_c()`.
#' @param display `"change"` (default) a divergent choropleth of `_change`
#'   about zero; `"paired"` two shared-scale period maps (returns a
#'   [patchwork::patchwork]); `"arrow"` a per-hexagon glyph whose length and
#'   direction encode the change.
#' @param direction,binned,bins,robust,range Passed to the fill scale.
#' @param hull,hull_shadow,na_guide,border_colour As in [lap_plot_hex_map()].
#' @param margin,margin_side Attach a marginal distribution of the mapped
#'   `_change` values (only for `display = "change"`); see [lap_attach_margin()].
#' @param variant,lang,annotate,base_size,preset,title,subtitle,caption See
#'   [lap_plot_map].
#'
#' @return A [ggplot2::ggplot], or a [patchwork::patchwork] for
#'   `display = "paired"` or when `margin` is set.
#' @seealso [lap_indicator_delta()], [lap_plot_change_scatter()],
#'   [lap_plot_period_ridges()]
#' @export
#' @examples
#' \dontrun{
#' chg <- lap_indicator_change(
#'   gems_ger_sample, "amplitude",
#'   periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
#' )
#' dl <- lap_indicator_delta(chg, "reference", "recent")
#' hex <- lap_aggregate_to_hex(gems_ger_wells_sample, dl)
#' lap_plot_delta_map(hex, ind_amplitude)
#' lap_plot_delta_map(hex, ind_amplitude, display = "paired")
#' }
lap_plot_delta_map <- function(data, value, ...,
                               display = c("change", "paired", "arrow"),
                               direction = 1, binned = TRUE, bins = 8,
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
  rlang::check_installed(c("ggplot2", "sf"), "for `lap_plot_delta_map()`")
  display <- rlang::arg_match(display)
  margin <- rlang::arg_match(margin)
  margin_side <- rlang::arg_match(margin_side)
  check_hex_layer(data)

  a <- resolve_builder_args(variant, lang, base_size, preset)
  value <- rlang::as_string(rlang::ensym(value))
  dc <- resolve_delta_columns(data, value)
  base_label <- lap_prettify_label(value)
  scale_args <- rlang::list2(...)

  if (display == "paired") {
    flat <- sf::st_drop_geometry(data)
    lims <- range(c(flat[[dc$from]], flat[[dc$to]]), na.rm = TRUE)
    panel <- function(col, sub) {
      hex_fill_plot(
        data, col, a,
        role = "magnitude", direction = direction, binned = binned, bins = bins,
        robust = robust, range = range, hull = hull, hull_shadow = hull_shadow,
        border_colour = border_colour, na_guide = na_guide,
        scale_args = c(list(limits = lims), scale_args)
      ) +
        ggplot2::labs(subtitle = sub, fill = base_label) +
        theme_lapidary(a$variant, base_size = a$base_size, panel = "map")
    }
    pw <- patchwork::wrap_plots(
      panel(dc$from, dc$labels[[1]]), panel(dc$to, dc$labels[[2]]),
      nrow = 1
    ) +
      patchwork::plot_layout(guides = "collect")
    howto <- howto_text(annotate, "delta_map_paired", a$lang, a$variant)
    pw <- pw + patchwork::plot_annotation(
      title = title, subtitle = subtitle, caption = howto,
      theme = ggplot2::theme(plot.caption = howto_caption_element(a$tokens))
    )
    return(pw)
  }

  if (display == "arrow") {
    if (is.na(dc$change)) delta_change_abort(value)
    keep <- data[!is.na(data[[dc$change]]), , drop = FALSE]
    cent <- sf::st_coordinates(sf::st_centroid(sf::st_geometry(keep)))
    bb <- sf::st_bbox(data)
    step <- as.numeric(bb["xmax"] - bb["xmin"]) * 0.045
    chg <- keep[[dc$change]]
    dx <- chg / max(abs(chg), na.rm = TRUE) * step
    seg <- data.frame(
      x = cent[, 1] - dx / 2, xend = cent[, 1] + dx / 2,
      y = cent[, 2], yend = cent[, 2], .chg = chg
    )
    p <- ggplot2::ggplot(data) +
      ggplot2::geom_sf(fill = a$tokens$colour$panel, colour = a$tokens$colour$grid, linewidth = 0.1) +
      ggplot2::geom_segment(
        data = seg,
        ggplot2::aes(
          x = .data$x, y = .data$y, xend = .data$xend, yend = .data$yend,
          colour = .data$.chg
        ),
        arrow = ggplot2::arrow(length = grid::unit(4, "pt"), type = "closed"),
        linewidth = 0.6
      ) +
      ggplot2::coord_sf(datum = NA) +
      do.call(scale_colour_lapidary_c, c(
        list(
          "anomaly",
          binned = binned, bins = bins, direction = direction, midpoint = 0,
          robust = robust, range = range,
          guide = lap_coloursteps_guide(variant = a$variant)
        ),
        scale_args
      )) +
      ggplot2::labs(
        title = title, subtitle = subtitle, caption = caption,
        colour = paste0(base_label, " \u0394")
      ) +
      theme_lapidary(a$variant, base_size = a$base_size, panel = "map")
    return(apply_howto(p, annotate, paste0("delta_map_", display), a$lang, a$variant, a$tokens))
  }

  # display == "change"
  if (is.na(dc$change)) delta_change_abort(value)
  p <- hex_fill_plot(
    data, dc$change, a,
    role = "anomaly", direction = direction, binned = binned, bins = bins,
    midpoint = 0, robust = robust, range = range,
    hull = hull, hull_shadow = hull_shadow,
    border_colour = border_colour, na_guide = na_guide,
    scale_args = scale_args
  ) +
    ggplot2::labs(
      title = title, subtitle = subtitle, caption = caption,
      fill = paste0(base_label, " \u0394")
    ) +
    theme_lapidary(a$variant, base_size = a$base_size, panel = "map")

  p <- apply_howto(p, annotate, "delta_map_change", a$lang, a$variant, a$tokens)

  if (margin != "none") {
    p <- lap_attach_margin(
      p, data, dplyr::all_of(dc$change),
      side = margin_side, type = margin,
      role = "anomaly", direction = direction, robust = robust, range = range,
      limits = NULL, variant = a$variant, lang = a$lang
    )
  }
  p
}

# A helpful error when the base indicator has no meaningful `_change` column.
delta_change_abort <- function(value, call = rlang::caller_env()) {
  kind <- column_delta_kind(value)
  cli::cli_abort(c(
    "No {.field {value}_change} column in {.arg data}.",
    i = if (identical(kind, "none")) {
      "{.field {value}} has {.field delta_kind} {.val none} (e.g. a p-value or \\
       a year): a difference isn't defined."
    } else {
      "Recompute with {.fn lap_indicator_delta} so {.field {value}_change} is present."
    }
  ), call = call)
}
