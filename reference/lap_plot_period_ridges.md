# Stacked period distributions (ridgelines)

Takes the long output of
[`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md)
(`by` column(s), an ordered `period` factor, and `ind_*` columns) and
draws one density ridge per period, stacked, so you can see a
distribution shift as the periods advance. Each ridge is filled by its
median value on the map palette.

## Usage

``` r
lap_plot_period_ridges(
  data,
  value,
  ...,
  height = 1.6,
  role = "magnitude",
  direction = 1,
  robust = getOption("lapidary.scale_robust", FALSE),
  range = getOption("lapidary.scale_range", FALSE),
  variant = lap_variant(),
  lang = NULL,
  annotate = getOption("lapidary.annotate", "caption"),
  base_size = NULL,
  preset = NULL,
  title = NULL,
  subtitle = NULL,
  caption = NULL
)
```

## Arguments

- data:

  The long tibble from
  [`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md).

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the `ind_*` column to plot.

- ...:

  Passed to the underlying
  [`scale_fill_lapidary_c()`](https://mxnl.github.io/lapidary/reference/scale_lapidary.md).

- height:

  Ridge height as a multiple of the row spacing. Default 1.6 (ridges
  overlap a little).

- role, direction, robust, range:

  Passed to the fill scale.

- variant, lang, annotate, base_size, preset, title, subtitle, caption:

  See
  [lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md).

## Value

A
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html).

## See also

[`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md),
[`lap_plot_delta_map()`](https://mxnl.github.io/lapidary/reference/lap_plot_delta_map.md),
[`lap_plot_distribution()`](https://mxnl.github.io/lapidary/reference/lap_plot_distribution.md)

## Examples

``` r
if (FALSE) { # \dontrun{
chg <- lap_indicator_change(
  gems_ger_sample, "amplitude",
  periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
)
lap_plot_period_ridges(chg, ind_amplitude)
} # }
```
