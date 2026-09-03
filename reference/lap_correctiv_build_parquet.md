# Build the CORRECTIV Parquet artifact

Build the CORRECTIV Parquet artifact

## Usage

``` r
lap_correctiv_build_parquet(overwrite = FALSE, value = c("mean", "min", "max"))
```

## Arguments

- overwrite:

  Overwrite an existing Parquet file.

- value:

  Which monthly statistic becomes `gwl`: `"mean"` (default), `"min"` or
  `"max"`. The other two are kept as extra columns.

## Value

The Parquet path, invisibly.
