# Get or set the default visual variant

Resolves the light/dark variant used by
[`theme_lapidary()`](https://mxnl.github.io/lapidary/reference/theme_lapidary.md)
and the plot builders when `variant` is not given explicitly. Reads the
`lapidary.variant` option or `LAPIDARY_VARIANT` environment variable,
falling back to `"light"`. The dark-first counterpart of
[`lap_lang()`](https://mxnl.github.io/lapidary/reference/lap_lang.md).

## Usage

``` r
lap_variant(variant = NULL)
```

## Arguments

- variant:

  Optional variant to validate and return; `NULL` (default) returns the
  configured default.

## Value

A single valid variant string.

## Examples

``` r
lap_variant()
#> [1] "light"
old <- options(lapidary.variant = "dark")
lap_variant()
#> [1] "dark"
options(old)
```
