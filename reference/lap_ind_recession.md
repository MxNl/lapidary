# Master-recession-curve e-folding time

Identifies sustained recession segments (falling / flat runs of at least
`min_len` steps, tolerating a single up-step), fits
`log(level - asymptote)` against time per segment and reports the median
e-folding time. Short for fast, unconfined systems; long (many months)
for slow, confined ones. Can lengthen as storage is depleted.

## Usage

``` r
lap_ind_recession(data, value = gwl, date = "date", min_len = 8L, ...)
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

- min_len:

  Minimum recession-segment length, in timesteps.

- ...:

  Ignored; absorbs arguments forwarded to other indicators by
  [`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md).

## Value

A one-row tibble with the two columns above.

## Details

- `ind_recession_weeks`:

  median segment e-folding time

- `ind_recession_n_segments`:

  number of segments that contributed

## References

Posavec, K. et al. (2017) *Groundwater* 55, 891 (master recession
curve). Fiorillo, F. (2014) *Water Resour. Manag.* 28, 1919.

## See also

Other indicators:
[`lap_ind_amplitude()`](https://mxnl.github.io/lapidary/reference/lap_ind_amplitude.md),
[`lap_ind_climate_signal()`](https://mxnl.github.io/lapidary/reference/lap_ind_climate_signal.md),
[`lap_ind_drought()`](https://mxnl.github.io/lapidary/reference/lap_ind_drought.md),
[`lap_ind_drought_recovery()`](https://mxnl.github.io/lapidary/reference/lap_ind_drought_recovery.md),
[`lap_ind_extreme_months()`](https://mxnl.github.io/lapidary/reference/lap_ind_extreme_months.md),
[`lap_ind_flashiness()`](https://mxnl.github.io/lapidary/reference/lap_ind_flashiness.md),
[`lap_ind_memory()`](https://mxnl.github.io/lapidary/reference/lap_ind_memory.md),
[`lap_ind_phase_regularity()`](https://mxnl.github.io/lapidary/reference/lap_ind_phase_regularity.md),
[`lap_ind_recharge_discharge()`](https://mxnl.github.io/lapidary/reference/lap_ind_recharge_discharge.md),
[`lap_ind_rise_fall()`](https://mxnl.github.io/lapidary/reference/lap_ind_rise_fall.md),
[`lap_ind_seasonal_amplitude()`](https://mxnl.github.io/lapidary/reference/lap_ind_seasonal_amplitude.md),
[`lap_ind_seasonality_strength()`](https://mxnl.github.io/lapidary/reference/lap_ind_seasonality_strength.md),
[`lap_ind_step_change()`](https://mxnl.github.io/lapidary/reference/lap_ind_step_change.md),
[`lap_ind_trend()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend.md),
[`lap_ind_trend_acceleration()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend_acceleration.md),
[`lap_ind_trend_extremes()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend_extremes.md)
