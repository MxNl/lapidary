# Add a "no data" key for NA regions

ggplot2's colour-bar and colour-steps guides do not show an `NA` entry.
Add `+ lap_na_guide()` after a
[scale_lapidary](https://mxnl.github.io/lapidary/reference/scale_lapidary.md)
scale to draw a single swatch (an invisible layer on the unused `shape`
aesthetic) for the `na.value` colour - e.g. hexagons with no wells.

## Usage

``` r
lap_na_guide(
  label = "no data",
  colour = lap_tokens()$colour$missing,
  order = 2
)
```

## Arguments

- label:

  Key label. Defaults to `"no data"`.

- colour:

  Swatch colour. Defaults to the token `missing` colour (match the
  scale's `na.value`).

- order:

  Legend order (passed to
  [`ggplot2::guide_legend()`](https://ggplot2.tidyverse.org/reference/guide_legend.html));
  the default 2 keeps the NA key below a
  [`lap_coloursteps_guide()`](https://mxnl.github.io/lapidary/reference/lap_coloursteps_guide.md)
  bar (order 1).

## Value

A list of ggplot2 layers/scales to add to a plot with `+`.

## See also

[scale_lapidary](https://mxnl.github.io/lapidary/reference/scale_lapidary.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
data(germany_hex_sample, package = "lapidary")
ggplot(germany_hex_sample) +
  geom_sf(aes(fill = mean_gwl)) +
  scale_fill_lapidary_c("magnitude") +
  lap_na_guide()
} # }
```
