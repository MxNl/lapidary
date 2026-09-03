# Normalise groundwater levels for cross-region comparison

Absolute groundwater levels (m above sea level, or depth below ground)
are not comparable between wells. `lap_normalise_gwl()` adds a
`gwl_norm` column holding a per-well normalised series, so that dynamics
rather than absolute magnitude can be compared and plotted.

## Usage

``` r
lap_normalise_gwl(
  x,
  method = c("range", "zscore", "sgi"),
  value = gwl,
  group = well_id,
  date = "date",
  into = NULL
)
```

## Arguments

- x:

  A `gwl_ts` (or data frame with `well_id`, `date`, `gwl`).

- method:

  One of `"range"`, `"zscore"`, `"sgi"`.

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the single column to normalise. Default `gwl`.

- group:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  columns identifying an independent series. Default `well_id`.

- date:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the date column, used only by `"sgi"` (to deseasonalise). Default
  `date`.

- into:

  Name of the column to add. Default `"<value>_norm"`.

## Value

`x` with the `into` column added.

## Details

Methods:

- `"range"`:

  Rescale each well to `[0, 1]` using its own min/max.

- `"zscore"`:

  Subtract each well's mean and divide by its SD.

- `"sgi"`:

  Standardised Groundwater Index (Bloomfield & Marchant, 2013): a
  non-parametric normal-scores transform applied within each calendar
  month of each well, yielding an approximately standard-normal,
  deseasonalised index.

## References

Bloomfield, J. P. and Marchant, B. P. (2013). Analysis of groundwater
drought building on the standardised precipitation index approach.
Hydrology and Earth System Sciences, 17, 4769-4787.

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
head(lap_normalise_gwl(gems_ger_sample, "sgi"))
#> <gwl_ts> 6 rows | 1 well | 1991-01-07 .. 1991-02-11
#> variable: gwl_m_asl | source: gems-ger
#> # A tibble: 6 × 10
#>   well_id date         gwl variable  source   gwl_flag water_year water_month
#>   <chr>   <date>     <dbl> <chr>     <chr>    <fct>         <int>       <int>
#> 1 MW_1039 1991-01-07  413. gwl_m_asl gems-ger observed       1991           3
#> 2 MW_1039 1991-01-14  412. gwl_m_asl gems-ger observed       1991           3
#> 3 MW_1039 1991-01-21  412. gwl_m_asl gems-ger observed       1991           3
#> 4 MW_1039 1991-01-28  412. gwl_m_asl gems-ger observed       1991           3
#> 5 MW_1039 1991-02-04  412. gwl_m_asl gems-ger observed       1991           4
#> 6 MW_1039 1991-02-11  412. gwl_m_asl gems-ger observed       1991           4
#> # ℹ 2 more variables: reference_period <fct>, gwl_norm <dbl>
```
