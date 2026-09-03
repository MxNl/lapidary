# Build a hexagonal grid covering a region

Build a hexagonal grid covering a region

## Usage

``` r
lap_make_hex_grid(region, cellsize = 25000, clip = TRUE)
```

## Arguments

- region:

  An `sf` polygon (e.g.
  [`lap_germany_border()`](https://mxnl.github.io/lapidary/reference/lap_germany_border.md))
  or any `sf` object whose bounding box / union defines the extent.

- cellsize:

  Hexagon size in CRS units (metres for EPSG:25832). Default `25000`.

- clip:

  If `TRUE`, keep only hexagons intersecting `region`.

## Value

An `sf` polygon layer with a `hex_id` column.
