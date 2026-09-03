# Close a DuckDB connection

Accepts a connection, or a lazy `dplyr` table backed by one (including
the result of
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
etc. applied to a
[`lap_gwl_tbl()`](https://mxnl.github.io/lapidary/reference/lap_gwl_tbl.md)).
Idempotent.

## Usage

``` r
lap_disconnect(x)
```

## Arguments

- x:

  A DBI connection or a lazy `tbl`.

## Value

`NULL`, invisibly.
