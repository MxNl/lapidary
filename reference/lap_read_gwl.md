# Read a validated groundwater time series from the Parquet cache

Convenience wrapper around
[`lap_gwl_tbl()`](https://mxnl.github.io/lapidary/reference/lap_gwl_tbl.md)
that applies optional filters, pulls the data into memory and returns a
[`new_gwl_ts()`](https://mxnl.github.io/lapidary/reference/new_gwl_ts.md).

## Usage

``` r
lap_read_gwl(
  source = "gems-ger",
  version = "latest",
  wells = NULL,
  date_range = NULL,
  variable = "gwl_m_asl"
)
```

## Arguments

- source:

  Source key. Default `"gems-ger"`.

- version:

  Version string, or `"latest"` (the newest built version).

- wells:

  Optional character vector of `well_id`s to keep.

- date_range:

  Optional length-2 `Date` (or coercible) vector.

- variable:

  Value passed to
  [`new_gwl_ts()`](https://mxnl.github.io/lapidary/reference/new_gwl_ts.md)
  for the `variable` column (names the quantity + units, e.g.
  `"gwl_m_asl"`).

## Value

A `gwl_ts`.
