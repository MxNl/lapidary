# Write a groundwater data frame to the Parquet cache

Uses DuckDB `COPY ... TO` so no `arrow` install is needed.

## Usage

``` r
lap_write_gwl_parquet(
  x,
  source,
  version = "1.0",
  which = c("gwl", "meteo"),
  overwrite = FALSE
)
```

## Arguments

- x:

  A data frame (long, with at least `well_id`, `date`, `gwl`).

- source:

  Source key.

- version:

  Concrete version string (not `"latest"`).

- which:

  `"gwl"` or `"meteo"`.

- overwrite:

  Overwrite an existing file.

## Value

The Parquet file path, invisibly.
