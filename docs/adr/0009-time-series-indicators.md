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

An indicator is a **function of the time series, never of the summary**.
Per-well-year summaries (`lap_summarise_wells()`, whose job is feeding
`lap_gw_trend()` and annual plots) and per-well indicators are **deliberately
separate tables** at different aggregation levels; join them on `well_id` when
you want both. No `lap_ind_*()` is ever handed two frames.

- `lap_ind_<name>(data, value = gwl, date = "date")` - pure, one series slice
  in, a one-row tibble of `ind_*` scalars out.
- `lap_indicators(x, .funs, by = well_id, value, date)` - the collector: the
  time series goes in **once**; one row per well comes out.
- `lap_add_indicators(well_table, x, .funs, by = well_id)` - takes a well-level
  table + the time series and left-joins the indicators on, for building a
  feature table step by step. Explicit, key-checked; preserves `sf` geometry.

### Selecting indicators

`.funs` is **required** (running the whole catalogue on thousands of wells
should be a deliberate choice) and accepts:

- `"all"` - every indicator whose `in_all` flag is set, **plus** (amended, see
  below) each `in_all = FALSE` indicator whose declared inputs are present in
  the data;
- a character vector of registry **keys** (`c("amplitude", "trend")`);
- one or more `lap_ind_*` functions, or a mix of keys and functions.

`lap_indicator_registry()` (a small introspection helper, like
`lap_pal_roles()`) returns `key | columns | needs_date | in_all | description |
reference` so callers never have to memorise the `lap_ind_*` names. The
catalogue itself is the internal `indicator_catalog()` - a function returning
`list(fn, columns, needs_date, in_all, delta_kind, description, reference)` per
key; adding an indicator = one new `lap_ind_*()` + one `indicator_catalog()`
entry.

`delta_kind` (a per-output-column character vector, `"diff"` / `"circular"` /
`"none"`) tells `lap_indicator_delta()` how to difference each column between two
periods - see ADR-0010.

`reference` is a short literature citation surfaced in the registry; every
`lap_ind_*()` also carries a roxygen `@references` block, and
`vignette("indicators")` gives the long form (definition, formula,
interpretation, hydrogeological meaning) per indicator.

### Tunable arguments: `...` forwarding

`lap_indicators()` / `lap_add_indicators()` / `lap_indicator_change()` forward
`...` to every `lap_ind_*()` call (each `lap_ind_*()` ends its signature with
`...` to swallow the rest). So `threshold`, `min_len`, `driver`, `max_acc` etc.
are passable through a batch run, e.g.
`lap_indicators(sgi, "climate_signal", value = gwl_norm, driver = precip)`.

The catalogue as of this milestone: `amplitude`, `seasonal_amplitude`,
`seasonality_strength`, `recharge_discharge`, `phase_regularity`,
`extreme_months`, `flashiness`, `memory`, `rise_fall`, `trend`,
`trend_extremes`, `step_change`, `trend_acceleration`, `recession`
(master-recession e-folding time), and (opt-in, need an SGI column) `drought`
(run-theory event structure), `drought_recovery`, `climate_signal`
(climate coupling + climate-removed trend - see ADR-0011).

## Consequences

- Adding a metric = one new `lap_ind_*()` function (`R/ind-catalog.R`) + one
  `indicator_catalog()` entry.
- `lap_gw_trend()` (full trend table with CIs) and `lap_ind_trend()` (trend as
  an indicator column) share the internal `theil_sen_mann_kendall()`.
- The collector materialises the series in memory (`split()` per well); a lazy
  DuckDB input is collected first, with a message.
- Alternative considered - carrying the series as a **nested list-column** on
  the well table so any function can reach it without a second argument -
  rejected as the default: heavier, does not survive a DuckDB round-trip, and
  steeper for casual use. It remains available to power users via
  `tidyr::nest()` + `purrr::map()`.

## Amendment: `"all"` is data-aware

Originally `"all"` was exactly `in_all = TRUE`, and `drought` (later also
`drought_recovery` and `climate_signal`) was permanently unreachable through it:
the flag is static, so preparing the data made no difference. That was
surprising - `lap_join_meteo() |> lap_normalise_gwl("sgi") |>
lap_indicators("all")` still returned no drought columns - and the documented
promise ("every indicator in the registry") was untrue.

The flag could not simply be flipped, because `lap_indicators()` injects one
`value` into every indicator: under `"all"` that is `gwl`, and
`check_standardised()` would abort.

So a catalogue entry may now declare `inputs`, an `arg = requirement` list
(`"standardised"`, or a literal default column name). `"all"` resolves those
against the data: found, and the indicator runs with those columns substituted
for `value`; missing, and it is skipped with a message naming it and the reason.
`in_all` keeps its meaning - "runs unconditionally" - and stays in the registry.

Because the per-series `check_standardised()` can still reject one well over one
window even when the pooled column looks fine, an indicator that `"all"` chose
itself degrades to its `NA` row for that series (with a warning) rather than
aborting the table. Asking for it by key stays strict.

`check_standardised()` is scoped to the record the index was built from, not to
each analysis window: `lap_normalise_gwl("sgi")` guarantees median ~0 and sd ~1
over a well's *full* series, and any decade sliced out of it may legitimately sit
far from that - which is what a multi-year drought looks like. Re-applying the
guard per window therefore rejected the driest well-decades (on GEMS-GER, ~37%
of wells in 2021-2022, whose mean fraction below SGI -1 was 0.54 against 0.16 for
the wells it kept). The drought indicators take `check` so the caller can say the
index is already established; `"all"` sets it, having done that check itself.
