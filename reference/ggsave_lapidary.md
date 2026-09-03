# Save a lapidary plot at a named size preset

Wraps
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
with the poster/web size + dpi presets and, crucially, sets `showtext`'s
DPI to match so text metrics are correct in print output (the recurring
gotcha in the prototype). Uses the ragg PNG device when available for
crisper text.

## Usage

``` r
ggsave_lapidary(plot, filename, preset = "web", ...)
```

## Arguments

- plot:

  A ggplot (or patchwork) object.

- filename:

  Output path. The device is inferred from the extension (`.png`,
  `.pdf`, ...).

- preset:

  A name from
  [`lap_preset_names()`](https://mxnl.github.io/lapidary/reference/lap_preset_names.md).

- ...:

  Overrides passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  (`width`, `height`, `dpi`, ...).

## Value

`filename`, invisibly.

## Details

This does **not** re-theme the plot; build the plot with
`theme_lapidary(base_size = lap_preset(preset)$base_size)` (the
milestone-2 builders take a `preset`/`base_size` argument that does
this).
