# Shared plumbing for the lap_plot_* chart builders (see docs/adr/0012).
#
# Every builder:
#  * takes `data` as one documented canonical shape + tidy-select column args;
#  * takes `variant` / `lang` / `annotate` / `base_size` / `preset` and resolves
#    them here;
#  * returns a bare `ggplot` (or `patchwork` for composite / `margin` builders);
#  * ends with `theme_lapidary(variant, base_size, panel=)`, exactly one
#    `*_lapidary` scale, and all display text via `lap_tr()` / `lap_howto()`;
#  * has no global state, RNG, file IO or `options()` calls.

# Resolve the standard builder arguments once. `preset` (a `lap_preset_names()`
# value) supplies `base_size` when it is not given explicitly.
resolve_builder_args <- function(variant = NULL, lang = NULL,
                                 base_size = NULL, preset = NULL) {
  variant <- lap_variant(variant)
  if (!is.null(preset)) {
    base_size <- base_size %||% lap_preset(preset)$base_size
  }
  list(
    variant = variant,
    lang = lap_lang(lang),
    base_size = base_size %||% 11,
    tokens = lap_tokens(variant)
  )
}

# "Trend slope (m/year)" - the prettified column name plus its catalogue unit,
# unless the name already ends with that unit word (e.g. "Memory weeks").
lap_axis_label <- function(col) {
  lbl <- lap_prettify_label(col)
  u <- column_units(col)
  if (length(u) == 1L && !is.na(u) && nzchar(u) && u != "-" &&
    !endsWith(tolower(lbl), tolower(u))) {
    lbl <- paste0(lbl, " (", u, ")")
  }
  lbl
}

# Assert `data` is a plain data frame (an indicators / summary table).
check_table <- function(data, arg = "data", call = rlang::caller_env()) {
  if (!is.data.frame(data) || inherits(data, "sf")) {
    cli::cli_abort(c(
      "{.arg {arg}} must be a plain data frame.",
      i = "e.g. from {.fn lap_indicators} or {.fn lap_summarise_wells}."
    ), call = call)
  }
  invisible(data)
}

# Assert `data` is an sf POLYGON layer (a hex grid from lap_aggregate_to_hex()).
check_hex_layer <- function(data, arg = "data", call = rlang::caller_env()) {
  ok <- inherits(data, "sf") &&
    any(grepl("POLYGON", as.character(sf::st_geometry_type(data, by_geometry = FALSE))))
  if (!ok) {
    cli::cli_abort(c(
      "{.arg {arg}} must be an {.cls sf} polygon layer (a hex grid).",
      i = "Build one with {.fn lap_aggregate_to_hex}, or use {.code germany_hex_sample}."
    ), call = call)
  }
  invisible(data)
}

# `plot.caption` element for the how-to annotation: markdown-aware, wraps to
# the plot width, muted, left-aligned, in the body font of `tokens`.
howto_caption_element <- function(tokens) {
  fam <- resolve_family(tokens$font$body, tokens$font$fallback_body)
  if (requireNamespace("ggtext", quietly = TRUE)) {
    ggtext::element_textbox_simple(
      family = fam, size = ggplot2::rel(tokens$size$caption),
      colour = tokens$colour$ink_muted, lineheight = 1.3,
      halign = 0, width = grid::unit(1, "npc"),
      margin = ggplot2::margin(t = tokens$size$caption * 5)
    )
  } else {
    ggplot2::element_text(
      family = fam, size = ggplot2::rel(tokens$size$caption),
      colour = tokens$colour$ink_muted, hjust = 0
    )
  }
}

# Resolve `annotate` to the explainer string (or NULL for "no annotation"):
#   NA / FALSE       -> NULL
#   "caption" / "callout" / TRUE -> lap_howto(builder)
#   any other string -> that string
howto_text <- function(annotate, builder, lang, variant) {
  if (length(annotate) != 1L || is.na(annotate) || isFALSE(annotate)) {
    return(NULL)
  }
  if (isTRUE(annotate) || annotate %in% c("caption", "callout")) {
    lap_howto(builder, lang = lang, variant = variant)
  } else {
    as.character(annotate)
  }
}

# Append the builder's how-to explainer per `annotate` (see `howto_text()`).
# `"callout"` places an on-panel box; anything else that annotates goes to
# `plot.caption`.
apply_howto <- function(plot, annotate, builder, lang, variant, tokens) {
  text <- howto_text(annotate, builder, lang, variant)
  if (is.null(text)) {
    return(plot)
  }
  placement <- if (identical(annotate, "callout")) "callout" else "caption"
  lap_annotate_howto(
    plot, text = text, placement = placement, tokens = tokens
  )
}

# Locate the `<value>_<from>` / `<value>_<to>` / `<value>_change` columns that
# lap_indicator_delta() emits for the base indicator column `value`.
resolve_delta_columns <- function(data, value, call = rlang::caller_env()) {
  nms <- names(data)
  prefix <- paste0(value, "_")
  change <- paste0(value, "_change")
  paired <- setdiff(nms[startsWith(nms, prefix)], change)
  if (length(paired) < 2L) {
    cli::cli_abort(c(
      "Couldn't find the {.val {value}} period columns in {.arg data}.",
      i = "Expected {.field {value}_<from>} / {.field {value}_<to>} \\
           (and {.field {value}_change}) from {.fn lap_indicator_delta}."
    ), call = call)
  }
  list(
    from = paired[[1L]], to = paired[[2L]],
    change = if (change %in% nms) change else NA_character_,
    labels = sub(paste0("^", prefix), "", paired[1:2])
  )
}

# The shared hex-choropleth body: the dissolved hull (optionally shadowed), the
# `fill = value` polygon layer, `coord_sf(datum = NA)`, one
# `scale_fill_lapidary_c()` and - when the column has `NA`s - a `lap_na_guide()`.
# Returns a ggplot without labs / theme / how-to / margin (the callers add those).
hex_fill_plot <- function(data, value, a, role, direction, binned, bins,
                          midpoint = NULL, robust = FALSE, range = FALSE,
                          hull = TRUE, hull_shadow = TRUE,
                          border_colour = NULL, na_guide = TRUE,
                          scale_args = list()) {
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
    ggplot2::coord_sf(datum = NA) +
    do.call(scale_fill_lapidary_c, c(
      list(
        role,
        binned = binned, bins = bins, direction = direction,
        midpoint = midpoint, robust = robust, range = range,
        guide = lap_coloursteps_guide(variant = a$variant)
      ),
      scale_args
    ))

  if (isTRUE(na_guide) && anyNA(data[[value]])) {
    p <- p + lap_na_guide(variant = a$variant)
  }
  p
}
