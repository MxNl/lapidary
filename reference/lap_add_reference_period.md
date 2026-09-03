# Tag rows with a reference-period label

Adds a `reference_period` column marking which configured period each
observation falls into (by calendar year of `date_col`, or by `year_col`
if supplied). Rows outside every period get `NA`. Periods must not
overlap.

## Usage

``` r
lap_add_reference_period(
  x,
  periods = lap_reference_periods()["Z1"],
  date_col = date,
  year_col = NULL,
  drop = FALSE
)
```

## Arguments

- x:

  A `gwl_ts` or data frame.

- periods:

  Named list of `c(start_year, end_year)` pairs. Defaults to
  `lap_reference_periods()["Z1"]`.

- date_col:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  date column to derive the year from (bare name or string). Ignored if
  `year_col` is given. Defaults to `date`.

- year_col:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  optional integer year column to use directly instead of `date_col`.

- drop:

  If `TRUE`, keep only rows that fall inside a period.

## Value

`x` with a `reference_period` factor column (levels = `names(periods)`).

## Examples

``` r
df <- data.frame(date = as.Date(paste0(1985:1995, "-06-15")))
lap_add_reference_period(df)
#>          date reference_period
#> 1  1985-06-15             <NA>
#> 2  1986-06-15             <NA>
#> 3  1987-06-15             <NA>
#> 4  1988-06-15             <NA>
#> 5  1989-06-15             <NA>
#> 6  1990-06-15             <NA>
#> 7  1991-06-15               Z1
#> 8  1992-06-15               Z1
#> 9  1993-06-15               Z1
#> 10 1994-06-15               Z1
#> 11 1995-06-15               Z1
lap_add_reference_period(df, periods = lap_reference_periods()[c("Z0", "Z1")], drop = TRUE)
#>          date reference_period
#> 1  1985-06-15               Z0
#> 2  1986-06-15               Z0
#> 3  1987-06-15               Z0
#> 4  1988-06-15               Z0
#> 5  1989-06-15               Z0
#> 6  1990-06-15               Z0
#> 7  1991-06-15               Z1
#> 8  1992-06-15               Z1
#> 9  1993-06-15               Z1
#> 10 1994-06-15               Z1
#> 11 1995-06-15               Z1
```
