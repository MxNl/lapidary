# lapidary options

`lapidary` reads a handful of options. Those with an
environment-variable counterpart take it as a fallback (the option
wins); `lapidary.scale_range` and `lapidary.scale_robust` are
option-only.

## Details

- `lapidary.cache_dir` / `LAPIDARY_CACHE_DIR`:

  Directory for downloaded and derived datasets. Defaults to
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

- `lapidary.lang` / `LAPIDARY_LANG`:

  Default language for user-facing labels, one of `"en"` or `"de"`.
  Defaults to `"en"`.

- `lapidary.variant` / `LAPIDARY_VARIANT`:

  Default visual variant for
  [`theme_lapidary()`](https://mxnl.github.io/lapidary/reference/theme_lapidary.md)
  and the plot builders, `"light"` or `"dark"`. Defaults to `"light"`.

- `lapidary.annotate`:

  Default for the `annotate` argument of the plot builders: `"caption"`
  (a how-to-read explainer in `plot.caption`), `"callout"`, or `NA` to
  suppress. Option-only.

- `lapidary.scale_range`:

  Logical, default `FALSE`. When `TRUE` the continuous
  `scale_*_lapidary_c()` scales append a mapped `ind_*` column's
  theoretical range to the legend title (same as `range = TRUE`).

- `lapidary.scale_robust`:

  Logical / numeric, default `FALSE`. Global default for the `robust`
  argument of `scale_*_lapidary_c()`: clip the colour limits to
  distribution-aware percentiles (`TRUE` = 2nd / 98th).
