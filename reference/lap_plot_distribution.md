# Distribution of one indicator across wells

A histogram, density, raincloud or dot plot of a single `ind_*` column
(from
[`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md)),
coloured on the same palette the maps use, so a distribution panel reads
consistently with a choropleth of the same metric.

## Usage

``` r
lap_plot_distribution(
  data,
  value,
  ...,
  group = NULL,
  geom = c("histogram", "density", "raincloud", "dots"),
  bins = 30,
  role = "magnitude",
  direction = 1,
  robust = getOption("lapidary.scale_robust", FALSE),
  range = getOption("lapidary.scale_range", FALSE),
  rug = FALSE,
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

  A plain data frame with the value column (e.g. from
  [`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md)
  or
  [`lap_summarise_wells()`](https://mxnl.github.io/lapidary/reference/lap_summarise_wells.md)).

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the column to plot.

- ...:

  Passed to the underlying `scale_*_lapidary_c()`.

- group:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  optional split - facets for `"histogram"` / `"density"`, rows for
  `"raincloud"` / `"dots"`.

- geom:

  `"histogram"` (default), `"density"`, `"raincloud"` or `"dots"`. The
  last two need ggdist.

- bins:

  Histogram bin count. Default 30.

- role, direction, robust, range:

  Passed to the fill scale.

- rug:

  Add a marginal rug of the raw values.

- variant, lang, annotate, base_size, preset, title, subtitle, caption:

  See
  [lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md).

## Value

A
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html).

## See also

[lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md),
[`lap_indicator_registry()`](https://mxnl.github.io/lapidary/reference/lap_indicator_registry.md)

## Examples

``` r
if (FALSE) { # \dontrun{
ind <- lap_indicators(gems_ger_sample, "amplitude")
lap_plot_distribution(ind, ind_amplitude)
lap_plot_distribution(ind, ind_amplitude, geom = "raincloud")
} # }
```
