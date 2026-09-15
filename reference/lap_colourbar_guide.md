# A long, thin smooth colour-bar legend guide

The
[`lap_coloursteps_guide()`](https://mxnl.github.io/lapidary/reference/lap_coloursteps_guide.md)
styling (tall, narrow, framed, ticked) for a smooth (non-binned) scale -
[`ggplot2::guide_colourbar()`](https://ggplot2.tidyverse.org/reference/guide_colourbar.html)
instead of
[`ggplot2::guide_coloursteps()`](https://ggplot2.tidyverse.org/reference/guide_coloursteps.html).
Use it when a scale is built with `binned = FALSE`, or for a bespoke
continuous scale such as
[`lap_plot_calendar()`](https://mxnl.github.io/lapidary/reference/lap_plot_calendar.md)'s
divergent mode.

## Usage

``` r
lap_colourbar_guide(
  length = 18,
  thickness = 0.55,
  title_gap = 0.9,
  label_gap = 1,
  tick_length = 0.2,
  order = 1,
  variant = NULL,
  ...
)
```

## Arguments

- length, thickness:

  Bar length and thickness, in text `"lines"` (so they scale with the
  legend text size). Defaults 18 and 0.55.

- title_gap, label_gap, tick_length:

  Space (in `"lines"`) below the legend title, to the left of the break
  labels, and the tick-mark length. Defaults 0.9, 1.0 and 0.2.

- order:

  Guide order (default 1), so it sits above a
  [`lap_na_guide()`](https://mxnl.github.io/lapidary/reference/lap_na_guide.md)
  key.

- variant:

  `"light"` / `"dark"` for the frame / tick colour. Defaults to
  [`lap_variant()`](https://mxnl.github.io/lapidary/reference/lap_variant.md).

- ...:

  Passed to
  [`ggplot2::guide_colourbar()`](https://ggplot2.tidyverse.org/reference/guide_colourbar.html).

## Value

A ggplot2 guide.
