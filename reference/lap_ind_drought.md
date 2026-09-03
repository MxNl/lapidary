# Drought characterisation from a standardised index

Expects `value` to be an approximately standard-normal index such as the
SGI (add one with
[`lap_normalise_gwl()`](https://mxnl.github.io/lapidary/reference/lap_normalise_gwl.md)
`method = "sgi"` and pass `value = gwl_norm`). Errors if the column does
not look standardised. A **drought event** is a maximal run of
`value < threshold` (run theory, Yevjevich 1967).

## Usage

``` r
lap_ind_drought(data, value = gwl_norm, date = "date", threshold = -1, ...)
```

## Arguments

- data:

  A one-series data frame.

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  level column.

- date:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  optional date column (used only to order the series).

- threshold:

  Drought threshold on the index. Default `-1`.

- ...:

  Ignored (uniform indicator signature).

## Value

A one-row tibble with the columns above.

## Details

- `ind_drought_frequency`:

  fraction of timesteps below `threshold`

- `ind_frac_below_normal`:

  fraction of timesteps below 0

- `ind_index_min`:

  the most negative value in the slice

- `ind_drought_n_events`:

  number of drought events

- `ind_drought_duration_weeks`:

  mean event duration (timesteps)

- `ind_drought_max_weeks`:

  longest single event

- `ind_drought_severity`:

  mean cumulative deficit per event (sum of `-value` over the event)

- `ind_drought_intensity`:

  mean deficit per timestep (severity / duration)

## References

Bloomfield, J.P. & Marchant, B.P. (2013) *HESS* 17, 4769. Yevjevich, V.
(1967) *Hydrol. Pap.* 23, Colorado State Univ. Ebeling, P. et al. (2025)
*HESS* 29, 2925.

## See also

Other indicators:
[`lap_ind_amplitude()`](https://mxnl.github.io/lapidary/reference/lap_ind_amplitude.md),
[`lap_ind_climate_signal()`](https://mxnl.github.io/lapidary/reference/lap_ind_climate_signal.md),
[`lap_ind_drought_recovery()`](https://mxnl.github.io/lapidary/reference/lap_ind_drought_recovery.md),
[`lap_ind_extreme_months()`](https://mxnl.github.io/lapidary/reference/lap_ind_extreme_months.md),
[`lap_ind_flashiness()`](https://mxnl.github.io/lapidary/reference/lap_ind_flashiness.md),
[`lap_ind_memory()`](https://mxnl.github.io/lapidary/reference/lap_ind_memory.md),
[`lap_ind_phase_regularity()`](https://mxnl.github.io/lapidary/reference/lap_ind_phase_regularity.md),
[`lap_ind_recession()`](https://mxnl.github.io/lapidary/reference/lap_ind_recession.md),
[`lap_ind_recharge_discharge()`](https://mxnl.github.io/lapidary/reference/lap_ind_recharge_discharge.md),
[`lap_ind_rise_fall()`](https://mxnl.github.io/lapidary/reference/lap_ind_rise_fall.md),
[`lap_ind_seasonal_amplitude()`](https://mxnl.github.io/lapidary/reference/lap_ind_seasonal_amplitude.md),
[`lap_ind_seasonality_strength()`](https://mxnl.github.io/lapidary/reference/lap_ind_seasonality_strength.md),
[`lap_ind_step_change()`](https://mxnl.github.io/lapidary/reference/lap_ind_step_change.md),
[`lap_ind_trend()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend.md),
[`lap_ind_trend_acceleration()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend_acceleration.md),
[`lap_ind_trend_extremes()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend_extremes.md)
