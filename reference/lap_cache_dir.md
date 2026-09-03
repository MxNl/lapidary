# lapidary cache directory

Location for downloaded source datasets and derived artifacts (Parquet
trees, DuckDB files). Controlled by the `lapidary.cache_dir` option or
the `LAPIDARY_CACHE_DIR` environment variable; otherwise a per-user
cache directory from
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

## Usage

``` r
lap_cache_dir(..., create = FALSE)
```

## Arguments

- ...:

  Optional path components appended to the cache directory with
  [`file.path()`](https://rdrr.io/r/base/file.path.html).

- create:

  Whether to create the directory (and requested subpath) if it does not
  yet exist.

## Value

A normalised absolute path (character scalar).

## Examples

``` r
lap_cache_dir(create = FALSE)
#> [1] "/home/runner/.cache/R/lapidary"
```
