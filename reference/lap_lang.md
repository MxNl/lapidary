# Get or set the default label language

Resolves the language used by label/caption helpers when `lang` is not
given explicitly. Reads the `lapidary.lang` option or `LAPIDARY_LANG`
environment variable, falling back to `"en"`.

## Usage

``` r
lap_lang(lang = NULL)
```

## Arguments

- lang:

  Optional language code to validate and return. If `NULL` (default) the
  configured default is returned.

## Value

A single valid language code.

## Examples

``` r
lap_lang()
#> [1] "en"
old <- options(lapidary.lang = "de")
lap_lang()
#> [1] "de"
options(old)
```
