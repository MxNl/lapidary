# Read GEMS-GER well metadata as a `gwl_wells` layer

Read GEMS-GER well metadata as a `gwl_wells` layer

## Usage

``` r
lap_read_gems_ger_wells(version = "latest", attributes = "core")
```

## Arguments

- version:

  Version key or `"latest"`.

- attributes:

  Which static columns to keep: `"core"` (a curated subset), `"all"`, or
  a character vector of column names (original casing).

## Value

A `gwl_wells` `sf` layer in EPSG:25832.
