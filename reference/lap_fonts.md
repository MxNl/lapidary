# Register the lapidary fonts

Registers the Google fonts used by the lapidary style (Oleo Script for
titles, Dosis for everything else) via sysfonts and enables showtext.
Safe to call repeatedly. If the fonts or the packages are unavailable
(for example on a headless CI machine) it warns once and does nothing,
so downstream theme code must always provide fallback families.

## Usage

``` r
lap_fonts(enable_showtext = TRUE, quiet = FALSE)
```

## Arguments

- enable_showtext:

  Whether to call
  [`showtext::showtext_auto()`](https://rdrr.io/pkg/showtext/man/showtext_auto.html).

- quiet:

  Suppress the informational message.

## Value

`TRUE` if the fonts are registered, `FALSE` otherwise (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
lap_fonts()
} # }
```
