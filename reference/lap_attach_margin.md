# Attach a marginal distribution to a plot

Adds a thin histogram / density / raincloud of `value` alongside `plot`,
sharing the same fill scale, and returns the pair as a
[patchwork::patchwork](https://patchwork.data-imaginist.com/reference/patchwork-package.html).
The map builders call this for their `margin` argument; call it directly
to put a marginal on any plot whose fill is on a `scale_*_lapidary_c()`.

## Usage

``` r
lap_attach_margin(
  plot,
  data,
  value,
  side = c("bottom", "right"),
  type = c("histogram", "density", "raincloud"),
  size = 0.18,
  bins = 30,
  role = "magnitude",
  direction = 1,
  robust = FALSE,
  range = FALSE,
  limits = NULL,
  variant = NULL,
  lang = NULL
)
```

## Arguments

- plot:

  A ggplot (typically a map from
  [`lap_plot_hex_map()`](https://mxnl.github.io/lapidary/reference/lap_plot_map.md)).

- data:

  The data the marginal is computed from (the same layer / table).

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the column to summarise (the one `plot` is coloured by).

- side:

  `"bottom"` (default) or `"right"`.

- type:

  `"histogram"` (default), `"density"` or `"raincloud"` (`"raincloud"`
  needs ggdist).

- size:

  Marginal thickness as a fraction of the main plot. Default 0.18.

- bins:

  Histogram bin count.

- role, direction, robust, range, limits:

  Fill-scale parameters - pass the same values the main plot used so the
  gradients match.

- variant, lang:

  See
  [lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md).

## Value

A
[patchwork::patchwork](https://patchwork.data-imaginist.com/reference/patchwork-package.html).

## See also

[`lap_plot_hex_map()`](https://mxnl.github.io/lapidary/reference/lap_plot_map.md)
