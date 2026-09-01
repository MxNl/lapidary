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
* Parquet-artifact / DuckDB-engine backend: `lap_gwl_tbl()` (lazy), `lap_read_gwl()`,
  `lap_write_gwl_parquet()`, `lap_csvs_to_parquet()`; `arrow` is optional.
* GEMS-GER reader: `lap_gems_ger_download()`, `lap_gems_ger_build_parquet()`,
  `lap_read_gems_ger()`, `lap_read_gems_ger_wells()`, `lap_gems_ger_meta()`.
* CORRECTIV reader as a second source: `lap_correctiv_download()`,
  `lap_correctiv_build_parquet()`, `lap_read_correctiv()`, `lap_read_correctiv_wells()`.
* Cache helpers: `lap_cache_dir()`, `lap_cache_info()`.

## Analysis primitives
* `lap_add_reference_period()`, `lap_reference_periods()`, `lap_use_water_year()`.
* `lap_summarise_wells()` (in-memory or pushed down to DuckDB; `indicators=`
  argument), `lap_wells_with_coverage()`.
* `lap_normalise_gwl()` — `range`, `zscore`, `sgi`.
* `lap_gw_trend()` — Theil–Sen slope + Mann–Kendall test.
* `lap_make_hex_grid()`, `lap_aggregate_to_hex()`, `lap_circular_mean_month()`,
  `lap_germany_border()`.

## Time-series indicators (see `docs/adr/0009`)
* `lap_indicators()` collector + `lap_add_indicators()` for step-by-step
  appending; `ind_`-prefixed output columns.
* `lap_ind_amplitude()`, `lap_ind_extreme_months()`, `lap_ind_trend()`.

## Style scheme & i18n
* `lap_tokens()`, `theme_lapidary()`, `scale_fill/colour_lapidary_c/d()`,
  `lap_accents()`, `lap_fonts()`.
* `ggsave_lapidary()` with web/A4–A0 presets that also fix `showtext` DPI.
* Bilingual (`en`/`de`) string registry: `lap_tr()`, `lap_lang()`,
  `lap_langs()`.

## Data
* `gems_ger_sample`, `gems_ger_wells_sample`, `germany_hex_sample`.

## Infrastructure
* `{targets}` pipeline (`_targets.R`) to regenerate derived / sample data.
* Architecture decision records under `docs/adr/`.
