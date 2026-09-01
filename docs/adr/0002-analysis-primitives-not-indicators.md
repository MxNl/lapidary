# 2. Analysis layer: composable primitives, indicator catalogue deferred

- Status: accepted
- Date: 2026-09-01

## Context

`playground.R` depends on `klibiwinds` for a fixed set of KLIBIW "Kennwerte"
(`make_summary_table()`, `add_indicator_1_7/2_1/2_2/3_1/3_2`,
`add_reference_period_column()`, `lap_use_water_year()`). That package is not
publicly available, its indicator definitions are buried in NLWKN project
reports, and the project goal is *insightful, visually novel* graphics rather
than reproducing one authority's indicator set.

## Decision

`lapidary` reimplements only **composable analysis primitives**, self-contained
and tested:

- `lap_add_reference_period()` — configurable, multi-period, non-overlapping
- `lap_use_water_year()` — configurable hydrological-year start month
- `lap_summarise_wells()` — per-well(-year) min/max/mean/median/sd/n/coverage,
  pushed down to DuckDB when given a lazy tbl
- `lap_normalise_gwl()` — `range`, `zscore`, `sgi` (Standardised Groundwater Index)
- `lap_gw_trend()` — Theil-Sen slope + Mann-Kendall test (the KLIBIW trend method)
- `lap_aggregate_to_hex()` + `lap_circular_mean_month()` — spatial aggregation

There is **no `indicator_*()` catalogue** in milestone 1. A KLIBIW-style
Kennwert (month-of-extreme, recharge/discharge duration, ...) is added later
*only when a specific chart needs it*, and then documented with its definition,
formula, units and provenance.

## Consequences

- No dependency on `klibiwinds`; nothing to keep in sync.
- Freedom to design new chart types without an indicator taxonomy constraining
  them.
- When indicators do arrive they must each carry a provenance note (this ADR is
  updated or a follow-up ADR added).
- `klibiwinds` output can still be used as a cross-check in tests if an install
  becomes available.
