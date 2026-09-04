# Turn a variable name into a readable label

`snake_case` / `dotted.names` become sentence case with underscores
removed and domain acronyms (`gwl`, `sgi`, `spi`, ...) upper-cased; a
leading `ind_` (the indicator-column prefix) is dropped. Used as the
default `name` of the
[scale_lapidary](https://mxnl.github.io/lapidary/reference/scale_lapidary.md)
scales, and handy for axis titles and facet labellers.

## Usage

``` r
lap_prettify_label(x)
```

## Arguments

- x:

  A character vector (or a single value passed through unchanged if not
  a length-1 string, so it is safe as a ggplot2 `labeller` / scale
  `name`).

## Value

A character vector of prettified labels.

## Examples

``` r
lap_prettify_label(c("mean_gwl", "ind_trend_slope", "ind_drought_severity"))
#> [1] "Mean GWL"         "Trend slope"      "Drought severity"
```
