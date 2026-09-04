# 11. Climate coupling and the climate-removed (anthropogenic) trend

- Status: accepted
- Date: 2026-09-03

## Context

The headline question - how has Germany's groundwater developed over decades -
splits into two parts a plain `trend` indicator (ADR-0009) cannot separate:

1. **Climate.** How strongly, and with what delay, does a well track its local
   meteorological forcing? A shallow, well-connected system responds within
   weeks; a deep or confined one integrates years of forcing. GEMS-GER ships 15
   co-located forcing columns per well (`HYRAS_pr` precipitation, `DWD_evapo_*`
   PET, ...), so this is measurable per well.
2. **Everything else.** Once the climate-driven variation is removed, a residual
   long-term trend points at abstraction, drainage, land-use or mine dewatering
   - an *anthropogenic imprint* (Ebeling et al. 2025, *HESS* 29:2925; Retike et
   al. 2020, *HESS* 24:501).

## Decision

### A separate reader step for the driver: `lap_join_meteo()`

The climate driver is **not** a `vars=` argument on `lap_read_gems_ger()` (that
argument was removed in the review pass - readers set `variable` at
construction; ADR-0005 consequences). Instead `lap_join_meteo(x, vars, version)`
reads the requested forcing columns from `meteo.parquet` and left-joins them
onto a GEMS-GER `gwl_ts` by `well_id` + `date`. `vars` accepts `"all"` or a
character vector of `gems_ger_meteo_cols` names, optionally **named** for
renaming (`c(precip = "HYRAS_pr")`). The result is still a `gwl_ts`; the joined
columns are ordinary extra columns that the indicator layer points `driver` at.

Rationale: keeps the reader single-purpose, keeps the join explicit and
inspectable, and means the (large) meteo artifact is only touched when a climate
indicator is actually wanted.

### One catalogue key: `climate_signal`

A single `lap_ind_climate_signal(data, value, date, driver, max_acc, max_lag,
alpha, ...)` does one `climate_coupling()` computation and emits seven columns:

| column | meaning |
|---|---|
| `ind_accum_months` | driver accumulation window of maximum correlation |
| `ind_climate_lag_months` | lag (months) at maximum correlation |
| `ind_response_months` | `accum / 2 + lag` - the "peak-to-peak" propagation delay (Ebeling et al. 2025) |
| `ind_climate_cc` | that maximum cross-correlation - how climate-driven the well is |
| `ind_residual_trend_slope` | Theil-Sen slope of the annual-mean residual of `lm(SGI ~ SPI_best)` |
| `ind_residual_trend_p_value` | Mann-Kendall p-value of that residual trend |
| `ind_residual_trend_significant` | `p < alpha` |

The driver is standardised the same way SGI is (ADR: `lap_normalise_gwl("sgi")`
machinery - accumulate over `acc` months, then per-calendar-month
`normal_scores()`), giving an SPI/SPEI-analog. `value` must already be a
standardised index (guarded by `check_standardised()`), so the pipeline is
`lap_join_meteo()` -> `lap_normalise_gwl("sgi")` -> `lap_indicators("climate_signal",
value = gwl_norm, driver = ...)`.

`in_all = FALSE` (needs both an SGI column and a joined driver). It declares
those as `inputs = list(value = "standardised", driver = "precip")`, so
`.funs = "all"` runs it once the data actually has them - see the amendment to
ADR 0009. `delta_kind` is
`"diff"` for the four coupling columns and the residual slope, `"none"` for the
residual p-value / significance flag.

### De-duplication against the existing catalogue

- `drought_events` from the original plan is **folded into** the enriched
  `drought` key: one `drought_runs()` pass over runs of `SGI < threshold` now
  yields frequency, `n_events`, mean duration, max duration, mean severity
  (cumulative deficit) and intensity. `drought_recovery` is a second key on the
  same runs (recovery time from each event's minimum back to `SGI >= 0`).
- `memory`, `climate_signal`'s response time, and `recession` all proxy an
  "aquifer timescale" but from genuinely different angles - internal
  autocorrelation, external cross-correlation lag, and recession-curve e-folding
  respectively - so all three stay, documented as complementary in
  `vignette("indicators")`.
- `ind_trend_slope` (raw) vs `ind_residual_trend_slope` (climate-removed) is
  exactly the climate-vs-anthropogenic split; both stay.

## Consequences

- `lap_ind_climate_signal()` needs a non-standard argument (`driver`); this is
  what motivated the `...` forwarding in the collector (ADR-0009).
- Over multiple periods (`lap_indicator_change()`), the driver column must be
  joined **before** slicing, because `lap_join_meteo()` acts on a `gwl_ts`, not
  on a period slice.
- `meteo.parquet` is not part of the packaged sample data; the climate indicator
  is exercised in tests against a small fixture cache.
- The cross-correlation grid search is O(`max_acc` x `max_lag`) per well on a
  monthly series - cheap, but not free on thousands of wells; it is opt-in.
