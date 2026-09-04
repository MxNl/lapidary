# Starting value against its change

A well-level scatter of an indicator's value in the `from` period (x)
against how much it changed by the `to` period (y), from the wide output
of
[`lap_indicator_delta()`](https://mxnl.github.io/lapidary/reference/lap_indicator_delta.md).
A tilted cloud means wells that started high changed differently from
wells that started low.

## Usage

``` r
lap_plot_change_scatter(
  data,
  value,
  ...,
  smooth = TRUE,
  rug = FALSE,
  direction = 1,
  binned = TRUE,
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

  The wide tibble from
  [`lap_indicator_delta()`](https://mxnl.github.io/lapidary/reference/lap_indicator_delta.md).

- value:

  The base indicator column, as a bare name or string.

- ...:

  Passed to the underlying
  [`scale_colour_lapidary_c()`](https://mxnl.github.io/lapidary/reference/scale_lapidary.md).

- smooth:

  Add a linear
  [`geom_smooth()`](https://ggplot2.tidyverse.org/reference/geom_smooth.html)
  fit. Default `TRUE`.

- rug:

  Add marginal rugs.

- direction, binned, robust, range:

  Passed to the colour scale.

- variant, lang, annotate, base_size, preset, title, subtitle, caption:

  See
  [lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md).

## Value

A
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html).

## Details

`data` carries the wide `<value>_<from>` / `<value>_change` columns;
`value` is the **base** indicator column name (e.g. `ind_amplitude`).

## See also

[`lap_indicator_delta()`](https://mxnl.github.io/lapidary/reference/lap_indicator_delta.md),
[`lap_plot_delta_map()`](https://mxnl.github.io/lapidary/reference/lap_plot_delta_map.md)

## Examples

``` r
if (FALSE) { # \dontrun{
chg <- lap_indicator_change(
  gems_ger_sample, "amplitude",
  periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
)
dl <- lap_indicator_delta(chg, "reference", "recent")
lap_plot_change_scatter(dl, ind_amplitude)
} # }
```
