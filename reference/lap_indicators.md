# Compute time-series indicators per well

Applies a selection of `lap_ind_*()` indicator functions to each series
in `x` and column-binds the results into a well-level table.

## Usage

``` r
lap_indicators(x, .funs, by = well_id, value = gwl, date = "date", ...)
```

## Arguments

- x:

  A `gwl_ts` / data frame of time series (one row per well x date).

- .funs:

  Which indicators to compute. Required. One of:

  - `"all"` - every indicator in
    [`lap_indicator_registry()`](https://mxnl.github.io/lapidary/reference/lap_indicator_registry.md)
    whose inputs are present in `x` (see the section below);

  - a character vector of registry keys, e.g. `c("amplitude", "trend")`;

  - one or more `lap_ind_*` functions, e.g.
    `c(lap_ind_amplitude, lap_ind_trend)`;

  - a mix of keys and functions.

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

  Extra arguments forwarded to every `lap_ind_*()` (e.g. `threshold`,
  `min_len`, `driver`). Indicators ignore what they do not use.

## Value

A tibble: the `by` column(s) plus one column per indicator output (all
`ind_`-prefixed).

## Which indicators "all" runs

Most indicators run off `value` and are always included (`in_all` in the
registry). Three need more than a level column and are therefore added
only when `x` actually carries what they need:

- `drought` and `drought_recovery` need a standardised index - add one
  with
  [`lap_normalise_gwl()`](https://mxnl.github.io/lapidary/reference/lap_normalise_gwl.md)
  `method = "sgi"`;

- `climate_signal` needs that **and** a climate driver - join one with
  [`lap_join_meteo()`](https://mxnl.github.io/lapidary/reference/lap_join_meteo.md).

`"all"` finds those columns itself (`<value>_norm`, `precip`) and passes
them to those indicators instead of `value`, reporting what it added
and - when a prerequisite is missing - what it had to skip and why. A
single series whose index is unusable over the window at hand yields
`NA` for that indicator, with a warning, rather than failing the whole
table. Requesting one of the three by key is stricter: pass
`value = gwl_norm` (and `driver =`) yourself, and an unusable series is
an error.

## See also

[`lap_indicator_registry()`](https://mxnl.github.io/lapidary/reference/lap_indicator_registry.md),
[`lap_add_indicators()`](https://mxnl.github.io/lapidary/reference/lap_add_indicators.md)

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
lap_indicators(gems_ger_sample, "all")
#> ℹ "all" skipped "drought", "drought_recovery", and "climate_signal": no
#>   standardised column - add `lap_normalise_gwl("sgi")`.
#> # A tibble: 40 × 25
#>    well_id ind_amplitude ind_seasonal_amplitude ind_seasonality_strength
#>    <chr>           <dbl>                  <dbl>                    <dbl>
#>  1 MW_1039          2.38                  1.21                    0.0601
#>  2 MW_1051          2.44                  1.15                    0.132 
#>  3 MW_1105          1.19                  0.449                   0.0840
#>  4 MW_1230          1.12                  0.469                   0.0602
#>  5 MW_1249          1.49                  0.755                   0.348 
#>  6 MW_1268          2.99                  1.12                    0.109 
#>  7 MW_1325          2.31                  1.18                    0.316 
#>  8 MW_1333          2.73                  1.47                    0.0650
#>  9 MW_1342          2.34                  1.07                    0.574 
#> 10 MW_1419         21.9                  10.2                     0.462 
#> # ℹ 30 more rows
#> # ℹ 21 more variables: ind_recharge_months <dbl>, ind_discharge_months <dbl>,
#> #   ind_min_month_sd <dbl>, ind_min_month <dbl>, ind_max_month <dbl>,
#> #   ind_flashiness <dbl>, ind_acf1 <dbl>, ind_memory_weeks <dbl>,
#> #   ind_rise_rate <dbl>, ind_fall_rate <dbl>, ind_trend_slope <dbl>,
#> #   ind_trend_p_value <dbl>, ind_trend_significant <lgl>,
#> #   ind_trend_min_slope <dbl>, ind_trend_max_slope <dbl>, …
lap_indicators(gems_ger_sample, c("amplitude", "extreme_months"))
#> # A tibble: 40 × 4
#>    well_id ind_amplitude ind_min_month ind_max_month
#>    <chr>           <dbl>         <dbl>         <dbl>
#>  1 MW_1039          2.38        10.7            3.33
#>  2 MW_1051          2.44        10.3            2.69
#>  3 MW_1105          1.19        10.1            2.65
#>  4 MW_1230          1.12         0.830          6.10
#>  5 MW_1249          1.49         9.92           2.79
#>  6 MW_1268          2.99        12.3            6.51
#>  7 MW_1325          2.31         1.17           7.16
#>  8 MW_1333          2.73        12.2            6.13
#>  9 MW_1342          2.34         1.20           6.63
#> 10 MW_1419         21.9         12.2            3.78
#> # ℹ 30 more rows
# with an SGI column, "all" also covers the drought indicators
lap_indicators(lap_normalise_gwl(gems_ger_sample, "sgi"), "all")
#> ℹ "all" also ran "drought" and "drought_recovery", using gwl_norm.
#> ℹ "all" skipped "climate_signal": no precip column - add it with
#>   `lap_join_meteo()`.
#> # A tibble: 40 × 35
#>    well_id ind_amplitude ind_seasonal_amplitude ind_seasonality_strength
#>    <chr>           <dbl>                  <dbl>                    <dbl>
#>  1 MW_1039          2.38                  1.21                    0.0601
#>  2 MW_1051          2.44                  1.15                    0.132 
#>  3 MW_1105          1.19                  0.449                   0.0840
#>  4 MW_1230          1.12                  0.469                   0.0602
#>  5 MW_1249          1.49                  0.755                   0.348 
#>  6 MW_1268          2.99                  1.12                    0.109 
#>  7 MW_1325          2.31                  1.18                    0.316 
#>  8 MW_1333          2.73                  1.47                    0.0650
#>  9 MW_1342          2.34                  1.07                    0.574 
#> 10 MW_1419         21.9                  10.2                     0.462 
#> # ℹ 30 more rows
#> # ℹ 31 more variables: ind_recharge_months <dbl>, ind_discharge_months <dbl>,
#> #   ind_min_month_sd <dbl>, ind_min_month <dbl>, ind_max_month <dbl>,
#> #   ind_flashiness <dbl>, ind_acf1 <dbl>, ind_memory_weeks <dbl>,
#> #   ind_rise_rate <dbl>, ind_fall_rate <dbl>, ind_trend_slope <dbl>,
#> #   ind_trend_p_value <dbl>, ind_trend_significant <lgl>,
#> #   ind_trend_min_slope <dbl>, ind_trend_max_slope <dbl>, …
```
