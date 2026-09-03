# Administrative border of Germany

A cached [sf::sf](https://r-spatial.github.io/sf/reference/sf.html)
polygon of Germany from `rnaturalearth`, projected to EPSG:25832. The
result is memoised for the session.

## Usage

``` r
lap_germany_border(scale = c("medium", "small", "large"))
```

## Arguments

- scale:

  Map scale passed to
  [`rnaturalearth::ne_countries()`](https://docs.ropensci.org/rnaturalearth/reference/ne_countries.html):
  `"small"`, `"medium"` or `"large"`.

## Value

An `sf` object with a single (MULTI)POLYGON feature.

## Examples

``` r
if (FALSE) { # \dontrun{
lap_germany_border()
} # }
```
