# Temporal-evolution builder: a year x month/week calendar heatmap.
# See docs/adr/0012 for the builder contract.

#' Calendar heatmap
#'
#' A year x month (or year x week) tile grid, coloured by `value` - e.g. the
#' output of [lap_summarise_calendar()] (how many wells set a new record that
#' month), one tile per bucket. `facet` draws several such grids stacked on
#' one shared scale instead, e.g. new-low counts above new-high counts.
#'
#' Unlike most `lap_plot_*()` builders, the default how-to explanation is
#' placed in the plot **subtitle**, not the caption - it reads better directly
#' above the panel it describes, especially with the month/week labels also
#' at the top of the panel. `annotate = "callout"` still places it in an
#' on-panel box instead; the user's own `caption` argument is unaffected
#' either way.
#'
#' @param data The tibble from [lap_summarise_calendar()] (`year`, `unit`,
#'   `value`, optionally `facet`).
#' @param value <[`tidy-select`][dplyr::dplyr_tidy_select]> the column to
#'   colour tiles by.
#' @param year,unit <[`tidy-select`][dplyr::dplyr_tidy_select]> the calendar
#'   columns. Defaults `year` / `unit` (what [lap_summarise_calendar()]
#'   produces, whether `unit` holds months or ISO weeks).
#' @param facet <[`tidy-select`][dplyr::dplyr_tidy_select]> optional column to
#'   stack separate calendars by (one grid per level, `ncol = 1`), sharing one
#'   fill scale.
#' @param ... Passed to the underlying fill scale - `scale_fill_lapidary_c()`
#'   when `midpoint` is `NULL`, or a bespoke [ggplot2::continuous_scale()]
#'   built from the full `role` palette when a `midpoint` is given.
#' @param unit_labels Labels for the `unit` axis. `NULL` (default) uses
#'   localised month abbreviations when `unit`'s values are all `<= 12`
#'   (assumed to be calendar months), otherwise plain numbers (e.g. ISO
#'   weeks).
#' @param border_colour Outline colour between tiles. Defaults to the
#'   variant's background colour (a visible gap, unlike [lap_plot_stream()]'s
#'   seamless default) - pass `NA` for none.
#' @param role,direction,robust Passed to the fill scale. Default `role =
#'   "magnitude"` (sequential, for a count). `robust` squishes values beyond
#'   a data-aware quantile threshold onto the same end colour, so a few
#'   extreme buckets don't wash out the variation in the rest of the grid.
#' @param midpoint `NULL` (default) draws a sequential `role = "magnitude"`
#'   scale for a count. Set it (e.g. `0`) for a **divergent** scale instead -
#'   a smooth gradient built from the full `role` palette (not just its two
#'   end colours), with only the exact centre colour swapped for the
#'   variant's own background colour - genuinely neutral, and blends into the
#'   page in light mode / the panel in dark mode. Built as a bespoke smooth
#'   scale rather than the package's usual binned steps, because binning has
#'   no notion of `midpoint`: a value of exactly `midpoint` could land on a
#'   bin edge and inherit that bin's colour instead of the true neutral one.
#'   `direction = -1` puts the low end of the palette on the high value (see
#'   examples) - the hydrological low/dry-high/wet convention used elsewhere
#'   in the package.
#' @param low_label,high_label Words for what a low / a high value means
#'   (e.g. `"more new lows"` / `"more new highs"`). With `midpoint` set, these
#'   are woven into a sentence naming the actual rendered colours (assumes
#'   the `"anomaly"`/vik convention of low = red, high = blue - the package's
#'   only divergent role today; revisit this wording if a second divergent
#'   role is ever added), with a generic "a low/high value" fallback when
#'   they're not supplied. Without `midpoint`, a plain arrow sentence is
#'   appended only when both are given.
#' @param variant,lang,annotate,base_size,preset,title,subtitle,caption See
#'   [lap_plot_map].
#'
#' @return A [ggplot2::ggplot].
#' @seealso [lap_add_record_flags()], [lap_summarise_calendar()]
#' @export
#' @examples
#' \dontrun{
#' # one divergent panel: the balance of new-high vs new-low record years
#' cal <- gems_ger_sample |>
#'   lap_add_record_flags() |>
#'   lap_summarise_calendar(record_balance)
#' lap_plot_calendar(
#'   cal, n,
#'   role = "anomaly", direction = -1, midpoint = 0, robust = TRUE,
#'   low_label = "more new lows", high_label = "more new highs"
#' )
#'
#' # or two sequential panels, one per series' own magnitude
#' cal2 <- gems_ger_sample |>
#'   lap_add_record_flags() |>
#'   lap_summarise_calendar(is_new_min, is_new_max)
#' lap_plot_calendar(cal2, n, facet = name)
#' }
lap_plot_calendar <- function(data, value, year = year, unit = unit, facet = NULL, ...,
                              unit_labels = NULL, border_colour = NULL,
                              role = "magnitude", direction = 1, midpoint = NULL,
                              robust = getOption("lapidary.scale_robust", FALSE),
                              low_label = NULL, high_label = NULL,
                              variant = lap_variant(), lang = NULL,
                              annotate = getOption("lapidary.annotate", NA),
                              base_size = NULL, preset = NULL,
                              title = NULL, subtitle = NULL, caption = NULL) {
  rlang::check_installed("ggplot2", "for `lap_plot_calendar()`")
  check_table(data)
  if (missing(year) && missing(unit) && !all(c("year", "unit") %in% names(data))) {
    cli::cli_abort(c(
      "{.arg data} needs {.field year} and {.field unit} columns.",
      i = "Use the output of {.fn lap_summarise_calendar}, or pass your own via {.arg year} / {.arg unit}."
    ))
  }
  a <- resolve_builder_args(variant, lang, base_size, preset)
  value <- lap_eval_select_one(data, rlang::enquo(value), arg = "value")
  year_col <- lap_eval_select_one(data, rlang::enquo(year), arg = "year")
  unit_col <- lap_eval_select_one(data, rlang::enquo(unit), arg = "unit")
  facet_col <- lap_eval_select_one(
    data, rlang::enquo(facet), arg = "facet", null_ok = TRUE
  )

  df <- tibble::as_tibble(data)
  years <- sort(unique(df[[year_col]]))
  df[[year_col]] <- factor(df[[year_col]], levels = rev(years))
  border_colour <- border_colour %||% a$tokens$colour$background

  # tiles are 1 unit wide/tall; expand exactly half a tile so they fill the
  # panel edge-to-edge instead of leaving a gridline-exposing sliver
  tile_expand <- ggplot2::expansion(add = 0.5)
  unit_vals <- sort(unique(df[[unit_col]]))
  x_scale <- if (!is.null(unit_labels)) {
    ggplot2::scale_x_continuous(
      breaks = unit_vals, labels = unit_labels, expand = tile_expand, position = "top"
    )
  } else if (max(unit_vals, na.rm = TRUE) <= 12) {
    ggplot2::scale_x_continuous(
      breaks = 1:12, labels = lap_tr("months_short", a$lang), expand = tile_expand,
      position = "top"
    )
  } else {
    ggplot2::scale_x_continuous(
      breaks = scales::pretty_breaks(), expand = tile_expand, position = "top"
    )
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[[unit_col]], y = .data[[year_col]], fill = .data[[value]]
  )) +
    ggplot2::geom_tile(colour = border_colour, linewidth = 0.3, na.rm = TRUE) +
    ggplot2::scale_y_discrete(expand = tile_expand)

  if (!is.null(facet_col)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data[[facet_col]]), ncol = 1)
  }

  probs <- if (!is.null(midpoint)) resolve_robust_probs(robust) else NULL

  fill_scale <- if (is.null(midpoint)) {
    scale_fill_lapidary_c(role, direction = direction, robust = robust, ...)
  } else {
    # a bespoke smooth divergent scale built from the full role palette (not
    # just its two end colours), with only the exact centre stop swapped for
    # the variant's own background colour - genuinely neutral, and blends
    # into the page/panel - unlike the palette's native centre, which is
    # never guaranteed neutral and, on the package's usual binned steps, may
    # not even land on a bin centre
    n_stops <- 255 # odd -> a stop lands exactly at the rescaled centre
    stops <- scico::scico(n_stops, palette = resolve_palette(role), direction = direction)
    stops[[(n_stops + 1) / 2]] <- a$tokens$colour$background
    limits <- if (!is.null(probs) && any(is.finite(df[[value]]))) {
      lap_robust_limits(df[[value]], probs, midpoint)
    } else {
      NULL
    }
    do.call(ggplot2::continuous_scale, c(
      list(
        aesthetics = "fill", palette = scales::gradient_n_pal(stops),
        name = lap_prettify_label(value), limits = limits,
        rescaler = lap_mid_rescaler(midpoint),
        oob = if (!is.null(probs)) scales::oob_squish else scales::censor,
        na.value = a$tokens$colour$missing,
        guide = lap_colourbar_guide(variant = a$variant)
      ),
      list(...)
    ))
  }

  p <- p +
    fill_scale +
    x_scale +
    ggplot2::labs(
      x = NULL, y = NULL, title = title, subtitle = subtitle, caption = caption
    ) +
    theme_lapidary(a$variant, base_size = a$base_size, panel = "xy") +
    # the tiles already delineate the grid; panel.grid.major.y (which "xy"
    # otherwise keeps, for scatter/time-series builders) just peeks out in a
    # thin sliver past the last tile column
    ggplot2::theme(panel.grid = ggplot2::element_blank())

  if (annotate_enabled(annotate)) {
    # built once, regardless of where it ends up, so `callout` gets exactly
    # the same content (including dynamic value_label/colour substitution)
    # as the default subtitle placement - not just the generic base text
    base_text <- if (identical(annotate, "caption") || identical(annotate, "callout") ||
      isTRUE(annotate)) {
      lap_tr("howto_calendar", a$lang, value_label = lap_prettify_label(value))
    } else {
      as.character(annotate) # caller's own custom override text
    }
    fragments <- c(base_text)
    if (!is.null(midpoint)) {
      low_word <- low_label %||% lap_tr("calendar_low_generic", a$lang)
      high_word <- high_label %||% lap_tr("calendar_high_generic", a$lang)
      fragments <- c(fragments, lap_tr(
        "howto_calendar_divergent", a$lang,
        low_colour = stops[[1]], low_label = low_word,
        high_colour = stops[[n_stops]], high_label = high_word
      ))
    } else if (!is.null(low_label) && !is.null(high_label)) {
      fragments <- c(fragments, paste0(low_label, "  \u2190   \u2192  ", high_label))
    }
    if (!is.null(probs)) fragments <- c(fragments, lap_tr("howto_calendar_squished", a$lang))
    combined <- paste(fragments, collapse = "\n")

    if (identical(annotate, "callout")) {
      p <- lap_annotate_howto(
        p, text = combined, placement = "callout",
        lang = a$lang, variant = a$variant, tokens = a$tokens
      )
    } else {
      prev <- p$labels$subtitle
      keep <- !is.null(prev) && !inherits(prev, "waiver") && nzchar(prev)
      p <- p +
        ggplot2::labs(subtitle = paste(c(if (keep) prev, combined), collapse = "\n")) +
        ggplot2::theme(plot.subtitle = howto_subtitle_element(a$tokens))
    }
  }
  p
}
