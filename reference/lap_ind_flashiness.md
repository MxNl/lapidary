# Flashiness of the hydrograph

`ind_flashiness` = `sum(|diff(level)|) / (max - min)` - the total path
length the series travels, per unit of its overall span. High for flashy
shallow unconfined systems, low for smooth deep / confined ones.

## Usage

``` r
lap_ind_flashiness(data, value = gwl, date = "date", ...)
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

- ...:

  Ignored; absorbs arguments forwarded to other indicators by
  [`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md).

## Value

A one-row tibble: `ind_flashiness`.

## See also

Other indicators:
[`lap_ind_amplitude()`](https://mxnl.github.io/lapidary/reference/lap_ind_amplitude.md),
[`lap_ind_climate_signal()`](https://mxnl.github.io/lapidary/reference/lap_ind_climate_signal.md),
[`lap_ind_drought()`](https://mxnl.github.io/lapidary/reference/lap_ind_drought.md),
[`lap_ind_drought_recovery()`](https://mxnl.github.io/lapidary/reference/lap_ind_drought_recovery.md),
[`lap_ind_extreme_months()`](https://mxnl.github.io/lapidary/reference/lap_ind_extreme_months.md),
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
