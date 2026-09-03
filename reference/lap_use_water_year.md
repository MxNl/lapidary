# Add hydrological (water) year and month columns

The hydrological year in Germany conventionally starts on 1 November.
This helper adds a `water_year` integer column (the calendar year in
which the hydrological year *ends*) and a `water_month` column (1 =
first month of the hydrological year).

## Usage

``` r
lap_use_water_year(x, start_month = 11L, date_col = date)
```

## Arguments

- x:

  A `gwl_ts` (or any data frame with a date column).

- start_month:

  Integer 1-12, the calendar month the hydrological year begins.
  Defaults to `11` (November).

- date_col:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the date column (bare name or string). Defaults to `date`.

## Value

`x` with `water_year` and `water_month` columns added.

## Examples

``` r
df <- data.frame(date = as.Date(c("2019-10-15", "2019-11-15", "2020-05-15")))
lap_use_water_year(df)
#>         date water_year water_month
#> 1 2019-10-15       2019          12
#> 2 2019-11-15       2020           1
#> 3 2020-05-15       2020           7
```
