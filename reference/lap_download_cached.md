# Download a file with a checksum check and resume support

Download a file with a checksum check and resume support

## Usage

``` r
lap_download_cached(url, dest, md5 = NULL, overwrite = FALSE, quiet = FALSE)
```

## Arguments

- url:

  Source URL.

- dest:

  Destination path.

- md5:

  Optional expected MD5 checksum (hex string, with or without an `md5:`
  prefix).

- overwrite:

  Re-download even if `dest` exists and matches `md5`.

- quiet:

  Suppress the progress bar.

## Value

`dest`, invisibly.
