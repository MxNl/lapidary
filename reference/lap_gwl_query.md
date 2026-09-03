# Run a lazy query against a source and collect the result

Opens a DuckDB connection (or uses `con`), hands the lazy
[`lap_gwl_tbl()`](https://mxnl.github.io/lapidary/reference/lap_gwl_tbl.md)
to `fn`, collects the result, and closes the connection if it opened
one. This is the safe way to do a lazy filter/aggregate without managing
the connection lifetime yourself.

## Usage

``` r
lap_gwl_query(
  fn,
  source = "gems-ger",
  version = "latest",
  which = c("gwl", "meteo"),
  con = NULL
)
```

## Arguments

- fn:

  A function (or `\(tbl) ...` / `~ ...` formula) taking the lazy table
  and returning a lazy or eager result.

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
  it here. See also `lap_gwl_query()` for one-shot lazy pipelines.

## Value

A tibble (the collected result).

## Examples

``` r
if (FALSE) { # \dontrun{
lap_gwl_query("gems-ger", fn = \(t) dplyr::filter(t, well_id == "MW_1"))
} # }
```
