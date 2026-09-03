# lapidary continuous fill / colour scales

`role` selects a scico palette by its purpose: `"months"` (cyclic),
`"magnitude"`/`"magnitude_dark"` (sequential), `"density"` (sequential
greys), `"anomaly"` (divergent).

## Usage

``` r
scale_fill_lapidary_c(
  role = "magnitude",
  ...,
  na.value = lap_tokens()$colour$missing
)

scale_colour_lapidary_c(
  role = "magnitude",
  ...,
  na.value = lap_tokens()$colour$missing
)

scale_color_lapidary_c(
  role = "magnitude",
  ...,
  na.value = lap_tokens()$colour$missing
)

scale_fill_lapidary_d(
  role = "magnitude",
  ...,
  na.value = lap_tokens()$colour$missing
)

scale_colour_lapidary_d(
  role = "magnitude",
  ...,
  na.value = lap_tokens()$colour$missing
)

scale_color_lapidary_d(
  role = "magnitude",
  ...,
  na.value = lap_tokens()$colour$missing
)
```

## Arguments

- role:

  One of
  [`lap_pal_roles()`](https://mxnl.github.io/lapidary/reference/lap_pal_roles.md).

- ...:

  Passed to
  [`scico::scale_fill_scico()`](https://rdrr.io/pkg/scico/man/ggplot2-scales.html)
  /
  [`scico::scale_colour_scico()`](https://rdrr.io/pkg/scico/man/ggplot2-scales.html)
  (e.g. `limits`, `direction`, `na.value`).

- na.value:

  Colour for `NA`. Defaults to the token `missing` colour.

## Value

A ggplot2 scale.

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
  geom_raster() +
  scale_fill_lapidary_c("magnitude")
} # }
```
