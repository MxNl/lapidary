# 10. Indicators over multiple periods: `lap_indicator_change()` + `lap_indicator_delta()`

- Status: accepted
- Date: 2026-09-03

## Context

The project's headline question is how Germany's groundwater resources have
developed *over decades*. That means computing the same indicator over different
time windows - the whole record, a climate reference period, a recent period -
and looking at the change. The windows the user actually wants overlap (whole
record vs recent decade), which `lap_add_reference_period()` forbids by design
(a non-overlapping factor label).

`lap_indicators(x, .funs, by = c(well_id, reference_period))` already works when
the periods *don't* overlap (`reference_period` is just another grouping
column). What was missing: overlapping windows, and a tidy way to get the
change.

## Decision

Two new functions, both reusing `resolve_ind_funs()` / `indicator_catalog()` so
`.funs` selection is identical to `lap_indicators()`:

### `lap_indicator_change(x, .funs, periods, by = well_id, value, date)`
- `periods` is a **named** list of `c(start_year, end_year)`; **overlap
  allowed** (`validate_periods(allow_overlap = TRUE)`).
- Slices `x` to each period (`slice_years()`), runs `lap_indicators()` on the
  slice, stacks the results with a `period` column.
- Returns **long**: `<by> | period (ordered factor) | ind_*`. Long because
  `period` is then just another dimension - it plots straight into a slope chart
  faceted by indicator, or an arrow map after a join to `gwl_wells`.

### `lap_indicator_delta(change, from, to, by = well_id)`
- Pivots the long output to **one row per well**: `<col>_<from>`, `<col>_<to>`,
  and `<col>_change` for each `ind_*` column.
- `<col>_change` is computed per the catalogue's **`delta_kind`** for that
  column:
  - `"diff"` (default) - `to - from`
  - `"circular"` - signed month difference in `(-6, 6]` (`circular_month_diff()`),
    for the month-of-extreme columns
  - `"none"` - no change column (p-values, `ind_step_year`)

## Consequences

- `lap_indicators()` is unchanged - `lap_indicator_change()` calls it per slice.
- The non-overlapping tidy alternative still stands and is documented:
  `lap_add_reference_period() |> lap_indicators(by = c(well_id, reference_period))`.
- Cost scales with `n_periods`; on the full dataset (~3,200 wells) a
  three-period `"all"` run is minutes, acceptable for an analysis step.
- Indicators computed on a short slice (e.g. a 12-year "recent" window) return
  `NA` where their `min_years` guard isn't met - correct, not silent.
- SGI-based `drought` over periods: pre-compute the index on the full record
  (`lap_normalise_gwl("sgi")`), pass `value = gwl_norm`; the slice then inherits
  the full-record calibration.
