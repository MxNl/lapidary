# Circular mean of a month-of-year value

Averaging "month of annual minimum" naively is wrong (December and
January are one month apart, not eleven). This maps months onto the unit
circle, averages, and maps back to the `[1, 12]` range.

## Usage

``` r
lap_circular_mean_month(month, na.rm = TRUE)
```

## Arguments

- month:

  Numeric vector of months (may be fractional, 1-12).

- na.rm:

  Drop `NA`s before averaging.

## Value

A single numeric month in `(0, 12]`.

## Examples

``` r
lap_circular_mean_month(c(12, 1, 2))
#> [1] 1
```
