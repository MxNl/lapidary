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
  by = NULL,
  complete = TRUE,
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
  all numeric columns of `values` (or `wells`), minus any `by` columns.

- circular:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  subset of `cols` to average circularly (months). Default: none.

- by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  grouping column(s) in `values` (or `wells`) - the aggregation runs per
  hexagon *and* group, and the output has one row per combination.
  Default: none. A grouping column's type (e.g. the ordered `period`
  factor) is preserved.

- complete:

  When `by` is set, keep every hexagon in *every* observed group (with
  `NA` values / `n_wells = 0` where that hexagon had no wells in that
  group), so a facetted map draws the full grid in each panel. `TRUE` by
  default; set `FALSE` to keep only the hexagon-group combinations that
  actually have wells. No effect without `by`.

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

An `sf` polygon layer: the grid plus one column per aggregated value,
any `by` column(s), and `n_wells`. Without `by`, hexagons with no wells
keep `NA` values. With `by` and the default `complete = TRUE`, every
hexagon appears once per observed group (`NA` values / `n_wells = 0`
where that hexagon-group combination has no wells) - ready to facet by
`by` with the full grid in every panel; with `complete = FALSE` a
hexagon with no wells in *any* group instead keeps a single row with
`NA` in the `by` column(s).

## Details

Pass `by` to aggregate *within groups* - e.g. feed the long output of
[`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md)
with `by = period` to get one row per hexagon and period (without `by`,
the repeated `well_id`s would collapse the periods).
