# A long, thin colour-steps legend guide

The default guide for the binned
[scale_lapidary](https://mxnl.github.io/lapidary/reference/scale_lapidary.md)
scales: a tall, narrow
[`ggplot2::guide_coloursteps()`](https://ggplot2.tidyverse.org/reference/guide_coloursteps.html)
bar with a subtle frame and tick marks.

## Usage

``` r
lap_coloursteps_guide(
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
  [`ggplot2::guide_coloursteps()`](https://ggplot2.tidyverse.org/reference/guide_coloursteps.html).

## Value

A ggplot2 guide.
