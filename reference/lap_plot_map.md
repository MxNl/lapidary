# lapidary map builders

Two "status quo" builders that show one value per well over the whole
record on a map of Germany:

## Usage

``` r
lap_plot_hex_map(
  data,
  value,
  ...,
  role = NULL,
  direction = 1,
  midpoint = NULL,
  binned = TRUE,
  bins = 8,
  robust = getOption("lapidary.scale_robust", FALSE),
  range = getOption("lapidary.scale_range", FALSE),
  hull = TRUE,
  hull_shadow = TRUE,
  na_guide = TRUE,
  border_colour = NULL,
  variant = lap_variant(),
  lang = NULL,
  annotate = getOption("lapidary.annotate", "caption"),
  base_size = NULL,
  preset = NULL,
  title = NULL,
  subtitle = NULL,
  caption = NULL
)

lap_plot_point_map(
  data,
  value,
  ...,
  role = "magnitude",
  direction = 1,
  size = 1.6,
  robust = getOption("lapidary.scale_robust", FALSE),
  range = getOption("lapidary.scale_range", FALSE),
  basemap = TRUE,
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

  For `lap_plot_hex_map()` an `sf` polygon layer (a hex grid); for
  `lap_plot_point_map()` an `sf` POINT layer with the value column.

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the column to colour by.

- ...:

  Passed to the underlying `scale_*_lapidary_c()` (e.g. `limits`,
  `breaks`).

- role:

  Palette role (see
  [`lap_pal_roles()`](https://mxnl.github.io/lapidary/reference/lap_pal_roles.md)).
  Default: `"months"` for a circular-month column, `"anomaly"` when
  `midpoint` is set, else `"magnitude"`.

- direction, midpoint, binned, bins, robust, range:

  Passed to the scale.

- hull, hull_shadow:

  (`hex_map`) Draw the dissolved grid outline behind the hexes, with a
  drop shadow (needs ggfx; degrades to no shadow).

- na_guide:

  (`hex_map`) Add a
  [`lap_na_guide()`](https://mxnl.github.io/lapidary/reference/lap_na_guide.md)
  "no data" key when the value column has `NA`s.

- border_colour:

  (`hex_map`) Hex border colour; default the background.

- variant:

  `"light"` / `"dark"`; defaults to
  [`lap_variant()`](https://mxnl.github.io/lapidary/reference/lap_variant.md).

- lang:

  Language code; defaults to
  [`lap_lang()`](https://mxnl.github.io/lapidary/reference/lap_lang.md).

- annotate:

  How-to-read explainer: `"caption"` (default), `"callout"`, `NA` to
  suppress, or a literal string. Default
  `getOption("lapidary.annotate", "caption")`.

- base_size, preset:

  Base font size, or a
  [`lap_preset_names()`](https://mxnl.github.io/lapidary/reference/lap_preset_names.md)
  value that supplies it (e.g. `preset = "a1"` for poster-size text).

- title, subtitle, caption:

  Plot labels; `NULL` leaves them unset.

- size:

  (`point_map`) Point size.

- basemap:

  (`point_map`) Draw
  [`lap_germany_border()`](https://mxnl.github.io/lapidary/reference/lap_germany_border.md)
  behind the points (needs rnaturalearth).

## Value

A
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html).

## Details

- `lap_plot_hex_map()` - a choropleth of a hex grid from
  [`lap_aggregate_to_hex()`](https://mxnl.github.io/lapidary/reference/lap_aggregate_to_hex.md)
  (or `germany_hex_sample`). If a POINT layer is passed it dispatches to
  `lap_plot_point_map()`.

- `lap_plot_point_map()` - one coloured mark per monitoring well.

Both return a bare
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html);
both end with
[`theme_lapidary()`](https://mxnl.github.io/lapidary/reference/theme_lapidary.md),
a single `scale_*_lapidary_c()` and a how-to-read `plot.caption` (see
`annotate`).

## See also

[`lap_aggregate_to_hex()`](https://mxnl.github.io/lapidary/reference/lap_aggregate_to_hex.md),
[`lap_annotate_howto()`](https://mxnl.github.io/lapidary/reference/lap_annotate_howto.md)

## Examples

``` r
if (FALSE) { # \dontrun{
data(germany_hex_sample, package = "lapidary")
lap_plot_hex_map(germany_hex_sample, mean_gwl)
lap_plot_hex_map(germany_hex_sample, n_wells, role = "density")
} # }
```
