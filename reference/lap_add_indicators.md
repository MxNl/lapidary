# Append time-series indicators to a well-level table

For building an indicator set step by step: takes an existing well-level
table, computes the requested indicators from the time series, and
left-joins them on `by`.

## Usage

``` r
lap_add_indicators(
  data,
  x,
  .funs,
  by = well_id,
  value = gwl,
  date = "date",
  ...
)
```

## Arguments

- data:

  A well-level table (e.g. from
  [`lap_summarise_wells()`](https://mxnl.github.io/lapidary/reference/lap_summarise_wells.md)
  grouped by `well_id`, or a `gwl_wells` layer).

- x:

  The time series the indicators are computed from.

- .funs:

  Which indicators to compute; see
  [`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md).

- by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  join key(s), present in both `data` and `x`. Default `well_id`.

- value, date:

  Passed to
  [`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md).

- ...:

  Extra arguments forwarded to each `lap_ind_*()` (e.g. `threshold`,
  `driver`).

## Value

`data` with the indicator columns added.

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
lap_summarise_wells(gems_ger_sample, by = well_id) |>
  lap_add_indicators(gems_ger_sample, "all")
#> # A tibble: 40 × 32
#>    well_id min_gwl max_gwl mean_gwl median_gwl sd_gwl n_obs coverage
#>    <chr>     <dbl>   <dbl>    <dbl>      <dbl>  <dbl> <int>    <dbl>
#>  1 MW_1039    411.    414.     412.       412.  0.326  1669       NA
#>  2 MW_1051    511.    513.     511.       511.  0.341  1669       NA
#>  3 MW_1105    410.    412.     411.       411.  0.152  1669       NA
#>  4 MW_1230    164.    165.     165.       164.  0.126  1669       NA
#>  5 MW_1249    394.    395.     394.       394.  0.252  1669       NA
#>  6 MW_1268    401.    404.     402.       402.  0.319  1669       NA
#>  7 MW_1325    573.    575.     573.       573.  0.354  1669       NA
#>  8 MW_1333    428.    430.     429.       429.  0.460  1669       NA
#>  9 MW_1342    635.    637.     636.       636.  0.294  1669       NA
#> 10 MW_1419    225.    247.     236.       237.  6.39   1669       NA
#> # ℹ 30 more rows
#> # ℹ 24 more variables: ind_amplitude <dbl>, ind_seasonal_amplitude <dbl>,
#> #   ind_seasonality_strength <dbl>, ind_recharge_months <dbl>,
#> #   ind_discharge_months <dbl>, ind_min_month_sd <dbl>, ind_min_month <dbl>,
#> #   ind_max_month <dbl>, ind_flashiness <dbl>, ind_acf1 <dbl>,
#> #   ind_memory_weeks <dbl>, ind_rise_rate <dbl>, ind_fall_rate <dbl>,
#> #   ind_trend_slope <dbl>, ind_trend_p_value <dbl>, …
```
