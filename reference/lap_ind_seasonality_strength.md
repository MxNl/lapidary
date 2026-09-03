# Strength of the seasonal cycle

`ind_seasonality_strength` in `[0, 1]`:
`max(0, 1 - var(remainder) / var(seasonal + remainder))` from an STL
decomposition ([`stats::stl()`](https://rdrr.io/r/stats/stl.html)) of
the series aggregated to monthly means. 0 = no seasonal signal (typical
of deep confined systems), ~1 = the dynamics are almost purely seasonal.

## Usage

``` r
lap_ind_seasonality_strength(data, value = gwl, date = "date", ...)
```

## Arguments

- data:

  A one-series data frame.

- value:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  level column.

- date:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  date column.

- ...:

  Ignored; absorbs arguments forwarded to other indicators by
  [`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md).

## Value

A one-row tibble: `ind_seasonality_strength`.

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
[`lap_ind_recession()`](https://mxnl.github.io/lapidary/reference/lap_ind_recession.md),
[`lap_ind_recharge_discharge()`](https://mxnl.github.io/lapidary/reference/lap_ind_recharge_discharge.md),
[`lap_ind_rise_fall()`](https://mxnl.github.io/lapidary/reference/lap_ind_rise_fall.md),
[`lap_ind_seasonal_amplitude()`](https://mxnl.github.io/lapidary/reference/lap_ind_seasonal_amplitude.md),
[`lap_ind_step_change()`](https://mxnl.github.io/lapidary/reference/lap_ind_step_change.md),
[`lap_ind_trend()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend.md),
[`lap_ind_trend_acceleration()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend_acceleration.md),
[`lap_ind_trend_extremes()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend_extremes.md)
