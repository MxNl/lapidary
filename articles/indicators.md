# Time-series indicators: what they mean

Each `lap_ind_*()` reduces one well’s hydrograph to a handful of
numbers.
[`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md)
runs a selection of them and returns one row per well;
[`lap_indicator_registry()`](https://mxnl.github.io/lapidary/reference/lap_indicator_registry.md)
is the index. This vignette is the long form: for every catalogue key,
what it measures, how it is computed, and what a high or low value tells
you hydrogeologically. The one-line version, the emitted columns, each
column’s theoretical range and a short citation are in the registry:

``` r

lap_indicator_registry()[, c("key", "description", "reference")]
lap_indicator_registry()[, c("key", "columns", "range")]
```

`range` is `" | "`-separated and lines up with `columns` (e.g. `drought`
emits `ind_drought_frequency` in `[0, 1]` and `ind_index_min` in
`(-Inf, Inf)`). Every section below also states its range in interval
notation — `[`/`]` closed, `(`/`)` open, `Inf` unbounded,
`{FALSE, TRUE}` for the logical flags.

All indicators take `value` / `date` as
\[tidy-select\]\[dplyr::dplyr_tidy_select\] arguments and NA-guard short
input. Extra arguments (`threshold`, `min_len`, `driver`, …) are
forwarded through
[`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md)
/
[`lap_add_indicators()`](https://mxnl.github.io/lapidary/reference/lap_add_indicators.md)
/
[`lap_indicator_change()`](https://mxnl.github.io/lapidary/reference/lap_indicator_change.md).

## A. Seasonality and phase

### `amplitude` — `ind_amplitude`

*Range `[0, Inf)`.*

`max - min` of the level over the whole slice. The crudest measure of
how much a well moves. Inflated by any long-term trend — use
`seasonal_amplitude` for the within-year signal.

### `seasonal_amplitude` — `ind_seasonal_amplitude`

*Range `[0, Inf)`.*

Mean, over calendar years, of the annual `max - min`. The typical size
of the yearly recharge–discharge swing, with the multi-decadal drift
removed. Large in shallow unconfined aquifers under a strong seasonal
recharge regime; small in deep or confined systems.

### `seasonality_strength` — `ind_seasonality_strength`

*Range `[0, 1]`.*

`max(0, 1 - var(remainder) / var(seasonal + remainder))` from an STL
decomposition (\[stats::stl()\]) of the monthly-mean series (Wang, Smith
& Hyndman 2006). 0 = no detectable annual cycle (the hydrograph is
trend- and event-dominated, typical of deep confined heads or heavily
abstracted systems); ~1 = the dynamics are almost purely an annual
cycle.

### `recharge_discharge` — `ind_recharge_months`, `ind_discharge_months`

*Ranges `ind_recharge_months` `[1, 12]`, `ind_discharge_months`
`[0, 11]` (they sum to 12).*

From the 12 climatological monthly means: the number of months from the
annual trough up to the annual peak (the mean rising limb) and its
complement to 12. A short recharge / long discharge limb is a system
that fills quickly after winter rain and then drains slowly all summer.

### `phase_regularity` — `ind_min_month_sd`

*Range `[0, Inf)` (a circular SD, in months).*

Circular standard deviation (in months, Mardia & Jupp 2000) of the month
in which each year’s minimum falls. Near 0 = a metronomic seasonal cycle
(the low always lands in the same month); large = event-driven or
irregular timing, a sign the well responds to individual storms rather
than the seasonal balance.

## B. Dynamics and aquifer signature

### `extreme_months` — `ind_min_month`, `ind_max_month`

*Range `(0.5, 12.5]` for both columns (circular months).*

Circular-mean month of the annual minimum and of the annual maximum
level
([`lap_circular_mean_month()`](https://mxnl.github.io/lapidary/reference/lap_circular_mean_month.md);
values in `(0.5, 12.5]`). Together they bracket the discharge and
recharge periods and locate the well in the annual cycle — a March
maximum is a snowmelt-fed upland well, a June maximum a lowland well
integrating spring rain.

### `flashiness` — `ind_flashiness`

*Range `[1, Inf)`.*

`sum(|diff(level)|) / (max - min)` — the total path length the series
travels per unit of its overall span (Baker et al. 2004, the
Richards–Baker index applied to heads). High for flashy shallow
unconfined systems that react to every rain event; low (near 1) for
smooth, strongly filtered deep or confined ones.

### `memory` — `ind_acf1`, `ind_memory_weeks`

*Ranges `ind_acf1` `[-1, 1]`, `ind_memory_weeks` `[1, Inf)`.*

On the month-deseasonalised series: the lag-1 autocorrelation and the
first lag at which the autocorrelation falls below `1/e`. This is the
**internal** persistence timescale — how many weeks of “memory” the
aquifer carries in its own storage. Long memory (many months) means
recharge is integrated slowly: a deep or confined system, or one with a
thick unsaturated zone. See the note on timescales below.

### `rise_fall` — `ind_rise_rate`, `ind_fall_rate`

*Ranges `ind_rise_rate`, `ind_fall_rate` both `(0, Inf)`.*

Median magnitude of the positive and of the negative step-to-step
changes. A large rise rate with a small fall rate is a system driven by
sharp recharge pulses that then drain slowly — the classic saw-tooth
karst or shallow-sand hydrograph.

## C. Long-term change

### `trend` — `ind_trend_slope`, `ind_trend_p_value`, `ind_trend_significant`

*Ranges `ind_trend_slope` `(-Inf, Inf)`, `ind_trend_p_value` `[0, 1]`,
`ind_trend_significant` `{FALSE, TRUE}`.*

Theil–Sen slope (level units per year) plus a Mann–Kendall test on the
annual-mean series. The **raw** long-term trend — it mixes the climate
signal (wet/dry decades) with any human influence.
[`lap_gw_trend()`](https://mxnl.github.io/lapidary/reference/lap_gw_trend.md)
gives the full table with confidence intervals; `climate_signal` below
separates the two drivers.

### `trend_extremes` — `ind_trend_min_slope`, `ind_trend_max_slope`

*Range `(-Inf, Inf)` for both columns.*

Theil–Sen slope of the series of annual minima and of annual maxima. If
`ind_trend_min_slope` is more negative than the mean trend, the *drought
floor* is dropping faster than the average level — low-water conditions
are deepening even if the mean looks stable.

### `step_change` — `ind_step_year`, `ind_step_magnitude`, `ind_step_p_value`

*Ranges `ind_step_year` a calendar year (no fixed range),
`ind_step_magnitude` `(-Inf, Inf)`, `ind_step_p_value` `[0, 1]`.*

Pettitt change-point (1979): the single most likely year of an abrupt
shift in the annual mean, its size (after minus before) and approximate
significance. Captures post-drought regime shifts (2003, 2018–2019 in
Central Europe) and the onset of abstraction.

### `trend_acceleration` — `ind_trend_accel`

*Range `(-Inf, Inf)`.*

Theil–Sen slope over the second half of the record minus the slope over
the first half. Negative = an accelerating decline (the recent slope is
steeper); positive = a recovering or decelerating well.

## D. Drought and low water (need a standardised index)

Add one first with `lap_normalise_gwl("sgi")` and pass
`value = gwl_norm`. The **SGI** (Standardised Groundwater Index,
Bloomfield & Marchant 2013) is a non-parametric normal-scores transform
applied per calendar month: within each month the values are ranked and
mapped through `qnorm(rank / (n + 1))`, giving a deseasonalised,
unit-variance index directly comparable across wells with very different
dynamic ranges. A **drought event** is a maximal run of
`SGI < threshold` (default `-1`), i.e. run theory (Yevjevich 1967).

### `drought` — eight columns

| column | meaning | range |
|----|----|----|
| `ind_drought_frequency` | fraction of timesteps below `threshold` | `[0, 1]` |
| `ind_frac_below_normal` | fraction of timesteps below 0 | `[0, 1]` |
| `ind_index_min` | the most negative SGI in the slice | `(-Inf, Inf)` |
| `ind_drought_n_events` | number of events | `[0, Inf)` |
| `ind_drought_duration_weeks` | mean event duration | `[1, Inf)` |
| `ind_drought_max_weeks` | longest single event | `[0, Inf)` |
| `ind_drought_severity` | mean cumulative deficit per event (`sum(-SGI)` over the run) | `(0, Inf)` |
| `ind_drought_intensity` | mean deficit per timestep (severity / duration) | `(0, Inf)` |

Applied to German heads by Ebeling et al. (2025). Duration and severity
separate wells that dip briefly but often from wells that go into long,
deep deficits.

### `drought_recovery` — `ind_drought_recovery_weeks`, `ind_drought_n_unrecovered`

*Ranges `ind_drought_recovery_weeks`, `ind_drought_n_unrecovered` both
`[0, Inf)`.*

For each event, the number of timesteps from its SGI minimum forward to
the first `SGI >= 0`: the mean of that over events that do recover, and
a count of events still unrecovered at the end of the slice. Long or
non-completing recovery is the fingerprint of a slow, storage-controlled
system — Peterson, Saft & Peel (2021) show some aquifers do not return
to their pre-drought state at all.

## E. Climate coupling and the anthropogenic imprint

### `climate_signal` — seven columns (needs an SGI column **and** a driver)

Join a co-located climate driver first with
[`lap_join_meteo()`](https://mxnl.github.io/lapidary/reference/lap_join_meteo.md)
(precipitation `HYRAS_pr`, or build P–PET yourself), then:

``` r

lap_read_gems_ger() |>
  lap_join_meteo(c(precip = "HYRAS_pr")) |>
  lap_normalise_gwl("sgi") |>
  lap_indicators("climate_signal", value = gwl_norm, driver = precip)
```

The driver is accumulated over windows of 1..`max_acc` months and
standardised per calendar month (an SPI/SPEI-analog, reusing the SGI
machinery). A grid search over accumulation and lag 0..`max_lag` finds
the maximum cross-correlation with the SGI.

| column | meaning | range |
|----|----|----|
| `ind_accum_months` | accumulation window of maximum correlation | `[1, Inf)` |
| `ind_climate_lag_months` | lag at maximum correlation | `[0, Inf)` |
| `ind_response_months` | `accum / 2 + lag` — the peak-to-peak propagation delay (Ebeling et al. 2025) | `(0, Inf)` |
| `ind_climate_cc` | that maximum correlation — how climate-driven the well is | `[-1, 1]` |
| `ind_residual_trend_slope` | Theil–Sen slope of the annual-mean residual of `lm(SGI ~ SPI_best)` | `(-Inf, Inf)` |
| `ind_residual_trend_p_value` | Mann–Kendall p-value of the residual trend | `[0, 1]` |
| `ind_residual_trend_significant` | `p < alpha` | `{FALSE, TRUE}` |

A low `ind_climate_cc` with a long `ind_response_months` is a well whose
variability precipitation cannot explain — often confined, or under
abstraction. The **residual trend** is the long-term movement left once
the best-fitting climate signal is subtracted: a significant negative
`ind_residual_trend_slope` where `ind_trend_slope` is only mildly
negative points at an anthropogenic cause (abstraction, drainage,
mining) rather than dry decades (Ebeling et al. 2025; Retike et al. 2020
use the same reference-residual idea to screen for human influence).

## F. Aquifer physics

### `recession` — `ind_recession_weeks`, `ind_recession_n_segments`

*Ranges `ind_recession_weeks` `(0, Inf)`, `ind_recession_n_segments`
`[0, Inf)`.*

Sustained falling segments (at least `min_len` steps, tolerating a
single up-step) are identified; within each, `log(level - asymptote)` is
regressed on time and the e-folding time `-1 / slope` extracted.
`ind_recession_weeks` is the median over segments,
`ind_recession_n_segments` how many contributed. This is the
**master-recession-curve** decay constant (Posavec et al. 2006; Fiorillo
2014): short for fast, well-drained unconfined systems, long (many
months) for slow, low-diffusivity or confined ones. It can lengthen
through a record as storage is depleted.

## A note on the three timescales

`memory`, `climate_signal`’s response time, and `recession` all describe
“how slow” a well is, but they are **not** the same number and should be
read together:

- **`ind_memory_weeks`** — internal autocorrelation. How long a
  perturbation persists in the well’s *own* record, driver-agnostic.
- **`ind_response_months`** — external cross-correlation lag. How long
  climate forcing takes to *reach* the well (unsaturated-zone travel +
  aquifer filtering).
- **`ind_recession_weeks`** — drainage e-folding time. How fast the well
  *empties* once recharge stops, i.e. the storage/transmissivity ratio.

A well can have long memory but a short recession (large storage, but it
drains freely once it starts), or a long response with a short memory
(deep water table, but flashy once water arrives). Divergence between
the three is informative, not a contradiction.

## `trend` vs `residual_trend`: attribution

`ind_trend_slope` is the change you see. `ind_residual_trend_slope` is
the change that remains after the best-fitting climate signal is
removed. Read as a pair:

| `ind_trend_slope` | `ind_residual_trend_slope` | interpretation |
|----|----|----|
| ↓ significant | ~0 | decline is **climate-driven** (dry decades) |
| ↓ significant | ↓ significant | decline has an **anthropogenic component** on top of climate |
| ~0 | ↓ significant | human influence is **masking** a wetter climate |
| ~0 | ~0 | stable |
