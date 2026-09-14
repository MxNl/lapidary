# Temporal-evolution builder: composition of a categorical state over time.
# See docs/adr/0012 for the builder contract.

#' Proportional streamgraph of a composition over time
#'
#' A 100%-stacked, smooth area chart of the output of
#' [lap_summarise_composition()] - e.g. the share of wells in each
#' [lap_add_quantile_class()] percentile band, week by week. Every column
#' sums to 100%, so the shape shows how the *mix* shifts over time, not
#' absolute counts.
#'
#' @param data The tibble from [lap_summarise_composition()] (`x`, `category`,
#'   `n`).
#' @param category <[`tidy-select`][dplyr::dplyr_tidy_select]> the categorical
#'   column to stack, ideally an ordered factor (its level order becomes the
#'   bottom-to-top stacking order).
#' @param x <[`tidy-select`][dplyr::dplyr_tidy_select]> the time-bucket column.
#'   Default `date`.
#' @param ... Passed to the underlying `scale_fill_lapidary_d()`. Its legend
#'   defaults to `guide = guide_legend(reverse = TRUE)` so the legend reads
#'   low-to-high bottom-to-top too, matching the stack; pass your own `guide`
#'   to override.
#' @param smooth Centred rolling-mean window (in buckets) applied to each
#'   category's `n` before stacking - tames real week-to-week/month-to-month
#'   *noise*. `0`/`1` (default) leaves the values as-is. Use
#'   [lap_summarise_composition()]'s `period =` first if what you want is a
#'   coarser *time bucket* (e.g. `"month"` or `"year"`), not smoothing of a
#'   weekly series.
#' @param curve Round the stream's edges into a smooth curve by
#'   spline-interpolating each category's series onto a finer x grid before
#'   drawing, instead of the straight-line segments a plain stacked area chart
#'   draws between buckets. `TRUE` by default; set `FALSE` for the literal,
#'   unsmoothed polygon.
#' @param n_grid Number of x positions in that finer grid (at least the number
#'   of buckets already present). Default 400.
#' @param border_colour Outline colour drawn between adjacent bands (a thin
#'   cut-out seam so touching bands stay visually separated). `NA` (default)
#'   draws no outline.
#' @param role,direction Passed to the fill scale. Default `role = "anomaly"`
#'   (a divergent palette), a good fit for an odd number of ordered categories
#'   centred on a "normal" middle band; `direction = -1` puts the low end of
#'   the palette on the *high* category (so, for [lap_add_quantile_class()],
#'   "very low" reads as the warm/dry colour and "very high" as the cool/wet
#'   one - the hydrological drought-index convention).
#' @param variant,lang,annotate,base_size,preset,title,subtitle,caption See
#'   [lap_plot_map].
#'
#' @return A [ggplot2::ggplot].
#' @seealso [lap_add_quantile_class()], [lap_summarise_composition()]
#' @export
#' @examples
#' \dontrun{
#' gems_ger_sample |>
#'   lap_add_quantile_class() |>
#'   lap_summarise_composition(gwl_class) |>
#'   lap_plot_stream(gwl_class)
#'
#' # coarser time bucket + no extra curve smoothing
#' gems_ger_sample |>
#'   lap_add_quantile_class() |>
#'   lap_summarise_composition(gwl_class, period = "month") |>
#'   lap_plot_stream(gwl_class, curve = FALSE)
#' }
lap_plot_stream <- function(data, category, x = date, ...,
                            smooth = 0, curve = TRUE, n_grid = 400,
                            border_colour = NA,
                            role = "anomaly", direction = -1,
                            variant = lap_variant(), lang = NULL,
                            annotate = getOption("lapidary.annotate", "caption"),
                            base_size = NULL, preset = NULL,
                            title = NULL, subtitle = NULL, caption = NULL) {
  rlang::check_installed("ggplot2", "for `lap_plot_stream()`")
  check_table(data)
  if (!"n" %in% names(data)) {
    cli::cli_abort(c(
      "{.arg data} needs an {.field n} column.",
      i = "Use the output of {.fn lap_summarise_composition}."
    ))
  }
  a <- resolve_builder_args(variant, lang, base_size, preset)
  category <- lap_eval_select_one(data, rlang::enquo(category), arg = "category")
  x_col <- lap_eval_select_one(data, rlang::enquo(x), arg = "x")

  df <- tibble::as_tibble(data)
  df <- df[order(df[[x_col]]), ]
  if (isTRUE(smooth > 1)) {
    df[["n"]] <- stats::ave(df[["n"]], df[[category]], FUN = function(v) {
      sm <- stats::filter(v, rep(1 / smooth, smooth), sides = 2)
      ifelse(is.na(sm), v, as.numeric(sm))
    })
  }
  if (isTRUE(curve) && length(unique(df[[x_col]])) >= 3L) {
    df <- stream_curve(df, x_col, category, n_grid)
  }

  # the fill legend reads top-to-bottom in level order by default; reverse it
  # so it reads low-to-high bottom-to-top too, matching the stack below (the
  # first level is always the bottom band - see position_fill(reverse=TRUE)).
  dots <- rlang::list2(...)
  dots$guide <- dots$guide %||% ggplot2::guide_legend(reverse = TRUE)

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[[x_col]], y = .data$n, fill = .data[[category]]
  )) +
    ggplot2::geom_area(
      position = ggplot2::position_fill(reverse = TRUE),
      colour = border_colour, linewidth = 0.15, na.rm = TRUE
    ) +
    do.call(scale_fill_lapidary_d, c(list(role, direction = direction), dots)) +
    ggplot2::scale_y_continuous(labels = scales::percent, expand = c(0, 0)) +
    ggplot2::labs(
      x = NULL, y = NULL, title = title, subtitle = subtitle, caption = caption
    ) +
    theme_lapidary(a$variant, base_size = a$base_size, panel = "xy")

  apply_howto(p, annotate, "stream", a$lang, a$variant, a$tokens)
}

# Round a stacked series' polygon corners into a smooth curve: spline-
# interpolate each category's `n` onto a common, finer x grid (natural cubic
# spline; clamped to >= 0 since a share/count can't go negative). `df` must
# already have every category present at every x (as lap_summarise_composition()
# guarantees), so every category interpolates over the same x range.
stream_curve <- function(df, x_col, category, n_grid) {
  is_date <- inherits(df[[x_col]], "Date")
  is_fct <- is.factor(df[[category]])
  cat_levels <- if (is_fct) levels(df[[category]]) else NULL
  cat_ordered <- is_fct && is.ordered(df[[category]])

  xn <- as.numeric(df[[x_col]])
  grid <- seq(min(xn), max(xn), length.out = max(n_grid, length(unique(xn))))

  parts <- split(df, df[[category]])
  out <- do.call(rbind, lapply(names(parts), function(lev) {
    part <- parts[[lev]]
    fit <- stats::spline(as.numeric(part[[x_col]]), part[["n"]], xout = grid, method = "natural")
    row <- data.frame(
      x = if (is_date) as.Date(fit$x, origin = "1970-01-01") else fit$x,
      cat = if (is_fct) factor(lev, levels = cat_levels, ordered = cat_ordered) else lev,
      n = pmax(fit$y, 0)
    )
    names(row)[1:2] <- c(x_col, category)
    row
  }))
  tibble::as_tibble(out)
}
