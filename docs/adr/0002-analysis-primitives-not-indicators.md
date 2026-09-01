# 2. Analysis layer: composable primitives, indicator catalogue deferred

- Status: accepted
- Date: 2026-09-01

## Context

`playground.R` leaned on an external package for a fixed set of pre-defined
groundwater "indicators" (summary tables, month-of-extreme, recharge/discharge
timing, ...). That package is not publicly available, the exact definitions of
those indicators are not readily documented, and the project goal is
*insightful, visually novel* graphics rather than reproducing one particular
indicator set.

## Decision

`lapidary` implements only **composable analysis primitives**, self-contained
and tested:

- `lap_add_reference_period()` — configurable, multi-period, non-overlapping
- `lap_use_water_year()` — configurable hydrological-year start month
- `lap_summarise_wells()` — per-well(-year) min/max/mean/median/sd/n/coverage,
  pushed down to DuckDB when given a lazy tbl
- `lap_normalise_gwl()` — `range`, `zscore`, `sgi` (Standardised Groundwater Index)
- `lap_gw_trend()` — Theil-Sen slope + Mann-Kendall test
- `lap_aggregate_to_hex()` + `lap_circular_mean_month()` — spatial aggregation

There is **no `indicator_*()` catalogue** in milestone 1. A derived indicator
(month-of-extreme, recharge/discharge duration, ...) is added later *only when a
specific chart needs it*, and then documented with its definition, formula,
units and source.

## Consequences

- No dependency on an external indicator package; nothing to keep in sync.
- Freedom to design new chart types without an indicator taxonomy constraining
  them.
- When indicators do arrive they must each carry a provenance note (this ADR is
  updated or a follow-up ADR added).
