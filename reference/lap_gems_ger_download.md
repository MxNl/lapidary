# Download and extract the GEMS-GER dataset

Fetches `GEMS-GER_data.zip` (~290 MB) from Zenodo into the lapidary
cache and unzips it. Skips work already done.

## Usage

``` r
lap_gems_ger_download(
  version = "latest",
  dir = lap_cache_dir(),
  overwrite = FALSE,
  quiet = FALSE
)
```

## Arguments

- version:

  Version key or `"latest"`.

- dir:

  Cache root. Defaults to
  [`lap_cache_dir()`](https://mxnl.github.io/lapidary/reference/lap_cache_dir.md).

- overwrite:

  Force re-download.

- quiet:

  Suppress progress output.

## Value

Path to the extracted directory (holding `dynamic/` and `static/`),
invisibly.
