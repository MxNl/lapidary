# Proportional streamgraph of a composition over time

A 100%-stacked, smooth area chart of the output of
[`lap_summarise_composition()`](https://mxnl.github.io/lapidary/reference/lap_summarise_composition.md) -
e.g. the share of wells in each
[`lap_add_quantile_class()`](https://mxnl.github.io/lapidary/reference/lap_add_quantile_class.md)
percentile band, week by week. Every column sums to 100%, so the shape
shows how the *mix* shifts over time, not absolute counts.

## Usage

``` r
lap_plot_stream(
  data,
  category,
  x = date,
  ...,
  smooth = 0,
  curve = TRUE,
  n_grid = 400,
  border_colour = NA,
  role = "anomaly",
  direction = -1,
  variant = lap_variant(),
  lang = NULL,
  annotate = getOption("lapidary.annotate", NA),
  base_size = NULL,
  preset = NULL,
  title = NULL,
  subtitle = NULL,
  caption = NULL
)
```

## Arguments

- data:

  The tibble from
  [`lap_summarise_composition()`](https://mxnl.github.io/lapidary/reference/lap_summarise_composition.md)
  (`x`, `category`, `n`).

- category:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the categorical column to stack, ideally an ordered factor (its level
  order becomes the bottom-to-top stacking order).

- x:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the time-bucket column. Default `date`.

- ...:

  Passed to the underlying
  [`scale_fill_lapidary_d()`](https://mxnl.github.io/lapidary/reference/scale_lapidary.md).
  Its legend defaults to `guide = guide_legend(reverse = TRUE)` so the
  legend reads low-to-high bottom-to-top too, matching the stack; pass
  your own `guide` to override.

- smooth:

  Centred rolling-mean window (in buckets) applied to each category's
  `n` before stacking - tames real week-to-week/month-to-month *noise*.
  `0`/`1` (default) leaves the values as-is. Use
  [`lap_summarise_composition()`](https://mxnl.github.io/lapidary/reference/lap_summarise_composition.md)'s
  `period =` first if what you want is a coarser *time bucket* (e.g.
  `"month"` or `"year"`), not smoothing of a weekly series.

- curve:

  Round the stream's edges into a smooth curve by spline-interpolating
  each category's series onto a finer x grid before drawing, instead of
  the straight-line segments a plain stacked area chart draws between
  buckets. `TRUE` by default; set `FALSE` for the literal, unsmoothed
  polygon.

- n_grid:

  Number of x positions in that finer grid (at least the number of
  buckets already present). Default 400.

- border_colour:

  Outline colour drawn between adjacent bands (a thin cut-out seam so
  touching bands stay visually separated). `NA` (default) draws no
  outline.

- role, direction:

  Passed to the fill scale. Default `role = "anomaly"` (a divergent
  palette), a good fit for an odd number of ordered categories centred
  on a "normal" middle band; `direction = -1` puts the low end of the
  palette on the *high* category (so, for
  [`lap_add_quantile_class()`](https://mxnl.github.io/lapidary/reference/lap_add_quantile_class.md),
  "very low" reads as the warm/dry colour and "very high" as the
  cool/wet one - the hydrological drought-index convention).

- variant, lang, annotate, base_size, preset, title, subtitle, caption:

  See
  [lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md).

## Value

A
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html).

## See also

[`lap_add_quantile_class()`](https://mxnl.github.io/lapidary/reference/lap_add_quantile_class.md),
[`lap_summarise_composition()`](https://mxnl.github.io/lapidary/reference/lap_summarise_composition.md)

## Examples

``` r
if (FALSE) { # \dontrun{
gems_ger_sample |>
  lap_add_quantile_class() |>
  lap_summarise_composition(gwl_class) |>
  lap_plot_stream(gwl_class)

# coarser time bucket + no extra curve smoothing
gems_ger_sample |>
  lap_add_quantile_class() |>
  lap_summarise_composition(gwl_class, period = "month") |>
  lap_plot_stream(gwl_class, curve = FALSE)
} # }
```
