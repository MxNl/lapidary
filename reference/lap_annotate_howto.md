# Add a "how to read this chart" explainer to a plot

Places a short explainer either in `plot.caption` (default) or as an
on-panel corner box. The
[lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md)
builders call this for their default `annotate = "caption"`; call it
directly to override placement or add an explainer to a plot the
builders did not make.

## Usage

``` r
lap_annotate_howto(
  plot,
  key = NULL,
  text = NULL,
  placement = c("caption", "callout"),
  corner = c("bottom-right", "bottom-left", "top-right", "top-left"),
  lang = NULL,
  variant = NULL,
  tokens = NULL
)
```

## Arguments

- plot:

  A ggplot object.

- key:

  Builder name without the `lap_plot_` prefix (e.g. `"hex_map"`), used
  to look up the registry string. Ignored if `text` is given.

- text:

  Explainer text (may contain `<span>` markup for ggtext). `NULL`
  (default) uses `lap_howto(key)`.

- placement:

  `"caption"` (append to `plot.caption`) or `"callout"` (an on-panel
  box).

- corner:

  For `"callout"`: which corner. One of `"bottom-right"` (default),
  `"bottom-left"`, `"top-right"`, `"top-left"`.

- lang, variant:

  Passed to
  [`lap_howto()`](https://mxnl.github.io/lapidary/reference/lap_howto.md)
  when `text` is `NULL`.

- tokens:

  A
  [`lap_tokens()`](https://mxnl.github.io/lapidary/reference/lap_tokens.md)
  list; computed from `variant` if `NULL`.

## Value

`plot` with the annotation added.

## See also

[`lap_howto()`](https://mxnl.github.io/lapidary/reference/lap_howto.md),
[lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
data(germany_hex_sample, package = "lapidary")
lap_plot_hex_map(germany_hex_sample, mean_gwl, annotate = NA) |>
  lap_annotate_howto("hex_map", placement = "callout")
} # }
```
