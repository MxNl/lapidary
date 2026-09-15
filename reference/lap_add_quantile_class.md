# Classify groundwater levels into per-well percentile bands

Tags every row with which percentile band of *that well's own*
distribution it falls into - the German hydrological-service
groundwater-level classification ("Grundwasserstandsklassen") used in
weekly LfU / BGR / HLNUG bulletins: very low / low / below normal /
normal / above normal / high / very high, split at the 5th, 10th, 25th,
75th, 90th and 95th percentile.

## Usage

``` r
lap_add_quantile_class(
  x,
  value = gwl,
  group = well_id,
  date = "date",
  breaks = c(0, 0.05, 0.1, 0.25, 0.75, 0.9, 0.95, 1),
  labels = NULL,
  lang = NULL,
  reference = NULL,
  into = NULL
)
```

## Arguments

- x:

  A `gwl_ts` (or data frame with `well_id`, `date`, `gwl`).

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the column to classify. Default `gwl`.

- group:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  columns identifying an independent series (breakpoints are computed
  once per group). Default `well_id`.

- date:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the date column, used only when `reference` is given. Default `date`.

- breaks:

  Percentile cut points, `[0, 1]`, increasing. Default
  `c(0, .05, .10, .25, .75, .90, .95, 1)` (7 bands).

- labels:

  Band labels, one shorter than `breaks`. `NULL` (default) uses the
  built-in bilingual `gwl_class_labels` (see `lang`); pass your own
  7-vector to override.

- lang:

  Language for the default `labels`; defaults to
  [`lap_lang()`](https://mxnl.github.io/lapidary/reference/lap_lang.md).
  Ignored if `labels` is given.

- reference:

  `NULL` (default) computes breakpoints from a well's whole record. Or
  `c(start_year, end_year)` (or a single named period, e.g.
  `lap_reference_periods()["Z1"]`): breakpoints are computed from only
  the rows in that window, then *every* row (in or out of it) is
  classified against them - a fixed "normal" the way a climate normal
  works.

- into:

  Name of the column to add. Default `"<value>_class"`.

## Value

`x` with the `into` column added: an ordered factor, levels from low to
high. A group whose reference values are all identical (nothing to split
into bands) gets `NA` for every row, with a warning.

## Details

The breakpoints are computed independently for each well (a well's own
history is the yardstick for what counts as "normal" for it), then every
row of that well is classified against them - so the result is
comparable across wells with very different absolute levels.

## References

Bloomfield, J. P. and Marchant, B. P. (2013) as for
[`lap_normalise_gwl()`](https://mxnl.github.io/lapidary/reference/lap_normalise_gwl.md);
the band scheme follows the German state groundwater services' weekly
bulletin convention (e.g. Bayerisches Landesamt fuer Umwelt,
"Grundwasserstandsklassen").

## See also

[`lap_summarise_composition()`](https://mxnl.github.io/lapidary/reference/lap_summarise_composition.md),
[`lap_plot_stream()`](https://mxnl.github.io/lapidary/reference/lap_plot_stream.md)

## Examples

``` r
data(gems_ger_sample, package = "lapidary", envir = environment())
head(lap_add_quantile_class(gems_ger_sample))
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
#> # ℹ 2 more variables: reference_period <fct>, gwl_class <ord>
```
