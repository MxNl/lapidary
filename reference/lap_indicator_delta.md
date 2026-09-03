# Difference indicators between two periods

Takes the long output of
[`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md)
and returns one row per well with, for each indicator column, its value
in `from`, its value in `to`, and the change - differenced according to
the indicator's kind (a plain difference; a signed month difference in
`(-6, 6]` for the circular month columns; nothing for p-values and
`ind_step_year`).

## Usage

``` r
lap_indicator_delta(change, from, to, by = well_id)
```

## Arguments

- change:

  The long tibble from
  [`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md).

- from, to:

  Period labels present in `change$period`.

- by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the well-identifying column(s). Default `well_id`.

## Value

A tibble, one row per `by`, with `<col>_<from>`, `<col>_<to>` and (where
meaningful) `<col>_change` for each `ind_*` column.

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
chg <- lap_indicator_change(
  gems_ger_sample, c("amplitude", "extreme_months"),
  periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
)
lap_indicator_delta(chg, "reference", "recent")
#> # A tibble: 40 × 10
#>    well_id ind_amplitude_reference ind_amplitude_recent ind_amplitude_change
#>    <chr>                     <dbl>                <dbl>                <dbl>
#>  1 MW_1039                   2.03                 2.07                0.0400
#>  2 MW_1051                   1.69                 2.44                0.750 
#>  3 MW_1105                   0.830                0.910               0.0800
#>  4 MW_1230                   0.830                1.12                0.286 
#>  5 MW_1249                   1.49                 1.21               -0.283 
#>  6 MW_1268                   2.67                 2.99                0.314 
#>  7 MW_1325                   2.02                 1.96               -0.0600
#>  8 MW_1333                   2.24                 2.73                0.489 
#>  9 MW_1342                   2.34                 1.29               -1.05  
#> 10 MW_1419                  21.9                 20.0                -1.90  
#> # ℹ 30 more rows
#> # ℹ 6 more variables: ind_min_month_reference <dbl>,
#> #   ind_min_month_recent <dbl>, ind_min_month_change <dbl>,
#> #   ind_max_month_reference <dbl>, ind_max_month_recent <dbl>,
#> #   ind_max_month_change <dbl>
```
