# Keep only wells with enough temporal coverage

Keep only wells with enough temporal coverage

## Usage

``` r
lap_wells_with_coverage(summary, min_years = 20, min_coverage = 0.9)
```

## Arguments

- summary:

  A tibble from
  [`lap_summarise_wells()`](https://mxnl.github.io/lapidary/reference/lap_summarise_wells.md)
  grouped by `c("well_id", "year")`.

- min_years:

  Minimum number of years a well must have.

- min_coverage:

  Minimum per-year `coverage` for a year to count.

## Value

A character vector of `well_id`s that pass.
