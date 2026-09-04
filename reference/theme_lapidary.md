# The lapidary ggplot2 theme

A minimal, map-friendly theme shared by every lapidary graphic. It
strips panel furniture, uses the design-token colours for the chosen
`variant` and scales all type sizes from a single `base_size`, so the
*same* plot object can be rendered small for the web and large for an A0
poster just by changing `base_size` (see
[`ggsave_lapidary()`](https://mxnl.github.io/lapidary/reference/ggsave_lapidary.md),
which does this for you).

## Usage

``` r
theme_lapidary(
  variant = lap_variant(),
  base_size = 11,
  panel = c("map", "xy", "ridge", "polar"),
  tokens = NULL,
  map = NULL
)
```

## Arguments

- variant:

  `"light"` or `"dark"`. Defaults to
  [`lap_variant()`](https://mxnl.github.io/lapidary/reference/lap_variant.md).

- base_size:

  Base font size in points. Downstream builders typically leave this at
  the default and let
  [`ggsave_lapidary()`](https://mxnl.github.io/lapidary/reference/ggsave_lapidary.md)
  override it.

- panel:

  Which panel furniture to blank, matched to the chart family: `"map"`
  (default; no axes/grid, for choropleths), `"xy"` (Cartesian
  time-series/scatter: keep the y grid, drop minor + x grid), `"ridge"`
  (drop the y grid and y ticks, keep the x axis), `"polar"`
  (radial/month rings: no axis titles/ticks, keep the radial grid).

- tokens:

  A token list from
  [`lap_tokens()`](https://mxnl.github.io/lapidary/reference/lap_tokens.md);
  computed from `variant` if `NULL`.

- map:

  Deprecated; use `panel` instead (`map = TRUE` -\> `panel = "map"`,
  `map = FALSE` -\> `panel = "xy"`).

## Value

A [ggplot2::theme](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
ggplot(mtcars, aes(mpg, wt)) +
  geom_point() +
  theme_lapidary(variant = "dark", panel = "xy")
} # }
```
