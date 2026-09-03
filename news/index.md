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
  lists the catalogue (`key`, `columns`, `needs_date`, `in_all`,
  `description`, `reference`). Each `lap_ind_*()` also carries
  `@references`;
  [`vignette("indicators")`](https://mxnl.github.io/lapidary/articles/indicators.md)
  is the long-form guide.
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
