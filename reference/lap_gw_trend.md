# Non-parametric trend of groundwater time series

Computes the Theil-Sen slope estimator together with the Mann-Kendall
trend test (with tie correction) for each series. This non-parametric
pairing is a standard choice for hydrological trend analysis: robust to
outliers and making no assumption of normal residuals.

## Usage

``` r
lap_gw_trend(
  x,
  value = mean_gwl,
  time = year,
  by = well_id,
  min_n = 10L,
  conf_level = 0.95,
  warn_n = 1000L
)
```

## Arguments

- x:

  A data frame with a time column, a value column and grouping
  column(s).

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the single value column. Default `mean_gwl`.

- time:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the single time column (numeric years, or Date). Default `year`.

- by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  grouping column(s). Default `well_id`.

- min_n:

  Minimum number of finite observations required per group.

- conf_level:

  Confidence level for the slope confidence interval.

- warn_n:

  Warn when any group has more than this many rows: the pairwise
  Theil-Sen estimator is O(n^2), so this function expects an *annual*
  series (summarise first, or use
  [`lap_ind_trend()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend.md)).

## Value

A tibble with one row per group: `n`, `slope` (value units per year),
`slope_lower`, `slope_upper`, `intercept`, `tau`, `p_value`,
`significant` (logical at `1 - conf_level`), `direction`.

## Details

Input is typically an annual series - e.g. the `mean_gwl` column of
[`lap_summarise_wells()`](https://mxnl.github.io/lapidary/reference/lap_summarise_wells.md)
grouped by `c(well_id, year)` - but any regular-ish series works.

## Examples

``` r
set.seed(1)
df <- data.frame(
  well_id = rep(c("a", "b"), each = 30),
  year = rep(1991:2020, 2),
  mean_gwl = c(
    50 - 0.1 * (0:29) + rnorm(30, 0, 0.2),
    20 + rnorm(30, 0, 0.2)
  )
)
lap_gw_trend(df)
#> # A tibble: 2 × 10
#>   well_id     n     slope slope_lower slope_upper intercept      tau  p_value
#>   <chr>   <int>     <dbl>       <dbl>       <dbl>     <dbl>    <dbl>    <dbl>
#> 1 a          30 -0.102       -0.110      -0.0937      253.  -0.903   2.68e-12
#> 2 b          30 -0.000230    -0.00737     0.00843      20.4 -0.00690 9.72e- 1
#> # ℹ 2 more variables: significant <lgl>, direction <chr>
```
