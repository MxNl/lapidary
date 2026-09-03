# Build a `gwl_wells` well-metadata layer

Build a `gwl_wells` well-metadata layer

## Usage

``` r
new_gwl_wells(x, coords = c("x", "y"), crs = gwl_wells_crs)
```

## Arguments

- x:

  An `sf` POINT object, or a data frame plus `coords`.

- coords:

  When `x` is a plain data frame, a length-2 character vector of the x/y
  coordinate columns.

- crs:

  Coordinate reference system of the incoming coordinates. The result is
  transformed to EPSG:25832 (ETRS89 / UTM 32N).

## Value

A `gwl_wells` object (a classed `sf` tibble) in EPSG:25832.
