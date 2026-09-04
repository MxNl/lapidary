# Two indicators against each other

A well-level scatter of `x` vs `y` (columns from
[`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md)
/
[`lap_summarise_wells()`](https://mxnl.github.io/lapidary/reference/lap_summarise_wells.md)),
optionally coloured by a third indicator on the lapidary palette. Axis
labels carry the catalogue unit.

## Usage

``` r
lap_plot_indicator_scatter(
  data,
  x,
  y,
  colour = NULL,
  ...,
  smooth = FALSE,
  rug = FALSE,
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

  A plain data frame with the `x` / `y` (/ `colour`) columns.

- x, y:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the columns for the two axes.

- colour:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  optional third column to colour points by.

- ...:

  Passed to the underlying
  [`scale_colour_lapidary_c()`](https://mxnl.github.io/lapidary/reference/scale_lapidary.md)
  (only used when `colour` is given).

- smooth:

  Add a linear
  [`geom_smooth()`](https://ggplot2.tidyverse.org/reference/geom_smooth.html)
  fit.

- rug:

  Add marginal rugs.

- role, direction, robust, range:

  Passed to the colour scale.

- variant, lang, annotate, base_size, preset, title, subtitle, caption:

  See
  [lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md).

## Value

A
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html).

## See also

[lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md),
[`lap_plot_distribution()`](https://mxnl.github.io/lapidary/reference/lap_plot_distribution.md)

## Examples

``` r
if (FALSE) { # \dontrun{
ind <- lap_indicators(gems_ger_sample, c("memory", "flashiness"))
lap_plot_indicator_scatter(ind, ind_memory_weeks, ind_flashiness, smooth = TRUE)
} # }
```
