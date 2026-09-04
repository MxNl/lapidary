# A "how to read this chart" explainer string

Looks up `howto_<builder>` in the string registry (see
[`lap_tr()`](https://mxnl.github.io/lapidary/reference/lap_tr.md)) and
fills the `{recharge}` / `{discharge}` / `{below}` / `{above}` colour
placeholders from the design tokens of `variant`, so the prose
colour-matches the plot. The plot builders call this for their default
`plot.caption`; call it directly to place the explainer elsewhere.

## Usage

``` r
lap_howto(builder, lang = NULL, variant = NULL, ...)
```

## Arguments

- builder:

  Builder name without the `lap_plot_` prefix, e.g. `"hex_map"`.

- lang:

  Language code; defaults to
  [`lap_lang()`](https://mxnl.github.io/lapidary/reference/lap_lang.md).

- variant:

  `"light"` / `"dark"`; defaults to
  [`lap_variant()`](https://mxnl.github.io/lapidary/reference/lap_variant.md).

- ...:

  Further named `{placeholder}` values passed to
  [`lap_tr()`](https://mxnl.github.io/lapidary/reference/lap_tr.md).

## Value

A single string (may contain `<span>` markup for ggtext).

## Examples

``` r
lap_howto("hex_map")
#> [1] "Each hexagon is the average of the monitoring wells that fall inside it; darker cells hold more wells. Empty cells (no wells) are shown in grey."
lap_howto("hex_map", lang = "de")
#> [1] "Jede Wabe ist der Mittelwert der enthaltenen Messstellen; dunklere Zellen enthalten mehr Messstellen. Leere Zellen (keine Messstellen) sind grau dargestellt."
```
