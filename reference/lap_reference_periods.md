# Standard climate reference periods

Named list of `c(start_year, end_year)` pairs. `Z1` (1991-2020) is the
current WMO climate normal; `Z0` (1961-1990) is the previous one, and
`Z2` (2021-2050) / `Z3` (2071-2100) are the near- and far-future slices
commonly used in climate-projection work.

## Usage

``` r
lap_reference_periods()
```

## Value

A named list of length-2 integer vectors.

## Examples

``` r
lap_reference_periods()
#> $Z0
#> [1] 1961 1990
#> 
#> $Z1
#> [1] 1991 2020
#> 
#> $Z2
#> [1] 2021 2050
#> 
#> $Z3
#> [1] 2071 2100
#> 
```
