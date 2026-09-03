# Build the GEMS-GER Parquet artifacts

Converts the per-well CSVs into `gwl.parquet` (`well_id`, `date`, `gwl`,
`gwl_flag`) and, optionally, `meteo.parquet` (`well_id`, `date`, forcing
columns) in the lapidary cache. DuckDB does the conversion in one query;
run once per dataset version.

## Usage

``` r
lap_gems_ger_build_parquet(version = "latest", overwrite = FALSE, meteo = TRUE)
```

## Arguments

- version:

  Version key or `"latest"`.

- overwrite:

  Overwrite existing Parquet files.

- meteo:

  Also build `meteo.parquet`.

## Value

The Parquet paths, invisibly.
