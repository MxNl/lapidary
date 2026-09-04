# Colour + fill scales ------------------------------------------------------
#
# Thin, stably-named wrappers around scico palettes so builders (and users)
# refer to a *role* ("months", "magnitude", "divergent") rather than a palette
# name that might change.

lap_palettes <- list(
  # cyclic - month-of-year / phase
  months = "romaO",
  # sequential - a magnitude / duration
  magnitude = "lapaz",
  magnitude_dark = "batlowK",
  # sequential - counts / density
  density = "grayC",
  # divergent - anomaly vs a reference
  anomaly = "vik"
)

#' Names of the lapidary palette roles
#' @return A character vector.
#' @export
lap_pal_roles <- function() names(lap_palettes)

resolve_palette <- function(role) {
  pal <- lap_palettes[[role]]
  if (is.null(pal)) {
    cli::cli_abort(c(
      "Unknown palette role {.val {role}}.",
      i = "Roles: {.val {lap_pal_roles()}}."
    ))
  }
  pal
}

#' lapidary continuous fill / colour scales
#'
#' `role` selects a scico palette by its purpose:
#' `"months"` (cyclic), `"magnitude"`/`"magnitude_dark"` (sequential),
#' `"density"` (sequential greys), `"anomaly"` (divergent).
#'
#' The continuous (`_c`) scales are **binned** by default: the data is cut at
#' pretty round breaks and shown as a long, thin colour-steps bar. The legend
#' title is derived from the mapped variable with [lap_prettify_label()]
#' (`ind_trend_slope` becomes `"Trend slope"`) unless you pass `name`. Pair with
#' [lap_na_guide()] to add a "no data" key for `NA` regions (e.g. empty hexes).
#'
#' @param role One of [lap_pal_roles()].
#' @param ... Passed to the underlying scale ([ggplot2::binned_scale()] when
#'   `binned = TRUE`, else [scico::scale_fill_scico()] /
#'   [scico::scale_colour_scico()]) - e.g. `limits`, `breaks`, `labels`.
#' @param name Legend title. A string, `NULL` to drop it, or a function of the
#'   default (auto-derived) title. Defaults to [lap_prettify_label()].
#' @param na.value Colour for `NA`. Defaults to the token `missing` colour.
#' @param binned If `TRUE` (default, `_c` only) cut the scale at pretty breaks
#'   and use a colour-steps guide; `FALSE` gives a smooth gradient.
#' @param bins Target number of bins (passed to `binned_scale()` as `n.breaks`).
#'   Default 8; `NULL` lets ggplot2 choose.
#' @param begin,end,direction Passed to [scico::scico()] to trim / flip the
#'   palette.
#' @param midpoint For a divergent `role` (`"anomaly"`), the data value placed
#'   at the palette centre.
#' @param guide Legend guide. Defaults to a long, thin
#'   [ggplot2::guide_coloursteps()] (binned) or the scale default.
#'
#' @return A ggplot2 scale.
#' @name scale_lapidary
#' @seealso [lap_na_guide()], [lap_prettify_label()]
#' @examples
#' \dontrun{
#' library(ggplot2)
#' data(germany_hex_sample, package = "lapidary")
#' ggplot(germany_hex_sample) +
#'   geom_sf(aes(fill = mean_gwl)) +
#'   scale_fill_lapidary_c("magnitude") +
#'   lap_na_guide() +
#'   theme_lapidary()
#' }
NULL

#' @rdname scale_lapidary
#' @export
scale_fill_lapidary_c <- function(role = "magnitude", ...,
                                  name = lap_prettify_label,
                                  na.value = lap_tokens()$colour$missing,
                                  binned = TRUE, bins = 8,
                                  begin = 0, end = 1, direction = 1,
                                  midpoint = NULL, guide = NULL) {
  lapidary_scale_c(
    "fill", role, ...,
    name = name, na.value = na.value, binned = binned, bins = bins,
    begin = begin, end = end, direction = direction, midpoint = midpoint,
    guide = guide
  )
}

#' @rdname scale_lapidary
#' @export
scale_colour_lapidary_c <- function(role = "magnitude", ...,
                                    name = lap_prettify_label,
                                    na.value = lap_tokens()$colour$missing,
                                    binned = TRUE, bins = 8,
                                    begin = 0, end = 1, direction = 1,
                                    midpoint = NULL, guide = NULL) {
  lapidary_scale_c(
    "colour", role, ...,
    name = name, na.value = na.value, binned = binned, bins = bins,
    begin = begin, end = end, direction = direction, midpoint = midpoint,
    guide = guide
  )
}

#' @rdname scale_lapidary
#' @export
scale_color_lapidary_c <- scale_colour_lapidary_c

# Shared builder for the continuous fill/colour scales.
lapidary_scale_c <- function(aesthetic, role, ..., name, na.value, binned, bins,
                             begin, end, direction, midpoint, guide) {
  rlang::check_installed(c("ggplot2", "scico"), "for the lapidary scales")
  pal <- resolve_palette(role)

  if (!isTRUE(binned)) {
    scico_fn <- if (aesthetic == "fill") {
      scico::scale_fill_scico
    } else {
      scico::scale_colour_scico
    }
    args <- list(
      palette = pal, na.value = na.value, name = name,
      begin = begin, end = end, direction = direction, ...
    )
    if (!is.null(midpoint)) args$midpoint <- midpoint
    if (!is.null(guide)) args$guide <- guide
    return(do.call(scico_fn, args))
  }

  cols <- scico::scico(256, palette = pal, begin = begin, end = end, direction = direction)
  rescaler <- if (is.null(midpoint)) {
    scales::rescale
  } else {
    function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) {
      scales::rescale_mid(x, to, from, mid = midpoint)
    }
  }
  ggplot2::binned_scale(
    aesthetics = aesthetic,
    palette = scales::gradient_n_pal(cols),
    name = name,
    na.value = na.value,
    rescaler = rescaler,
    nice.breaks = TRUE,
    n.breaks = bins,
    show.limits = TRUE,
    guide = guide %||% lap_coloursteps_guide(),
    ...
  )
}

#' A long, thin colour-steps legend guide
#'
#' The default guide for the binned [scale_lapidary] scales: a tall, narrow
#' [ggplot2::guide_coloursteps()] bar with a subtle frame and tick marks.
#'
#' @param length,thickness Bar length and thickness, in text `"lines"` (so they
#'   scale with the legend text size). Defaults 18 and 0.55.
#' @param title_gap,label_gap,tick_length Space (in `"lines"`) below the legend
#'   title, to the left of the break labels, and the tick-mark length. Defaults
#'   0.9, 1.0 and 0.2.
#' @param order Guide order (default 1), so it sits above a [lap_na_guide()] key.
#' @param ... Passed to [ggplot2::guide_coloursteps()].
#'
#' @return A ggplot2 guide.
#' @export
lap_coloursteps_guide <- function(length = 18, thickness = 0.55,
                                  title_gap = 0.9, label_gap = 1.0,
                                  tick_length = 0.2, order = 1, ...) {
  rlang::check_installed("ggplot2", "for `lap_coloursteps_guide()`")
  tk <- lap_tokens()
  ggplot2::guide_coloursteps(
    theme = ggplot2::theme(
      legend.key.width = grid::unit(thickness, "lines"),
      legend.key.height = grid::unit(length, "lines"),
      legend.title = ggplot2::element_text(
        margin = ggplot2::margin(b = title_gap, unit = "lines")
      ),
      legend.text = ggplot2::element_text(
        margin = ggplot2::margin(l = label_gap, unit = "lines")
      ),
      legend.ticks.length = grid::unit(tick_length, "lines"),
      legend.ticks = ggplot2::element_line(colour = tk$colour$grid, linewidth = 0.4),
      legend.frame = ggplot2::element_rect(
        colour = tk$colour$grid, fill = NA, linewidth = 0.3
      )
    ),
    show.limits = TRUE,
    order = order,
    ...
  )
}

#' Add a "no data" key for NA regions
#'
#' ggplot2's colour-bar and colour-steps guides do not show an `NA` entry.
#' Add `+ lap_na_guide()` after a [scale_lapidary] scale to draw a single
#' swatch (an invisible layer on the unused `shape` aesthetic) for the
#' `na.value` colour - e.g. hexagons with no wells.
#'
#' @param label Key label. Defaults to `"no data"`.
#' @param colour Swatch colour. Defaults to the token `missing` colour (match
#'   the scale's `na.value`).
#' @param order Legend order (passed to [ggplot2::guide_legend()]); the default
#'   2 keeps the NA key below a [lap_coloursteps_guide()] bar (order 1).
#'
#' @return A list of ggplot2 layers/scales to add to a plot with `+`.
#' @seealso [scale_lapidary]
#' @export
#' @examples
#' \dontrun{
#' library(ggplot2)
#' data(germany_hex_sample, package = "lapidary")
#' ggplot(germany_hex_sample) +
#'   geom_sf(aes(fill = mean_gwl)) +
#'   scale_fill_lapidary_c("magnitude") +
#'   lap_na_guide()
#' }
lap_na_guide <- function(label = "no data",
                         colour = lap_tokens()$colour$missing,
                         order = 2) {
  rlang::check_installed("ggplot2", "for `lap_na_guide()`")
  label <- as.character(label)
  list(
    # an off-panel (NA-coord) point: never drawn, but it trains a `shape`
    # legend whose single key we recolour to the NA swatch
    ggplot2::geom_point(
      data = data.frame(x = NA_real_, y = NA_real_, lap_na = label),
      mapping = ggplot2::aes(
        x = .data$x, y = .data$y, shape = .data$lap_na
      ),
      inherit.aes = FALSE, na.rm = TRUE, key_glyph = ggplot2::draw_key_rect
    ),
    ggplot2::scale_shape_manual(
      name = NULL,
      values = stats::setNames(22L, label),
      guide = ggplot2::guide_legend(
        order = order,
        override.aes = list(fill = colour, colour = NA, alpha = 1)
      )
    )
  )
}

#' Turn a variable name into a readable label
#'
#' `snake_case` / `dotted.names` become sentence case with underscores removed
#' and domain acronyms (`gwl`, `sgi`, `spi`, ...) upper-cased; a leading `ind_`
#' (the indicator-column prefix) is dropped. Used as the default `name` of the
#' [scale_lapidary] scales, and handy for axis titles and facet labellers.
#'
#' @param x A character vector (or a single value passed through unchanged if
#'   not a length-1 string, so it is safe as a ggplot2 `labeller` / scale
#'   `name`).
#'
#' @return A character vector of prettified labels.
#' @export
#' @examples
#' lap_prettify_label(c("mean_gwl", "ind_trend_slope", "ind_drought_severity"))
lap_prettify_label <- function(x) {
  if (!is.character(x)) {
    return(x)
  }
  acr <- c(
    gwl = "GWL", sgi = "SGI", spi = "SPI", spei = "SPEI", pet = "PET",
    sd = "SD", cc = "CC", id = "ID", na = "NA", acf1 = "ACF1",
    rmse = "RMSE", asl = "a.s.l.", bgl = "b.g.l.", wmo = "WMO"
  )
  vapply(x, function(s) {
    if (is.na(s) || !nzchar(s)) {
      return(s)
    }
    s <- sub("^ind_", "", s)
    toks <- strsplit(gsub("[._]+", " ", trimws(s)), " ", fixed = TRUE)[[1]]
    toks <- toks[nzchar(toks)]
    toks <- vapply(toks, function(t) {
      hit <- acr[tolower(t)]
      if (is.na(hit)) t else unname(hit)
    }, character(1))
    out <- paste(toks, collapse = " ")
    substr(out, 1, 1) <- toupper(substr(out, 1, 1))
    out
  }, character(1), USE.NAMES = FALSE)
}

#' @rdname scale_lapidary
#' @export
scale_fill_lapidary_d <- function(role = "magnitude", ...,
                                  name = lap_prettify_label,
                                  na.value = lap_tokens()$colour$missing) {
  rlang::check_installed("scico", "for the lapidary scales")
  scico::scale_fill_scico_d(
    palette = resolve_palette(role), name = name, na.value = na.value, ...
  )
}

#' @rdname scale_lapidary
#' @export
scale_colour_lapidary_d <- function(role = "magnitude", ...,
                                    name = lap_prettify_label,
                                    na.value = lap_tokens()$colour$missing) {
  rlang::check_installed("scico", "for the lapidary scales")
  scico::scale_colour_scico_d(
    palette = resolve_palette(role), name = name, na.value = na.value, ...
  )
}

#' @rdname scale_lapidary
#' @export
scale_color_lapidary_d <- scale_colour_lapidary_d

#' A named vector of the semantic accent colours
#'
#' Handy for `scale_*_manual()` when mapping e.g. recharge vs discharge.
#'
#' @param variant `"light"` or `"dark"`.
#' @return A named character vector.
#' @export
lap_accents <- function(variant = c("light", "dark")) {
  col <- lap_tokens(rlang::arg_match(variant))$colour
  c(
    recharge = col$recharge,
    discharge = col$discharge,
    below_reference = col$below_reference,
    above_reference = col$above_reference
  )
}
