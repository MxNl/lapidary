# Translate a registry string

Looks up `id` in the `lapidary` string registry and returns the value
for `lang`. Simple `{name}` placeholders are filled from `...`.

## Usage

``` r
lap_tr(id, lang = NULL, ...)
```

## Arguments

- id:

  String id present in the registry.

- lang:

  Language code; defaults to
  [`lap_lang()`](https://mxnl.github.io/lapidary/reference/lap_lang.md).

- ...:

  Named values substituted into `{placeholder}` tokens.

## Value

A character vector (usually length 1, but e.g. `month_names` is 12).

## Examples

``` r
lap_tr("app_title", "de")
#> [1] "Grundwasser in Deutschland"
lap_tr("by_author", author = "Max")
#> [1] "By Max"
```
