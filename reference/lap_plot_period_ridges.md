# Stacked period distributions (ridgelines)

Takes the long output of
[`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md)
(`by` column(s), an ordered `period` factor, and `ind_*` columns) and
draws one density ridge per period, stacked earliest-on-top so reading
down the plot follows time. Each ridge is filled with the continuous
lapidary palette along the value axis (as the maps and
[`lap_plot_distribution()`](https://mxnl.github.io/lapidary/reference/lap_plot_distribution.md)
are), outlined in the background colour so overlapping ridges stay
legible.

## Usage

``` r
lap_plot_period_ridges(
  data,
  value,
  ...,
  overlap = 1.4,
  interpret = TRUE,
  low_label = NULL,
  high_label = NULL,
  role = "magnitude",
  direction = 1,
  robust = getOption("lapidary.scale_robust", FALSE),
  range = getOption("lapidary.scale_range", FALSE),
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

  The long tibble from
  [`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md).

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the `ind_*` column to plot.

- ...:

  Passed to the underlying
  [`scale_fill_lapidary_c()`](https://mxnl.github.io/lapidary/reference/scale_lapidary.md).

- overlap:

  Ridge overlap, passed to `ggridges` as `scale`: `1` makes the tallest
  ridge just reach the next baseline; the default `1.4` overlaps the
  ridges (the background-colour outline keeps them readable), `> 2` is a
  dense "Joy Division" stack.

- interpret:

  For the common indicators, label the value axis with what a low vs a
  high value means (`"<low> <- Indicator -> <high>"`). `TRUE` by
  default; has no effect for a column without a stored interpretation.
  `low_label` / `high_label` set or override the wording for any column.

- low_label, high_label:

  Words for the low / high end of the value axis. Both must resolve
  (from here or the registry) for the directional label to appear.

- role, direction, robust, range:

  Passed to the fill scale.

- variant, lang, annotate, base_size, preset, title, subtitle, caption:

  See
  [lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md).

## Value

A
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html).

## Details

Needs ggridges.

## See also

[`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md),
[`lap_plot_delta_map()`](https://mxnl.github.io/lapidary/reference/lap_plot_delta_map.md),
[`lap_plot_distribution()`](https://mxnl.github.io/lapidary/reference/lap_plot_distribution.md)

## Examples

``` r
if (FALSE) { # \dontrun{
chg <- lap_indicator_change(
  gems_ger_sample, "amplitude",
  periods = lap_period_windows(gems_ger_sample, "decade_per_decade")
)
lap_plot_period_ridges(chg, ind_amplitude)
lap_plot_period_ridges(chg, ind_trend_slope,
  low_label = "falling levels", high_label = "rising levels"
)
} # }
```
