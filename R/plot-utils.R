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

# Append the builder's how-to explainer per `annotate`:
#   NA / FALSE       -> unchanged
#   "caption" / TRUE -> lap_howto(builder) into plot.caption
#   "callout"        -> lap_howto(builder) as an on-panel corner box
#   any other string -> that string, as the caption
apply_howto <- function(plot, annotate, builder, lang, variant, tokens) {
  if (length(annotate) != 1L || is.na(annotate) || isFALSE(annotate)) {
    return(plot)
  }
  as_key <- isTRUE(annotate) || annotate %in% c("caption", "callout")
  text <- if (as_key) {
    lap_howto(builder, lang = lang, variant = variant)
  } else {
    as.character(annotate)
  }
  placement <- if (identical(annotate, "callout")) "callout" else "caption"
  lap_annotate_howto(
    plot, text = text, placement = placement, tokens = tokens
  )
}
