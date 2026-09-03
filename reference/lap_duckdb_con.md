# Open a DuckDB connection

Open a DuckDB connection

## Usage

``` r
lap_duckdb_con(dbdir = ":memory:", read_only = FALSE)
```

## Arguments

- dbdir:

  Database file, or `":memory:"` (default).

- read_only:

  Open read-only.

## Value

A DBI connection (see
[`DBI::dbConnect()`](https://dbi.r-dbi.org/reference/dbConnect.html)).
Close it with
[`lap_disconnect()`](https://mxnl.github.io/lapidary/reference/lap_disconnect.md).
