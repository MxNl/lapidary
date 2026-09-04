# Changelog

## lapidary 0.0.0.9000 (development)

First milestone: **data + analysis foundation**.

**Conventions** (see `docs/adr/0008`): the core API is `lap_`-prefixed;
ggplot2 extension points
([`theme_lapidary()`](https://mxnl.github.io/lapidary/reference/theme_lapidary.md),
`scale_*_lapidary_*()`,
[`ggsave_lapidary()`](https://mxnl.github.io/lapidary/reference/ggsave_lapidary.md))
and class constructors
([`new_gwl_ts()`](https://mxnl.github.io/lapidary/reference/new_gwl_ts.md),
…) keep their names. Column arguments use tidy evaluation (bare names,
strings, or tidyselect helpers).

### Plot builders (milestone 2, see `docs/adr/0012`)

- [`lap_plot_hex_map()`](https://mxnl.github.io/lapidary/reference/lap_plot_map.md)
  /
  [`lap_plot_point_map()`](https://mxnl.github.io/lapidary/reference/lap_plot_map.md)
  — the first `lap_plot_*` chart builders: a themed choropleth of a hex
  grid (or coloured well points) in one call, replacing the hand-written
  `geom_sf() + scale_fill_lapidary_c() + theme_lapidary()` block. Return
  a bare ggplot; auto-add a
  [`lap_na_guide()`](https://mxnl.github.io/lapidary/reference/lap_na_guide.md)
  when the value column has `NA`s; use the cyclic palette for
  circular-month columns; a POINT layer to
  [`lap_plot_hex_map()`](https://mxnl.github.io/lapidary/reference/lap_plot_map.md)
  dispatches to the point map.
- Every builder appends a localised “how to read this chart” explainer
  to `plot.caption` (`annotate = "caption"` default; `"callout"` /`NA` /
  a string; `options(lapidary.annotate = )`).
  [`lap_howto()`](https://mxnl.github.io/lapidary/reference/lap_howto.md)
  /
  [`lap_annotate_howto()`](https://mxnl.github.io/lapidary/reference/lap_annotate_howto.md).
- [`lap_variant()`](https://mxnl.github.io/lapidary/reference/lap_variant.md)
  — light/dark resolver mirroring
  [`lap_lang()`](https://mxnl.github.io/lapidary/reference/lap_lang.md)
  (`options(lapidary.variant = )` / `LAPIDARY_VARIANT`).
- [`theme_lapidary()`](https://mxnl.github.io/lapidary/reference/theme_lapidary.md)
  gains `panel = c("map", "xy", "ridge", "polar")` (`map = TRUE/FALSE`
  kept as a deprecated alias).
- [`lap_na_guide()`](https://mxnl.github.io/lapidary/reference/lap_na_guide.md)
  /
  [`lap_coloursteps_guide()`](https://mxnl.github.io/lapidary/reference/lap_coloursteps_guide.md)
  gain a `variant` argument (they previously always resolved
  light-variant token colours).
- `ggplot2` (`>= 3.5.0`), `ggtext`, `scales`, `scico` moved from
  Suggests to Imports.

### Data model

- `gwl_ts` (tidy long groundwater time series) and `gwl_wells` (`sf`
  well metadata) canonical shapes, with constructors, coercers and
  validators
  ([`new_gwl_ts()`](https://mxnl.github.io/lapidary/reference/new_gwl_ts.md),
  [`as_gwl_ts()`](https://mxnl.github.io/lapidary/reference/as_gwl_ts.md),
  [`validate_gwl_ts()`](https://mxnl.github.io/lapidary/reference/validate_gwl_ts.md),
  [`check_gwl_ts()`](https://mxnl.github.io/lapidary/reference/check_gwl_ts.md),
  [`new_gwl_wells()`](https://mxnl.github.io/lapidary/reference/new_gwl_wells.md),
  [`check_gwl_wells()`](https://mxnl.github.io/lapidary/reference/check_gwl_wells.md)).

### Ingest & caching

- Parquet-artifact / DuckDB-engine backend:
  [`lap_gwl_tbl()`](https://mxnl.github.io/lapidary/reference/lap_gwl_tbl.md)
  (lazy),
  [`lap_gwl_query()`](https://mxnl.github.io/lapidary/reference/lap_gwl_query.md)
  (lazy pipeline that manages its own connection),
  [`lap_read_gwl()`](https://mxnl.github.io/lapidary/reference/lap_read_gwl.md),
  [`lap_write_gwl_parquet()`](https://mxnl.github.io/lapidary/reference/lap_write_gwl_parquet.md),
  [`lap_csvs_to_parquet()`](https://mxnl.github.io/lapidary/reference/lap_csvs_to_parquet.md);
  `arrow` is optional.
- GEMS-GER reader:
  [`lap_gems_ger_download()`](https://mxnl.github.io/lapidary/reference/lap_gems_ger_download.md),
  [`lap_gems_ger_build_parquet()`](https://mxnl.github.io/lapidary/reference/lap_gems_ger_build_parquet.md),
  [`lap_read_gems_ger()`](https://mxnl.github.io/lapidary/reference/lap_read_gems_ger.md),
  [`lap_read_gems_ger_wells()`](https://mxnl.github.io/lapidary/reference/lap_read_gems_ger_wells.md),
  [`lap_gems_ger_meta()`](https://mxnl.github.io/lapidary/reference/lap_gems_ger_meta.md).
- CORRECTIV reader as a second source:
  [`lap_correctiv_download()`](https://mxnl.github.io/lapidary/reference/lap_correctiv_download.md),
  [`lap_correctiv_build_parquet()`](https://mxnl.github.io/lapidary/reference/lap_correctiv_build_parquet.md),
  [`lap_read_correctiv()`](https://mxnl.github.io/lapidary/reference/lap_read_correctiv.md),
  [`lap_read_correctiv_wells()`](https://mxnl.github.io/lapidary/reference/lap_read_correctiv_wells.md).
- Cache helpers:
  [`lap_cache_dir()`](https://mxnl.github.io/lapidary/reference/lap_cache_dir.md),
  [`lap_cache_info()`](https://mxnl.github.io/lapidary/reference/lap_cache_info.md).

### Analysis primitives

- [`lap_add_reference_period()`](https://mxnl.github.io/lapidary/reference/lap_add_reference_period.md),
  [`lap_reference_periods()`](https://mxnl.github.io/lapidary/reference/lap_reference_periods.md),
  [`lap_use_water_year()`](https://mxnl.github.io/lapidary/reference/lap_use_water_year.md).
- [`lap_period_windows()`](https://mxnl.github.io/lapidary/reference/lap_period_windows.md)
  derives a `periods` list from a record’s date range
  (`first_vs_last_decade`, `first_vs_last_half`, `decade_per_decade`, or
  from a `c(first_year, last_year)` vector) to feed
  [`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md)
  /
  [`lap_add_reference_period()`](https://mxnl.github.io/lapidary/reference/lap_add_reference_period.md)
  without hand-writing year pairs.
- [`lap_summarise_wells()`](https://mxnl.github.io/lapidary/reference/lap_summarise_wells.md)
  (in-memory or pushed down to DuckDB),
  [`lap_wells_with_coverage()`](https://mxnl.github.io/lapidary/reference/lap_wells_with_coverage.md).
- [`lap_normalise_gwl()`](https://mxnl.github.io/lapidary/reference/lap_normalise_gwl.md)
  — `range`, `zscore`, `sgi`.
- [`lap_gw_trend()`](https://mxnl.github.io/lapidary/reference/lap_gw_trend.md)
  — Theil–Sen slope + Mann–Kendall test.
- [`lap_make_hex_grid()`](https://mxnl.github.io/lapidary/reference/lap_make_hex_grid.md),
  [`lap_aggregate_to_hex()`](https://mxnl.github.io/lapidary/reference/lap_aggregate_to_hex.md),
  [`lap_circular_mean_month()`](https://mxnl.github.io/lapidary/reference/lap_circular_mean_month.md),
  [`lap_germany_border()`](https://mxnl.github.io/lapidary/reference/lap_germany_border.md).

### Time-series indicators (see `docs/adr/0009`, `docs/adr/0010`, `docs/adr/0011`)

- [`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md)
  collector +
  [`lap_add_indicators()`](https://mxnl.github.io/lapidary/reference/lap_add_indicators.md)
  for step-by-step appending; `ind_`-prefixed output columns. Per-well
  indicators and per-well-year summaries are separate tables (no
  `indicators=` on
  [`lap_summarise_wells()`](https://mxnl.github.io/lapidary/reference/lap_summarise_wells.md)).
- `.funs` selects indicators by `"all"`, registry key(s)
  (`c("amplitude", "trend")`) or `lap_ind_*` functions, and is required.
  `...` on
  [`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md)
  /
  [`lap_add_indicators()`](https://mxnl.github.io/lapidary/reference/lap_add_indicators.md)
  /
  [`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md)
  is forwarded to every `lap_ind_*()` (`threshold`, `min_len`, `driver`,
  …).
- [`lap_indicator_registry()`](https://mxnl.github.io/lapidary/reference/lap_indicator_registry.md)
  lists the catalogue (`key`, `columns`, `range`, `needs_date`,
  `in_all`, `description`, `reference`). Each `lap_ind_*()` also carries
  `@references`;
  [`vignette("indicators")`](https://mxnl.github.io/lapidary/articles/indicators.md)
  is the long-form guide.
- `range` gives each `ind_*` column’s theoretical value range in
  interval notation (`[0, 1]`, `(-Inf, Inf)`, `{FALSE, TRUE}`, …),
  `" | "`-separated and aligned with `columns`.
- Catalogue: `amplitude`, `seasonal_amplitude`, `seasonality_strength`,
  `recharge_discharge`, `phase_regularity`, `extreme_months`,
  `flashiness`, `memory` (autocorrelation / e-folding), `rise_fall`,
  `trend`, `trend_extremes` (Sen slope of annual minima / maxima),
  `step_change` (Pettitt), `trend_acceleration`, `recession`
  (master-recession e-folding time), and (opt-in, need an SGI column)
  `drought` (run-theory event structure: frequency, count, duration,
  severity, intensity), `drought_recovery` (recovery time from drought
  minima), `climate_signal`.
- `climate_signal` (needs an SGI column and a climate driver from
  [`lap_join_meteo()`](https://mxnl.github.io/lapidary/reference/lap_join_meteo.md)):
  SPI/SPEI-analog cross-correlation gives the driver accumulation, lag,
  `ind_response_months` and `ind_climate_cc`; the residual of
  `lm(SGI ~ SPI)` gives a climate-removed (anthropogenic) trend
  (`ind_residual_trend_slope` / `_p_value` / `_significant`).
- `lap_join_meteo(x, vars, version)` left-joins GEMS-GER `meteo.parquet`
  forcing columns (`HYRAS_pr`, `DWD_evapo_p`, …, optionally renamed)
  onto a GEMS-GER `gwl_ts`.
- `lap_indicator_change(x, .funs, periods)` computes any indicator over
  several (possibly overlapping) year windows -\> long
  `well_id | period | ind_*`. `lap_indicator_delta(change, from, to)`
  -\> one row per well with `<col>_<from>`, `<col>_<to>`, `<col>_change`
  (catalog-aware differencing).

### Style scheme & i18n

- [`lap_tokens()`](https://mxnl.github.io/lapidary/reference/lap_tokens.md),
  [`theme_lapidary()`](https://mxnl.github.io/lapidary/reference/theme_lapidary.md),
  `scale_fill/colour_lapidary_c/d()`,
  [`lap_accents()`](https://mxnl.github.io/lapidary/reference/lap_accents.md),
  [`lap_fonts()`](https://mxnl.github.io/lapidary/reference/lap_fonts.md).
- The continuous `scale_*_lapidary_c()` scales are now **binned** at
  pretty round breaks with a long, thin
  [`guide_coloursteps()`](https://ggplot2.tidyverse.org/reference/guide_coloursteps.html)
  bar
  ([`lap_coloursteps_guide()`](https://mxnl.github.io/lapidary/reference/lap_coloursteps_guide.md));
  pass `binned = FALSE` for a smooth gradient. Their legend title
  defaults to
  [`lap_prettify_label()`](https://mxnl.github.io/lapidary/reference/lap_prettify_label.md)
  of the mapped variable (`ind_trend_slope` -\> `"Trend slope"`);
  `range = TRUE` (or `options(lapidary.scale_range = TRUE)`) appends a
  known indicator’s theoretical range, e.g. `"Trend slope (−∞, ∞)"`.
  [`lap_na_guide()`](https://mxnl.github.io/lapidary/reference/lap_na_guide.md)
  adds a “no data” key for `NA` regions (e.g. empty hexes).
- `scale_fill/colour_lapidary_c(robust = TRUE)` (or a percentile spec,
  or `options(lapidary.scale_robust = TRUE)`) clips the colour limits to
  distribution-aware percentiles (default 2nd / 98th) so a few extreme
  values stop flattening the pattern for the bulk of the data.
  Out-of-range values take the end colour; on the binned default the
  clipped legend end is marked “≤” / “≥”. Off by default; an explicit
  `limits` wins; with `midpoint` the limits stay symmetric about the
  centre.
- [`ggsave_lapidary()`](https://mxnl.github.io/lapidary/reference/ggsave_lapidary.md)
  with web/A4–A0 presets that also fix `showtext` DPI.
- Bilingual (`en`/`de`) string registry:
  [`lap_tr()`](https://mxnl.github.io/lapidary/reference/lap_tr.md),
  [`lap_lang()`](https://mxnl.github.io/lapidary/reference/lap_lang.md),
  [`lap_langs()`](https://mxnl.github.io/lapidary/reference/lap_langs.md).

### Data

- `gems_ger_sample`, `gems_ger_wells_sample`, `germany_hex_sample`.

### Infrastructure

- [targets](https://docs.ropensci.org/targets/) pipeline
  (`_targets.R`) + `data-raw/make_sample_data.R` share the internal
  helpers in `R/sample-data.R`, so both regenerate identical
  `data/*.rda`.
- Architecture decision records under `docs/adr/`.

### Review-pass fixes (see `docs/adr/0004`–`0005`)

- `version = "latest"` now resolves to the newest built version
  directory in the generic backend
  ([`lap_read_gwl()`](https://mxnl.github.io/lapidary/reference/lap_read_gwl.md)
  /
  [`lap_gwl_tbl()`](https://mxnl.github.io/lapidary/reference/lap_gwl_tbl.md)
  no longer required a concrete version).
- [`lap_disconnect()`](https://mxnl.github.io/lapidary/reference/lap_disconnect.md)
  closes the connection behind a lazy table even after `dplyr` verbs
  (reads `tbl$src$con`); the fragile attribute is gone.
- [`lap_summarise_wells()`](https://mxnl.github.io/lapidary/reference/lap_summarise_wells.md)
  returns `NA` (not `Inf` / `NaN`) and emits no warning for an
  all-missing group.
- [`lap_gw_trend()`](https://mxnl.github.io/lapidary/reference/lap_gw_trend.md)
  warns when a group is larger than `warn_n` (it is O(n^2) and expects
  an annual series).
- [`lap_aggregate_to_hex()`](https://mxnl.github.io/lapidary/reference/lap_aggregate_to_hex.md)
  uses `dplyr` joins instead of `merge.sf`.
- [`lap_normalise_gwl()`](https://mxnl.github.io/lapidary/reference/lap_normalise_gwl.md)
  names its output `"<value>_norm"` (override with `into =`) and takes a
  tidy-select `date =` argument for `sgi`.
- Readers set `variable` at construction; the placeholder `vars`
  argument is removed from
  [`lap_read_gwl()`](https://mxnl.github.io/lapidary/reference/lap_read_gwl.md)
  /
  [`lap_read_gems_ger()`](https://mxnl.github.io/lapidary/reference/lap_read_gems_ger.md)
  /
  [`lap_read_correctiv()`](https://mxnl.github.io/lapidary/reference/lap_read_correctiv.md).
