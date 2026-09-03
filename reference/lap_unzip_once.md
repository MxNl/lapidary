# Unzip an archive once

Unzip an archive once

## Usage

``` r
lap_unzip_once(zip, exdir, sentinel = NULL)
```

## Arguments

- zip:

  Path to a `.zip` file.

- exdir:

  Target directory.

- sentinel:

  A relative path inside `exdir` whose existence means the archive is
  already extracted.

## Value

`exdir`, invisibly.
