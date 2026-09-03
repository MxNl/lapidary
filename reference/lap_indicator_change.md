# Compute indicators over several time windows

Runs
[`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md)
once per named period and stacks the results, so the change in a well's
behaviour between (say) a reference decade and a recent one is visible.
Unlike
[`lap_add_reference_period()`](https://mxnl.github.io/lapidary/reference/lap_add_reference_period.md),
the periods **may overlap** (e.g. a full-record window alongside a
recent one).

## Usage

``` r
lap_indicator_change(
  x,
  .funs,
  periods,
  by = well_id,
  value = gwl,
  date = "date",
  ...
)
```

## Arguments

- x:

  A `gwl_ts` / data frame of time series (one row per well x date).

- .funs:

  Which indicators to compute. Required. One of:

  - `"all"` - every indicator in
    [`lap_indicator_registry()`](https://mxnl.github.io/lapidary/reference/lap_indicator_registry.md);

  - a character vector of registry keys, e.g. `c("amplitude", "trend")`;

  - one or more `lap_ind_*` functions, e.g.
    `c(lap_ind_amplitude, lap_ind_trend)`;

  - a mix of keys and functions.

- periods:

  A **named** list of `c(start_year, end_year)` pairs, e.g.
  `list(reference = c(1991, 2010), recent = c(2011, 2022))`.

- by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the series-identifying column(s). Default `well_id`.

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the level column. Default `gwl`.

- date:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the date column, or `NULL` for a series with no dates. Default `date`.

- ...:

  Extra arguments forwarded to each `lap_ind_*()` (e.g. `threshold`,
  `driver`). For `climate_signal` the driver column must already be in
  `x` (join it with
  [`lap_join_meteo()`](https://mxnl.github.io/lapidary/reference/lap_join_meteo.md)
  before slicing into periods).

## Value

A long tibble: the `by` column(s), a `period` **ordered factor** (levels
in the order of `periods`), and the `ind_*` columns.

## See also

[`lap_indicator_delta()`](https://mxnl.github.io/lapidary/reference/lap_indicator_delta.md)
to turn this into one row per well with change columns.

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
lap_indicator_change(
  gems_ger_sample, c("amplitude", "trend"),
  periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
)
#> # A tibble: 80 × 6
#>    well_id period    ind_amplitude ind_trend_slope ind_trend_p_value
#>    <chr>   <ord>             <dbl>           <dbl>             <dbl>
#>  1 MW_1039 reference         2.03        -0.00400             0.284 
#>  2 MW_1051 reference         1.69        -0.00668             0.256 
#>  3 MW_1105 reference         0.830        0.00451             0.230 
#>  4 MW_1230 reference         0.830        0.00407             0.0297
#>  5 MW_1249 reference         1.49         0.0131              0.0744
#>  6 MW_1268 reference         2.67         0.00235             0.721 
#>  7 MW_1325 reference         2.02        -0.00738             0.0350
#>  8 MW_1333 reference         2.24        -0.00781             0.206 
#>  9 MW_1342 reference         2.34         0.000186            0.974 
#> 10 MW_1419 reference        21.9          0.248               0.315 
#> # ℹ 70 more rows
#> # ℹ 1 more variable: ind_trend_significant <lgl>
```
