# Aggregate per-well values onto a hexagonal grid

Spatially joins well points to a hex grid and summarises one or more
value columns per hexagon. Regular numeric columns are averaged (mean);
columns named in `circular` are averaged with
[`lap_circular_mean_month()`](https://mxnl.github.io/lapidary/reference/lap_circular_mean_month.md);
a well count `n_wells` is always added.

## Usage

``` r
lap_aggregate_to_hex(
  wells,
  values = NULL,
  cols = NULL,
  circular = NULL,
  grid = NULL,
  region = NULL,
  cellsize = 25000
)
```

## Arguments

- wells:

  A `gwl_wells` layer (or any `sf` POINT layer with `well_id`).

- values:

  A data frame keyed by `well_id` holding the columns to aggregate, or
  `NULL` to use numeric columns already on `wells`.

- cols:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  value columns to aggregate (bare names, strings, helpers). Default:
  all numeric columns of `values` (or `wells`).

- circular:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  subset of `cols` to average circularly (months). Default: none.

- grid:

  A hex grid from
  [`lap_make_hex_grid()`](https://mxnl.github.io/lapidary/reference/lap_make_hex_grid.md).
  If `NULL`, one is built from `region`.

- region:

  Passed to
  [`lap_make_hex_grid()`](https://mxnl.github.io/lapidary/reference/lap_make_hex_grid.md)
  when `grid` is `NULL`. Defaults to
  [`lap_germany_border()`](https://mxnl.github.io/lapidary/reference/lap_germany_border.md).

- cellsize:

  Passed to
  [`lap_make_hex_grid()`](https://mxnl.github.io/lapidary/reference/lap_make_hex_grid.md).

## Value

An `sf` polygon layer: the grid plus one column per aggregated value and
`n_wells`. Hexagons with no wells keep `NA` values.
