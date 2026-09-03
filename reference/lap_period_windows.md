# Derive comparison windows from a record's date range

Builds a named `periods` list (the shape
[`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md)
and
[`lap_add_reference_period()`](https://mxnl.github.io/lapidary/reference/lap_add_reference_period.md)
expect) from the span of a groundwater record, so you do not have to
write year pairs by hand. Unlike
[`lap_reference_periods()`](https://mxnl.github.io/lapidary/reference/lap_reference_periods.md)
(fixed WMO climate normals), these windows adapt to the data.

## Usage

``` r
lap_period_windows(
  x,
  scheme = c("first_vs_last_decade", "first_vs_last_half", "decade_per_decade"),
  date = "date",
  width = 10L
)
```

## Arguments

- x:

  A data frame with a date column, or a length-2 numeric vector
  `c(first_year, last_year)`.

- scheme:

  One of:

  - `"first_vs_last_decade"` - the first and last `width` years;

  - `"first_vs_last_half"` - the record split at its midpoint;

  - `"decade_per_decade"` - one window per 10-year block from the first
    year of the record, the last block clipped to the end. Names are the
    actual spans, e.g. `"1991-2000"`.

- date:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the date column used to derive the year range when `x` is a data
  frame. Default `date`.

- width:

  Window length in years for `"first_vs_last_decade"`. Default 10.

## Value

A named list of `c(start_year, end_year)` integer pairs in chronological
order (`first` before `last`), validated for
[`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md)
(overlaps allowed).

## Details

`"decade_per_decade"` can return more than two windows; pass any two of
its labels to
[`lap_indicator_delta()`](https://mxnl.github.io/lapidary/reference/lap_indicator_delta.md).
The non-overlapping schemes (`"first_vs_last_half"` and
`"decade_per_decade"`) also work as the `periods` argument of
[`lap_add_reference_period()`](https://mxnl.github.io/lapidary/reference/lap_add_reference_period.md).

## See also

[`lap_reference_periods()`](https://mxnl.github.io/lapidary/reference/lap_reference_periods.md),
[`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md),
[`lap_add_reference_period()`](https://mxnl.github.io/lapidary/reference/lap_add_reference_period.md)

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
lap_period_windows(gems_ger_sample, "first_vs_last_decade")
#> $first
#> [1] 1991 2000
#> 
#> $last
#> [1] 2013 2022
#> 
lap_period_windows(c(1991, 2022), "decade_per_decade")
#> $`1991-2000`
#> [1] 1991 2000
#> 
#> $`2001-2010`
#> [1] 2001 2010
#> 
#> $`2011-2020`
#> [1] 2011 2020
#> 
#> $`2021-2022`
#> [1] 2021 2022
#> 
lap_indicator_change(
  gems_ger_sample, c("amplitude", "trend"),
  periods = lap_period_windows(gems_ger_sample, "first_vs_last_half")
)
#> # A tibble: 80 × 6
#>    well_id period ind_amplitude ind_trend_slope ind_trend_p_value
#>    <chr>   <ord>          <dbl>           <dbl>             <dbl>
#>  1 MW_1039 first          2.03        -0.000657             0.893
#>  2 MW_1051 first          1.69        -0.00685              0.392
#>  3 MW_1105 first          0.830        0.00693              0.300
#>  4 MW_1230 first          0.830        0.00169              0.558
#>  5 MW_1249 first          1.49         0.0159               0.163
#>  6 MW_1268 first          2.67         0.0108               0.192
#>  7 MW_1325 first          2.02        -0.00413              0.344
#>  8 MW_1333 first          2.05        -0.000553             0.964
#>  9 MW_1342 first          2.34         0.0109               0.300
#> 10 MW_1419 first         21.9          0.146                0.822
#> # ℹ 70 more rows
#> # ℹ 1 more variable: ind_trend_significant <lgl>
```
