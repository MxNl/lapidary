# Calendar heatmap

A year x month (or year x week) tile grid, coloured by `value` - e.g.
the output of
[`lap_summarise_calendar()`](https://mxnl.github.io/lapidary/reference/lap_summarise_calendar.md)
(how many wells set a new record that month), one tile per bucket.
`facet` draws several such grids stacked on one shared scale instead,
e.g. new-low counts above new-high counts.

## Usage

``` r
lap_plot_calendar(
  data,
  value,
  year = year,
  unit = unit,
  facet = NULL,
  ...,
  unit_labels = NULL,
  border_colour = NULL,
  role = "magnitude",
  direction = 1,
  midpoint = NULL,
  robust = getOption("lapidary.scale_robust", FALSE),
  low_label = NULL,
  high_label = NULL,
  variant = lap_variant(),
  lang = NULL,
  annotate = getOption("lapidary.annotate", NA),
  base_size = NULL,
  preset = NULL,
  title = NULL,
  subtitle = NULL,
  caption = NULL
)
```

## Arguments

- data:

  The tibble from
  [`lap_summarise_calendar()`](https://mxnl.github.io/lapidary/reference/lap_summarise_calendar.md)
  (`year`, `unit`, `value`, optionally `facet`).

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the column to colour tiles by.

- year, unit:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the calendar columns. Defaults `year` / `unit` (what
  [`lap_summarise_calendar()`](https://mxnl.github.io/lapidary/reference/lap_summarise_calendar.md)
  produces, whether `unit` holds months or ISO weeks).

- facet:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  optional column to stack separate calendars by (one grid per level,
  `ncol = 1`), sharing one fill scale.

- ...:

  Passed to the underlying fill scale -
  [`scale_fill_lapidary_c()`](https://mxnl.github.io/lapidary/reference/scale_lapidary.md)
  when `midpoint` is `NULL`, or a bespoke
  [`ggplot2::continuous_scale()`](https://ggplot2.tidyverse.org/reference/continuous_scale.html)
  built from the full `role` palette when a `midpoint` is given.

- unit_labels:

  Labels for the `unit` axis. `NULL` (default) uses localised month
  abbreviations when `unit`'s values are all `<= 12` (assumed to be
  calendar months), otherwise plain numbers (e.g. ISO weeks).

- border_colour:

  Outline colour between tiles. Defaults to the variant's background
  colour (a visible gap, unlike
  [`lap_plot_stream()`](https://mxnl.github.io/lapidary/reference/lap_plot_stream.md)'s
  seamless default) - pass `NA` for none.

- role, direction, robust:

  Passed to the fill scale. Default `role = "magnitude"` (sequential,
  for a count). `robust` squishes values beyond a data-aware quantile
  threshold onto the same end colour, so a few extreme buckets don't
  wash out the variation in the rest of the grid.

- midpoint:

  `NULL` (default) draws a sequential `role = "magnitude"` scale for a
  count. Set it (e.g. `0`) for a **divergent** scale instead - a smooth
  gradient built from the full `role` palette (not just its two end
  colours), with only the exact centre colour swapped for the variant's
  own background colour - genuinely neutral, and blends into the page in
  light mode / the panel in dark mode. Built as a bespoke smooth scale
  rather than the package's usual binned steps, because binning has no
  notion of `midpoint`: a value of exactly `midpoint` could land on a
  bin edge and inherit that bin's colour instead of the true neutral
  one. `direction = -1` puts the low end of the palette on the high
  value (see examples) - the hydrological low/dry-high/wet convention
  used elsewhere in the package.

- low_label, high_label:

  Words for what a low / a high value means (e.g. `"more new lows"` /
  `"more new highs"`). With `midpoint` set, these are woven into a
  sentence naming the actual rendered colours (assumes the
  `"anomaly"`/vik convention of low = red, high = blue - the package's
  only divergent role today; revisit this wording if a second divergent
  role is ever added), with a generic "a low/high value" fallback when
  they're not supplied. Without `midpoint`, a plain arrow sentence is
  appended only when both are given.

- variant, lang, annotate, base_size, preset, title, subtitle, caption:

  See
  [lap_plot_map](https://mxnl.github.io/lapidary/reference/lap_plot_map.md).

## Value

A
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html).

## Details

Unlike most `lap_plot_*()` builders, the default how-to explanation is
placed in the plot **subtitle**, not the caption - it reads better
directly above the panel it describes, especially with the month/week
labels also at the top of the panel. `annotate = "callout"` still places
it in an on-panel box instead; the user's own `caption` argument is
unaffected either way.

## See also

[`lap_add_record_flags()`](https://mxnl.github.io/lapidary/reference/lap_add_record_flags.md),
[`lap_summarise_calendar()`](https://mxnl.github.io/lapidary/reference/lap_summarise_calendar.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# one divergent panel: the balance of new-high vs new-low record years
cal <- gems_ger_sample |>
  lap_add_record_flags() |>
  lap_summarise_calendar(record_balance)
lap_plot_calendar(
  cal, n,
  role = "anomaly", direction = -1, midpoint = 0, robust = TRUE,
  low_label = "more new lows", high_label = "more new highs"
)

# or two sequential panels, one per series' own magnitude
cal2 <- gems_ger_sample |>
  lap_add_record_flags() |>
  lap_summarise_calendar(is_new_min, is_new_max)
lap_plot_calendar(cal2, n, facet = name)
} # }
```
