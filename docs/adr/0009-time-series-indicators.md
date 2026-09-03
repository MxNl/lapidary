# 9. Time-series indicators: `lap_ind_*`, `ind_` columns, series-in one collector

- Status: accepted
- Date: 2026-09-01

## Context

Beyond the plain per-well statistics of `lap_summarise_wells()`, the graphics
need *derived* per-well metrics computed from the **time series**: amplitude,
the timing of the annual extremes, a long-term trend, seasonality strength,
drought frequency, ... The catalogue will grow over time and users will add
metrics to a well-level table step by step.

Two things needed deciding: how these functions are named, and how they compose
into a pipeline without every function having to be handed *both* the summary
table and the original time series.

## Decision

### Naming

- **Function family: `lap_ind_<property>()`** — a prefix, so the whole
  catalogue groups under `lap_ind_<TAB>` (same rationale as the `lap_` prefix
  itself; ADR-0008). Mirrors `feasts::feat_*()`.
- **Output columns: `ind_` prefix.** Every `lap_ind_*()` names its outputs
  `ind_<name>`; multi-output metrics share a concept stem after it
  (`ind_trend_slope` / `ind_trend_p_value`; `ind_min_month` / `ind_max_month`).
  The prefix earns its place because the indicator table is joined onto
  `gwl_wells` (static attributes) and then aggregated to hexes - after those
  joins the prefix keeps provenance obvious and enables
  `select(starts_with("ind_"))` to grab every computed metric for plotting.
- Column names carry no units; units are documented (ADR-0002), or baked in
  only where it prevents a mistake.

### The pipeline (the "elegant way")

An indicator is a **function of the time series, never of the summary**. The
summary is not a prerequisite - it is a sibling table, joined on `well_id` at
the end. So no `lap_ind_*()` is ever handed two frames.

- `lap_ind_<name>(data, value = gwl, date = date)` - pure, one series slice in,
  a one-row tibble of `ind_*` scalars out.
- `lap_indicators(x, .funs, by = well_id, value, date)` - the collector: the
  time series goes in **once**, with a set of `lap_ind_*` functions; one row
  per well comes out.
- `lap_summarise_wells(x, ..., indicators = c(lap_ind_...))` - folds the
  collector into the same call, so the common case is **one function, one data
  frame**: stats and indicators computed from the same series, returned merged.
  Only valid for a well-level grouping (indicators are one value per well).
- `lap_add_indicators(well_table, x, .funs, by = well_id)` - the only helper
  that takes both a table and the time series, for appending metrics step by
  step. It is an explicit, key-checked left join; `x` is passed once per call.
  Preserves `sf` geometry.

## Consequences

- Adding a metric = one new `lap_ind_*()` function + its definition/provenance;
  nothing else changes.
- `lap_gw_trend()` (full trend table with CIs) and `lap_ind_trend()` (trend as
  an indicator column) share the internal `theil_sen_mann_kendall()`.
- The collector materialises the series in memory (`split()` per well); a lazy
  DuckDB input is collected first, with a message.
- Alternative considered - carrying the series as a **nested list-column** on
  the well table so any function can reach it without a second argument -
  rejected as the default: heavier, does not survive a DuckDB round-trip, and
  steeper for casual use. It remains available to power users via
  `tidyr::nest()` + `purrr::map()`.
