# Per-well (and per-period) groundwater summaries

Collapses a groundwater time series to one row per group, where the
grouping is usually the well and optionally the (water) year. Works both
on an in-memory `gwl_ts` / data frame and on a lazy `dplyr` table backed
by DuckDB (see
[`lap_gwl_tbl()`](https://mxnl.github.io/lapidary/reference/lap_gwl_tbl.md));
in the lazy case the aggregation is pushed down to the database and you
get a lazy result back unless `collect = TRUE`.

## Usage

``` r
lap_summarise_wells(
  x,
  by = c(well_id, year),
  value = gwl,
  expected_per_year = 52,
  collect = TRUE
)
```

## Arguments

- x:

  A `gwl_ts`, data frame, or lazy `dplyr` tbl.

- by:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  grouping columns: bare names, strings, or helpers. Defaults to
  `c(well_id, year)`; a `year` column is derived from `date` if it is
  requested but absent.

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the single column to summarise. Defaults to `gwl`.

- expected_per_year:

  Nominal observations per full year, for `coverage`.

- collect:

  If `x` is lazy, whether to
  [`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
  the result.

## Value

A tibble (or lazy tbl) with the grouping columns plus `min_gwl`,
`max_gwl`, `mean_gwl`, `median_gwl`, `sd_gwl`, `n_obs`, `coverage`.

Derived per-well metrics (amplitude, trend, extreme-month timing, ...)
are a separate table - see
[`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md) -
joined on `well_id` when you want both.

## Details

`coverage` is the fraction of the expected number of observations that
are actually present, using `expected_per_year` as the nominal count for
a full year (52 for weekly GEMS-GER data, 12 for monthly series). For
groupings without a year component `coverage` is `NA`.

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
lap_summarise_wells(gems_ger_sample, by = c(well_id, year))
#> # A tibble: 1,280 × 9
#>    well_id  year min_gwl max_gwl mean_gwl median_gwl sd_gwl n_obs coverage
#>    <chr>   <int>   <dbl>   <dbl>    <dbl>      <dbl>  <dbl> <int>    <dbl>
#>  1 MW_1039  1991    412.    413.     412.       412.  0.289    52     1   
#>  2 MW_1039  1992    412.    413.     412.       412.  0.362    52     1   
#>  3 MW_1039  1993    412.    413.     412.       412.  0.262    52     1   
#>  4 MW_1039  1994    412.    413.     412.       412.  0.227    52     1   
#>  5 MW_1039  1995    412.    413.     412.       412.  0.293    52     1   
#>  6 MW_1039  1996    412.    413.     412.       412.  0.215    53     1.02
#>  7 MW_1039  1997    412.    413.     412.       412.  0.262    52     1   
#>  8 MW_1039  1998    412.    413.     412.       412.  0.338    52     1   
#>  9 MW_1039  1999    412.    414.     412.       412.  0.373    52     1   
#> 10 MW_1039  2000    412.    413.     412.       412.  0.269    52     1   
#> # ℹ 1,270 more rows
lap_summarise_wells(gems_ger_sample, by = "well_id", value = gwl)
#> # A tibble: 40 × 8
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
```
