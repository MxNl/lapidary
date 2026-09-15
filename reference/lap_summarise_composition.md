# Share of wells in each category, per time bucket

Turns a row-level categorical column (e.g.
[`lap_add_quantile_class()`](https://mxnl.github.io/lapidary/reference/lap_add_quantile_class.md)'s
`gwl_class`, or any other per-well state - drought / rising / falling,
...) into a composition-over-time table: for each `period` bucket, how
many wells sat in each `category`, and what share of that bucket they
were. Feed the result to
[`lap_plot_stream()`](https://mxnl.github.io/lapidary/reference/lap_plot_stream.md).

## Usage

``` r
lap_summarise_composition(
  x,
  category,
  date = "date",
  period = c("week", "month", "year"),
  by = well_id
)
```

## Arguments

- x:

  A data frame with `by`, `date` and `category` columns (e.g. the output
  of
  [`lap_add_quantile_class()`](https://mxnl.github.io/lapidary/reference/lap_add_quantile_class.md)).

- category:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the categorical column to tally (ideally a factor, so empty categories
  still get a `0` row rather than being silently dropped from a bucket).

- date:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the date column. Default `date`.

- period:

  Bucket width: `"week"` (default, ISO weeks, Monday start), `"month"`
  or `"year"`.

- by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the well-identifying column(s). Default `well_id`.

## Value

A tibble: `date` (the bucket start), `category`, `n` (well count) and
`share` (`n` divided by the bucket total).

## Details

If `x` has more than one row per well within a bucket (raw daily data,
or a `period` coarser than `x`'s own resolution), only the most recent
row per well per bucket counts - so a well contributes exactly once to
each bucket regardless of how finely `x` is sampled.

## See also

[`lap_add_quantile_class()`](https://mxnl.github.io/lapidary/reference/lap_add_quantile_class.md),
[`lap_plot_stream()`](https://mxnl.github.io/lapidary/reference/lap_plot_stream.md)

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
gems_ger_sample |>
  lap_add_quantile_class() |>
  lap_summarise_composition(gwl_class)
#> # A tibble: 11,683 × 4
#>    date       gwl_class        n share
#>    <date>     <ord>        <int> <dbl>
#>  1 1991-01-07 Very low         1 0.025
#>  2 1991-01-07 Low              1 0.025
#>  3 1991-01-07 Below normal     4 0.1  
#>  4 1991-01-07 Normal          17 0.425
#>  5 1991-01-07 Above normal     4 0.1  
#>  6 1991-01-07 High             6 0.15 
#>  7 1991-01-07 Very high        7 0.175
#>  8 1991-01-14 Very low         2 0.05 
#>  9 1991-01-14 Low              0 0    
#> 10 1991-01-14 Below normal     4 0.1  
#> # ℹ 11,673 more rows
```
