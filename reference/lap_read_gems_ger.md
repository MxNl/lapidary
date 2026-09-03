# Read GEMS-GER groundwater levels as a `gwl_ts`

Requires
[`lap_gems_ger_build_parquet()`](https://mxnl.github.io/lapidary/reference/lap_gems_ger_build_parquet.md)
to have been run for `version`.

## Usage

``` r
lap_read_gems_ger(version = "latest", wells = NULL, date_range = NULL)
```

## Arguments

- version:

  Version string, or `"latest"` (the newest built version).

- wells:

  Optional character vector of `well_id`s to keep.

- date_range:

  Optional length-2 `Date` (or coercible) vector.

## Value

A `gwl_ts` (`variable` = `"gwl_m_asl"`, `source` = `"gems-ger"`).
