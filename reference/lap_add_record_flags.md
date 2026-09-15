# Flag new all-time annual low / high records

Tags, for each well, the single timestep of each calendar year that is
that year's minimum / maximum - but only when that annual extreme is
itself a new all-time record for the well, beating every *prior* year's
annual extreme. A well can set at most one new-low and one new-high
record per year (possibly both, possibly neither); every other row is
`FALSE`. Aggregate the flags across wells (see
[`lap_summarise_calendar()`](https://mxnl.github.io/lapidary/reference/lap_summarise_calendar.md))
to see whether record-setting years cluster in particular periods.

## Usage

``` r
lap_add_record_flags(
  x,
  value = gwl,
  group = well_id,
  date = "date",
  into_min = NULL,
  into_max = NULL,
  into_balance = NULL
)
```

## Arguments

- x:

  A `gwl_ts` (or data frame with `well_id`, `date`, `gwl`).

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the column to evaluate. Default `gwl`.

- group:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  columns identifying an independent series. Default `well_id`.

- date:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the date column, used to derive the calendar year and to order each
  group chronologically. Default `date`.

- into_min, into_max, into_balance:

  Names of the columns to add. Default `"is_new_min"` / `"is_new_max"` /
  `"record_balance"`. `record_balance` is `into_max - into_min` as an
  integer (`+1` on a new-high row, `-1` on a new-low row, `0` everywhere
  else) - summing it in
  [`lap_summarise_calendar()`](https://mxnl.github.io/lapidary/reference/lap_summarise_calendar.md)
  gives the *net* balance of highs vs lows per bucket directly
  (summation is linear, so this is identical to summing the two flags
  separately and subtracting), letting
  [`lap_plot_calendar()`](https://mxnl.github.io/lapidary/reference/lap_plot_calendar.md)
  draw one divergent panel instead of two separate ones.

## Value

`x` with the `into_min` / `into_max` logical columns and the
`into_balance` integer column added.

## Details

A well's first year is not evaluated for records at all: there is no
real prior year to compare against, so flagging its own annual min/max
would either look like a genuine record (misleading) or, left `FALSE`,
look identical to a genuine non-record year (also misleading -
indistinguishable from "no baseline yet"). Its `into_min` / `into_max` /
`into_balance` are `NA` instead for every row of that year, and
[`lap_summarise_calendar()`](https://mxnl.github.io/lapidary/reference/lap_summarise_calendar.md)
excludes (does not zero-fill) `NA` contributions - so a well's first
year produces no tile at all in a
[`lap_plot_calendar()`](https://mxnl.github.io/lapidary/reference/lap_plot_calendar.md)
grid, rather than a misleading blank/neutral one. The first year's own
min/max still silently seed the running record that its second year is
compared against. Ties are not records - a year's annual extreme equal
to the running record neither sets nor breaks it, mirroring the usual
"record broken" vs "record tied" distinction. If a year's own annual
extreme is tied across more than one timestep, only the first
chronologically is flagged, so a well never gets more than one `TRUE`
per year per direction. `NA` values are excluded from a year's min/max;
a well-year with only `NA` values contributes nothing (neither sets a
record nor updates the running one).

This has no correction for two things that can confound a "records over
time" comparison: a well added to the network later shows an elevated
record rate in its own early years purely for lacking a long baseline,
and a growing monitoring network means more wells are at risk of setting
a record in later years than in earlier ones. Feed a dataset with a
stable set of wells over the period you are comparing if that matters
for your conclusion; this function does not do it for you.

## See also

[`lap_summarise_calendar()`](https://mxnl.github.io/lapidary/reference/lap_summarise_calendar.md),
[`lap_plot_calendar()`](https://mxnl.github.io/lapidary/reference/lap_plot_calendar.md)

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
head(lap_add_record_flags(gems_ger_sample))
#> <gwl_ts> 6 rows | 1 well | 1991-01-07 .. 1991-02-11
#> variable: gwl_m_asl | source: gems-ger
#> # A tibble: 6 × 12
#>   well_id date         gwl variable  source   gwl_flag water_year water_month
#>   <chr>   <date>     <dbl> <chr>     <chr>    <fct>         <int>       <int>
#> 1 MW_1039 1991-01-07  413. gwl_m_asl gems-ger observed       1991           3
#> 2 MW_1039 1991-01-14  412. gwl_m_asl gems-ger observed       1991           3
#> 3 MW_1039 1991-01-21  412. gwl_m_asl gems-ger observed       1991           3
#> 4 MW_1039 1991-01-28  412. gwl_m_asl gems-ger observed       1991           3
#> 5 MW_1039 1991-02-04  412. gwl_m_asl gems-ger observed       1991           4
#> 6 MW_1039 1991-02-11  412. gwl_m_asl gems-ger observed       1991           4
#> # ℹ 4 more variables: reference_period <fct>, is_new_min <lgl>,
#> #   is_new_max <lgl>, record_balance <int>
```
