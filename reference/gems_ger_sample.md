# GEMS-GER sample groundwater time series

A small, spatially spread subset of the GEMS-GER dataset for examples,
tests and vignettes: weekly groundwater levels (m above sea level) for
~40 monitoring wells, 1991-2022, already passed through
[`lap_use_water_year()`](https://mxnl.github.io/lapidary/reference/lap_use_water_year.md)
and
[`lap_add_reference_period()`](https://mxnl.github.io/lapidary/reference/lap_add_reference_period.md).

## Usage

``` r
gems_ger_sample
```

## Format

A [gwl_ts](https://mxnl.github.io/lapidary/reference/new_gwl_ts.md)
tibble with columns `well_id`, `date`, `gwl`, `variable`, `source`,
`gwl_flag`, `water_year`, `water_month`, `reference_period`.

## Source

GEMS-GER, Wunsch, Liesch & Broda (2026), doi:10.5281/zenodo.15530171,
licence CC-BY-NC-ND 4.0. See
[`lap_gems_ger_meta()`](https://mxnl.github.io/lapidary/reference/lap_gems_ger_meta.md).
