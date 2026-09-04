# Map the change in an indicator between two periods

Visualises the output of
[`lap_indicator_delta()`](https://mxnl.github.io/lapidary/reference/lap_indicator_delta.md)
aggregated onto a hex grid: the per-hexagon change in one indicator
between a `from` and a `to` period.

## Usage

``` r
lap_plot_delta_map(
  data,
  value,
  ...,
  display = c("change", "paired", "arrow"),
  direction = 1,
  binned = TRUE,
  bins = 8,
  robust = getOption("lapidary.scale_robust", FALSE),
  range = getOption("lapidary.scale_range", FALSE),
  hull = TRUE,
  hull_shadow = TRUE,
  na_guide = TRUE,
  border_colour = NULL,
  margin = c("none", "histogram", "density", "raincloud"),
  margin_side = c("bottom", "right"),
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

  An `sf` polygon layer (a hex grid) with the delta columns.

- value:

  The base indicator column, as a bare name or string (e.g.
  `ind_amplitude`); the `_<from>` / `_<to>` / `_change` columns are
  resolved from it.

- ...:

  Passed to the underlying
  [`scale_fill_lapidary_c()`](https://mxnl.github.io/lapidary/reference/scale_lapidary.md).

- display:

  `"change"` (default) a divergent choropleth of `_change` about zero;
  `"paired"` two shared-scale period maps (returns a
  [patchwork::patchwork](https://patchwork.data-imaginist.com/reference/patchwork-package.html));
  `"arrow"` a per-hexagon glyph whose length and direction encode the
  change.

- direction, binned, bins, robust, range:

  Passed to the fill scale.

- hull, hull_shadow, na_guide, border_colour:

  As in
  [`lap_plot_hex_map()`](https://mxnl.github.io/lapidary/reference/lap_plot_map.md).

- margin, margin_side:

  Attach a marginal distribution of the mapped `_change` values (only
  for `display = "change"`); see
  [`lap_attach_margin()`](https://mxnl.github.io/lapidary/reference/lap_attach_margin.md).

- variant, lang, annotate, base_size, preset, title, subtitle, caption:

  See
  [lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md).

## Value

A
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html),
or a
[patchwork::patchwork](https://patchwork.data-imaginist.com/reference/patchwork-package.html)
for `display = "paired"` or when `margin` is set.

## Details

`data` is an `sf` hex layer carrying the wide `<value>_<from>`,
`<value>_<to>` and `<value>_change` columns - build it by joining
[`lap_indicator_delta()`](https://mxnl.github.io/lapidary/reference/lap_indicator_delta.md)
to the wells and passing it through
[`lap_aggregate_to_hex()`](https://mxnl.github.io/lapidary/reference/lap_aggregate_to_hex.md).
`value` is the **base** indicator column name (without the period /
`_change` suffix), e.g. `ind_amplitude`.

## See also

[`lap_indicator_delta()`](https://mxnl.github.io/lapidary/reference/lap_indicator_delta.md),
[`lap_plot_change_scatter()`](https://mxnl.github.io/lapidary/reference/lap_plot_change_scatter.md),
[`lap_plot_period_ridges()`](https://mxnl.github.io/lapidary/reference/lap_plot_period_ridges.md)

## Examples

``` r
if (FALSE) { # \dontrun{
chg <- lap_indicator_change(
  gems_ger_sample, "amplitude",
  periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
)
dl <- lap_indicator_delta(chg, "reference", "recent")
hex <- lap_aggregate_to_hex(gems_ger_wells_sample, dl)
lap_plot_delta_map(hex, ind_amplitude)
lap_plot_delta_map(hex, ind_amplitude, display = "paired")
} # }
```
