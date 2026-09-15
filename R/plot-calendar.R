# Temporal-evolution builder: a year x month/week calendar heatmap.
# See docs/adr/0012 for the builder contract.

#' Calendar heatmap
#'
#' A year x month (or year x week) tile grid, coloured by `value` - e.g. the
#' output of [lap_summarise_calendar()] (how many wells set a new record that
#' month), one tile per bucket. `facet` draws several such grids stacked on
#' one shared scale instead, e.g. new-low counts above new-high counts.
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
#' @param ... Passed to the underlying `scale_fill_lapidary_c()`.
#' @param unit_labels Labels for the `unit` axis. `NULL` (default) uses
#'   localised month abbreviations when `unit`'s values are all `<= 12`
#'   (assumed to be calendar months), otherwise plain numbers (e.g. ISO
#'   weeks).
#' @param border_colour Outline colour between tiles. Defaults to the
#'   variant's background colour (a visible gap, unlike [lap_plot_stream()]'s
#'   seamless default) - pass `NA` for none.
#' @param role,direction Passed to the fill scale. Default `role =
#'   "magnitude"` (sequential, for a count); pass `role = "anomaly", direction
#'   = -1, midpoint = 0` yourself for a divergent net-balance calendar (see
#'   examples) - `direction = -1` reads a negative value warm and a positive
#'   one cool, the hydrological low/dry-high/wet convention used elsewhere in
#'   the package. For a divergent scale, also pass `binned = FALSE`: the
#'   package's binned-by-default scale picks its round-number breaks from the
#'   data range with no awareness of `midpoint`, so a value of exactly
#'   `midpoint` can land on a bin edge and inherit that bin's non-neutral
#'   colour instead of the palette's true neutral one - `binned = FALSE`'s
#'   smooth gradient doesn't have that ambiguity.
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
#' lap_plot_calendar(cal, n, role = "anomaly", direction = -1, midpoint = 0, binned = FALSE)
#'
#' # or two sequential panels, one per series' own magnitude
#' cal2 <- gems_ger_sample |>
#'   lap_add_record_flags() |>
#'   lap_summarise_calendar(is_new_min, is_new_max)
#' lap_plot_calendar(cal2, n, facet = name)
#' }
lap_plot_calendar <- function(data, value, year = year, unit = unit, facet = NULL, ...,
                              unit_labels = NULL, border_colour = NULL,
                              role = "magnitude", direction = 1,
                              variant = lap_variant(), lang = NULL,
                              annotate = getOption("lapidary.annotate", "caption"),
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
    ggplot2::scale_x_continuous(breaks = unit_vals, labels = unit_labels, expand = tile_expand)
  } else if (max(unit_vals, na.rm = TRUE) <= 12) {
    ggplot2::scale_x_continuous(
      breaks = 1:12, labels = lap_tr("months_short", a$lang), expand = tile_expand
    )
  } else {
    ggplot2::scale_x_continuous(breaks = scales::pretty_breaks(), expand = tile_expand)
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[[unit_col]], y = .data[[year_col]], fill = .data[[value]]
  )) +
    ggplot2::geom_tile(colour = border_colour, linewidth = 0.3, na.rm = TRUE) +
    ggplot2::scale_y_discrete(expand = tile_expand)

  if (!is.null(facet_col)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data[[facet_col]]), ncol = 1)
  }

  p <- p +
    scale_fill_lapidary_c(role, direction = direction, ...) +
    x_scale +
    ggplot2::labs(
      x = NULL, y = NULL, title = title, subtitle = subtitle, caption = caption
    ) +
    theme_lapidary(a$variant, base_size = a$base_size, panel = "xy") +
    # the tiles already delineate the grid; panel.grid.major.y (which "xy"
    # otherwise keeps, for scatter/time-series builders) just peeks out in a
    # thin sliver past the last tile column
    ggplot2::theme(panel.grid = ggplot2::element_blank())

  apply_howto(p, annotate, "calendar", a$lang, a$variant, a$tokens)
}
