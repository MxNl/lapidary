# Directory holding a source's Parquet artifacts

Directory holding a source's Parquet artifacts

## Usage

``` r
lap_parquet_dir(source, version = "latest", create = FALSE)
```

## Arguments

- source:

  Source key (e.g. `"gems-ger"`).

- version:

  Version string, or `"latest"` (resolved to the newest built version
  directory unless `create = TRUE`).

- create:

  Create the directory. When `TRUE`, `"latest"` is *not* resolved (there
  may be nothing to resolve yet) - pass a concrete version.

## Value

A path string.
