# lapidary design tokens

Returns a nested list of design tokens for one visual `variant`.
Downstream code should read tokens through this function rather than
hard-coding values, so that a restyle happens in one place.

## Usage

``` r
lap_tokens(variant = c("light", "dark"))
```

## Arguments

- variant:

  `"light"` (default) or `"dark"`.

## Value

A list with elements `variant`, `colour` (named colours), `font` (family
names + a logical `available`), `size` (type sizes, relative to a base
size of 1), `spacing` and `effect` (e.g. shadow sigma).

## Examples

``` r
lap_tokens()$colour$recharge
#> [1] "#506ea7"
lap_tokens("dark")$colour$panel
#> [1] "#040720"
```
