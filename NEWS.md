# lapidary 0.0.0.9000 (development)

First milestone: **data + analysis foundation**.

**Conventions** (see `docs/adr/0008`): the core API is `lap_`-prefixed;
ggplot2 extension points (`theme_lapidary()`, `scale_*_lapidary_*()`,
`ggsave_lapidary()`) and class constructors (`new_gwl_ts()`, ...) keep their
names. Column arguments use tidy evaluation (bare names, strings, or
tidyselect helpers).

## Data model
* `gwl_ts` (tidy long groundwater time series) and `gwl_wells` (`sf` well
  metadata) canonical shapes, with constructors, coercers and validators
  (`new_gwl_ts()`, `as_gwl_ts()`, `validate_gwl_ts()`, `check_gwl_ts()`,
  `new_gwl_wells()`, `check_gwl_wells()`).

## Ingest & caching
* Parquet-artifact / DuckDB-engine backend: `lap_gwl_tbl()` (lazy),
  `lap_gwl_query()` (lazy pipeline that manages its own connection),
  `lap_read_gwl()`, `lap_write_gwl_parquet()`, `lap_csvs_to_parquet()`;
  `arrow` is optional.
* GEMS-GER reader: `lap_gems_ger_download()`, `lap_gems_ger_build_parquet()`,
  `lap_read_gems_ger()`, `lap_read_gems_ger_wells()`, `lap_gems_ger_meta()`.
* CORRECTIV reader as a second source: `lap_correctiv_download()`,
  `lap_correctiv_build_parquet()`, `lap_read_correctiv()`, `lap_read_correctiv_wells()`.
* Cache helpers: `lap_cache_dir()`, `lap_cache_info()`.

## Analysis primitives
* `lap_add_reference_period()`, `lap_reference_periods()`, `lap_use_water_year()`.
* `lap_period_windows()` derives a `periods` list from a record's date range
  (`first_vs_last_decade`, `first_vs_last_half`, `decade_per_decade`, or from a
  `c(first_year, last_year)` vector) to feed `lap_indicator_change()` /
  `lap_add_reference_period()` without hand-writing year pairs.
* `lap_summarise_wells()` (in-memory or pushed down to DuckDB),
  `lap_wells_with_coverage()`.
* `lap_normalise_gwl()` — `range`, `zscore`, `sgi`.
* `lap_gw_trend()` — Theil–Sen slope + Mann–Kendall test.
* `lap_make_hex_grid()`, `lap_aggregate_to_hex()`, `lap_circular_mean_month()`,
  `lap_germany_border()`.

## Time-series indicators (see `docs/adr/0009`, `docs/adr/0010`, `docs/adr/0011`)
* `lap_indicators()` collector + `lap_add_indicators()` for step-by-step
  appending; `ind_`-prefixed output columns. Per-well indicators and
  per-well-year summaries are separate tables (no `indicators=` on
  `lap_summarise_wells()`).
* `.funs` selects indicators by `"all"`, registry key(s) (`c("amplitude",
  "trend")`) or `lap_ind_*` functions, and is required. `...` on
  `lap_indicators()` / `lap_add_indicators()` / `lap_indicator_change()` is
  forwarded to every `lap_ind_*()` (`threshold`, `min_len`, `driver`, ...).
* `lap_indicator_registry()` lists the catalogue (`key`, `columns`, `range`,
  `needs_date`, `in_all`, `description`, `reference`). Each `lap_ind_*()` also
  carries `@references`; `vignette("indicators")` is the long-form guide.
* `range` gives each `ind_*` column's theoretical value range in interval
  notation (`[0, 1]`, `(-Inf, Inf)`, `{FALSE, TRUE}`, ...), `" | "`-separated
  and aligned with `columns`.
* Catalogue: `amplitude`, `seasonal_amplitude`, `seasonality_strength`,
  `recharge_discharge`, `phase_regularity`, `extreme_months`, `flashiness`,
  `memory` (autocorrelation / e-folding), `rise_fall`, `trend`,
  `trend_extremes` (Sen slope of annual minima / maxima), `step_change`
  (Pettitt), `trend_acceleration`, `recession` (master-recession e-folding
  time), and (opt-in, need an SGI column) `drought` (run-theory event
  structure: frequency, count, duration, severity, intensity),
  `drought_recovery` (recovery time from drought minima), `climate_signal`.
* `climate_signal` (needs an SGI column and a climate driver from
  `lap_join_meteo()`): SPI/SPEI-analog cross-correlation gives the driver
  accumulation, lag, `ind_response_months` and `ind_climate_cc`; the residual
  of `lm(SGI ~ SPI)` gives a climate-removed (anthropogenic) trend
  (`ind_residual_trend_slope` / `_p_value` / `_significant`).
* `lap_join_meteo(x, vars, version)` left-joins GEMS-GER `meteo.parquet`
  forcing columns (`HYRAS_pr`, `DWD_evapo_p`, ..., optionally renamed) onto a
  GEMS-GER `gwl_ts`.
* `lap_indicator_change(x, .funs, periods)` computes any indicator over several
  (possibly overlapping) year windows -> long `well_id | period | ind_*`.
  `lap_indicator_delta(change, from, to)` -> one row per well with
  `<col>_<from>`, `<col>_<to>`, `<col>_change` (catalog-aware differencing).

## Style scheme & i18n
* `lap_tokens()`, `theme_lapidary()`, `scale_fill/colour_lapidary_c/d()`,
  `lap_accents()`, `lap_fonts()`.
* The continuous `scale_*_lapidary_c()` scales are now **binned** at pretty
  round breaks with a long, thin `guide_coloursteps()` bar
  (`lap_coloursteps_guide()`); pass `binned = FALSE` for a smooth gradient.
  Their legend title defaults to `lap_prettify_label()` of the mapped variable
  (`ind_trend_slope` -> `"Trend slope"`); `range = TRUE` (or
  `options(lapidary.scale_range = TRUE)`) appends a known indicator's
  theoretical range, e.g. `"Trend slope  (−∞, ∞)"`.
  `lap_na_guide()` adds a "no data" key for `NA` regions (e.g. empty hexes).
* `scale_fill/colour_lapidary_c(robust = TRUE)` (or a percentile spec, or
  `options(lapidary.scale_robust = TRUE)`) clips the colour limits to
  distribution-aware percentiles (default 2nd / 98th) so a few extreme values
  stop flattening the pattern for the bulk of the data. Out-of-range values take
  the end colour; on the binned default the clipped legend end is marked
  "≤" / "≥". Off by default; an explicit `limits` wins; with `midpoint` the
  limits stay symmetric about the centre.
* `ggsave_lapidary()` with web/A4–A0 presets that also fix `showtext` DPI.
* Bilingual (`en`/`de`) string registry: `lap_tr()`, `lap_lang()`,
  `lap_langs()`.

## Data
* `gems_ger_sample`, `gems_ger_wells_sample`, `germany_hex_sample`.

## Infrastructure
* `{targets}` pipeline (`_targets.R`) + `data-raw/make_sample_data.R` share the
  internal helpers in `R/sample-data.R`, so both regenerate identical
  `data/*.rda`.
* Architecture decision records under `docs/adr/`.

## Review-pass fixes (see `docs/adr/0004`–`0005`)
* `version = "latest"` now resolves to the newest built version directory in
  the generic backend (`lap_read_gwl()` / `lap_gwl_tbl()` no longer required a
  concrete version).
* `lap_disconnect()` closes the connection behind a lazy table even after
  `dplyr` verbs (reads `tbl$src$con`); the fragile attribute is gone.
* `lap_summarise_wells()` returns `NA` (not `Inf` / `NaN`) and emits no warning
  for an all-missing group.
* `lap_gw_trend()` warns when a group is larger than `warn_n` (it is O(n^2) and
  expects an annual series).
* `lap_aggregate_to_hex()` uses `dplyr` joins instead of `merge.sf`.
* `lap_normalise_gwl()` names its output `"<value>_norm"` (override with
  `into =`) and takes a tidy-select `date =` argument for `sgi`.
* Readers set `variable` at construction; the placeholder `vars` argument is
  removed from `lap_read_gwl()` / `lap_read_gems_ger()` / `lap_read_correctiv()`.
