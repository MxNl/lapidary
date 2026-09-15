# Sum event columns into a year x month/week calendar grid

Turns one or more row-level numeric or logical columns (e.g.
[`lap_add_record_flags()`](https://mxnl.github.io/lapidary/reference/lap_add_record_flags.md)'s
`is_new_min` / `is_new_max`) into a long `year | unit | name | n`
table - the sum of each column, across *every* row of `x` (not per
well), in every calendar bucket. Feed the result to
[`lap_plot_calendar()`](https://mxnl.github.io/lapidary/reference/lap_plot_calendar.md).

## Usage

``` r
lap_summarise_calendar(x, ..., date = "date", period = c("month", "week"))
```

## Arguments

- x:

  A data frame with a `date` column and the columns to sum.

- ...:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  one or more numeric or logical columns to sum, e.g.
  `is_new_min, is_new_max`.

- date:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the date column. Default `date`.

- period:

  `"month"` (default, `unit` is 1-12) or `"week"` (`unit` is the ISO
  week number, paired with its ISO week-year so the Dec/Jan week-53 edge
  case lands in the right year).

## Value

A tibble: `year`, `unit`, `name` (the summed column, with a leading
`is_` stripped for a cleaner label) and `n` (its sum in that bucket). A
`(year, unit, name)` row only appears when at least one row contributed
a non-`NA` value for that column in that bucket; a bucket with rows but
no flagged event still gets a real `n = 0`, distinct from a bucket where
every contributing row was `NA` (e.g. every well's first year, see
[`lap_add_record_flags()`](https://mxnl.github.io/lapidary/reference/lap_add_record_flags.md)),
which produces no row at all. Columns from the same call can drop
independently - if one column is all-`NA` in a bucket but another isn't,
only the all-`NA` column's row is omitted.

## See also

[`lap_add_record_flags()`](https://mxnl.github.io/lapidary/reference/lap_add_record_flags.md),
[`lap_plot_calendar()`](https://mxnl.github.io/lapidary/reference/lap_plot_calendar.md)

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
flagged <- lap_add_record_flags(gems_ger_sample)
# one column: the net balance of new-high vs new-low record years
lap_summarise_calendar(flagged, record_balance)
#> # A tibble: 372 × 4
#>     year  unit name               n
#>    <dbl> <dbl> <chr>          <int>
#>  1  1992     1 record_balance    -3
#>  2  1992     2 record_balance     1
#>  3  1992     3 record_balance     4
#>  4  1992     4 record_balance     5
#>  5  1992     5 record_balance     3
#>  6  1992     6 record_balance     0
#>  7  1992     7 record_balance    -1
#>  8  1992     8 record_balance    -3
#>  9  1992     9 record_balance    -3
#> 10  1992    10 record_balance    -6
#> # ℹ 362 more rows
# or several at once: each series' own magnitude, kept separate
lap_summarise_calendar(flagged, is_new_min, is_new_max)
#> # A tibble: 744 × 4
#>     year  unit name        n
#>    <dbl> <dbl> <chr>   <int>
#>  1  1992     1 new_max     0
#>  2  1992     1 new_min     3
#>  3  1992     2 new_max     1
#>  4  1992     2 new_min     0
#>  5  1992     3 new_max     4
#>  6  1992     3 new_min     0
#>  7  1992     4 new_max     5
#>  8  1992     4 new_min     0
#>  9  1992     5 new_max     3
#> 10  1992     5 new_min     0
#> # ℹ 734 more rows
```
