# Lazy table over a source's groundwater Parquet dataset

Returns a lazy `dplyr` table (backed by DuckDB) over the core
groundwater Parquet file for `source`. Filtering and aggregation on the
result are pushed down to DuckDB; call
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
to materialise, or use
[`lap_read_gwl()`](https://mxnl.github.io/lapidary/reference/lap_read_gwl.md)
which returns a validated `gwl_ts`.

## Usage

``` r
lap_gwl_tbl(
  source = "gems-ger",
  version = "latest",
  which = c("gwl", "meteo"),
  con = NULL
)
```

## Arguments

- source:

  Source key. Default `"gems-ger"`.

- version:

  Version string, or `"latest"` (the newest built version).

- which:

  One of `"gwl"` (core levels) or `"meteo"` (forcing variables).

- con:

  Optional existing DuckDB connection. If `NULL` a fresh in-memory
  connection is opened; close it afterwards with
  [`lap_disconnect()`](https://mxnl.github.io/lapidary/reference/lap_disconnect.md)
  (which also accepts the result of `dplyr` verbs applied to this
  table). For a long-running app, open one connection yourself and pass
  it here. See also
  [`lap_gwl_query()`](https://mxnl.github.io/lapidary/reference/lap_gwl_query.md)
  for one-shot lazy pipelines.

## Value

A lazy `tbl`.
