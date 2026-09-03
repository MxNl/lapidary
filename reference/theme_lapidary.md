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
  variant = c("light", "dark"),
  base_size = 11,
  map = TRUE,
  tokens = NULL
)
```

## Arguments

- variant:

  `"light"` (default) or `"dark"`.

- base_size:

  Base font size in points. Downstream builders typically leave this at
  the default and let
  [`ggsave_lapidary()`](https://mxnl.github.io/lapidary/reference/ggsave_lapidary.md)
  override it.

- map:

  If `TRUE` (default) also blanks axis text/ticks/grid, which is what
  the hex-map builders want; set `FALSE` for time-series panels.

- tokens:

  A token list from
  [`lap_tokens()`](https://mxnl.github.io/lapidary/reference/lap_tokens.md);
  computed from `variant` if `NULL`.

## Value

A [ggplot2::theme](https://ggplot2.tidyverse.org/reference/theme.html)
object.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
ggplot(mtcars, aes(mpg, wt)) +
  geom_point() +
  theme_lapidary(variant = "dark", map = FALSE)
} # }
```
