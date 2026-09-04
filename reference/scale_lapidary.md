# lapidary continuous fill / colour scales

`role` selects a scico palette by its purpose: `"months"` (cyclic),
`"magnitude"`/`"magnitude_dark"` (sequential), `"density"` (sequential
greys), `"anomaly"` (divergent).

## Usage

``` r
scale_fill_lapidary_c(
  role = "magnitude",
  ...,
  name = lap_prettify_label,
  na.value = lap_tokens()$colour$missing,
  binned = TRUE,
  bins = 8,
  begin = 0,
  end = 1,
  direction = 1,
  midpoint = NULL,
  guide = NULL
)

scale_colour_lapidary_c(
  role = "magnitude",
  ...,
  name = lap_prettify_label,
  na.value = lap_tokens()$colour$missing,
  binned = TRUE,
  bins = 8,
  begin = 0,
  end = 1,
  direction = 1,
  midpoint = NULL,
  guide = NULL
)

scale_color_lapidary_c(
  role = "magnitude",
  ...,
  name = lap_prettify_label,
  na.value = lap_tokens()$colour$missing,
  binned = TRUE,
  bins = 8,
  begin = 0,
  end = 1,
  direction = 1,
  midpoint = NULL,
  guide = NULL
)

scale_fill_lapidary_d(
  role = "magnitude",
  ...,
  name = lap_prettify_label,
  na.value = lap_tokens()$colour$missing
)

scale_colour_lapidary_d(
  role = "magnitude",
  ...,
  name = lap_prettify_label,
  na.value = lap_tokens()$colour$missing
)

scale_color_lapidary_d(
  role = "magnitude",
  ...,
  name = lap_prettify_label,
  na.value = lap_tokens()$colour$missing
)
```

## Arguments

- role:

  One of
  [`lap_pal_roles()`](https://mxnl.github.io/lapidary/reference/lap_pal_roles.md).

- ...:

  Passed to the underlying scale
  ([`ggplot2::binned_scale()`](https://ggplot2.tidyverse.org/reference/binned_scale.html)
  when `binned = TRUE`, else
  [`scico::scale_fill_scico()`](https://rdrr.io/pkg/scico/man/ggplot2-scales.html)
  /
  [`scico::scale_colour_scico()`](https://rdrr.io/pkg/scico/man/ggplot2-scales.html)) -
  e.g. `limits`, `breaks`, `labels`.

- name:

  Legend title. A string, `NULL` to drop it, or a function of the
  default (auto-derived) title. Defaults to
  [`lap_prettify_label()`](https://mxnl.github.io/lapidary/reference/lap_prettify_label.md).

- na.value:

  Colour for `NA`. Defaults to the token `missing` colour.

- binned:

  If `TRUE` (default, `_c` only) cut the scale at pretty breaks and use
  a colour-steps guide; `FALSE` gives a smooth gradient.

- bins:

  Target number of bins (passed to
  [`binned_scale()`](https://ggplot2.tidyverse.org/reference/binned_scale.html)
  as `n.breaks`). Default 8; `NULL` lets ggplot2 choose.

- begin, end, direction:

  Passed to [`scico::scico()`](https://rdrr.io/pkg/scico/man/scico.html)
  to trim / flip the palette.

- midpoint:

  For a divergent `role` (`"anomaly"`), the data value placed at the
  palette centre.

- guide:

  Legend guide. Defaults to a long, thin
  [`ggplot2::guide_coloursteps()`](https://ggplot2.tidyverse.org/reference/guide_coloursteps.html)
  (binned) or the scale default.

## Value

A ggplot2 scale.

## Details

The continuous (`_c`) scales are **binned** by default: the data is cut
at pretty round breaks and shown as a long, thin colour-steps bar. The
legend title is derived from the mapped variable with
[`lap_prettify_label()`](https://mxnl.github.io/lapidary/reference/lap_prettify_label.md)
(`ind_trend_slope` becomes `"Trend slope"`) unless you pass `name`. Pair
with
[`lap_na_guide()`](https://mxnl.github.io/lapidary/reference/lap_na_guide.md)
to add a "no data" key for `NA` regions (e.g. empty hexes).

## See also

[`lap_na_guide()`](https://mxnl.github.io/lapidary/reference/lap_na_guide.md),
[`lap_prettify_label()`](https://mxnl.github.io/lapidary/reference/lap_prettify_label.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
data(germany_hex_sample, package = "lapidary")
ggplot(germany_hex_sample) +
  geom_sf(aes(fill = mean_gwl)) +
  scale_fill_lapidary_c("magnitude") +
  lap_na_guide() +
  theme_lapidary()
} # }
```
