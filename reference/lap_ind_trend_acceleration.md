# Trend acceleration

`ind_trend_accel` = Theil-Sen slope over the second half of the record
minus the slope over the first half (level units per year). Positive =
the level is rising faster / falling slower than before; negative = an
accelerating decline.

## Usage

``` r
lap_ind_trend_acceleration(
  data,
  value = gwl,
  date = "date",
  min_years = 16L,
  ...
)
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

- min_years:

  Minimum number of years; below this the outputs are `NA`.

- ...:

  Ignored; absorbs arguments forwarded to other indicators by
  [`lap_indicators()`](https://mxnl.github.io/lapidary/reference/lap_indicators.md).

## Value

A one-row tibble: `ind_trend_accel`.

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
[`lap_ind_seasonality_strength()`](https://mxnl.github.io/lapidary/reference/lap_ind_seasonality_strength.md),
[`lap_ind_step_change()`](https://mxnl.github.io/lapidary/reference/lap_ind_step_change.md),
[`lap_ind_trend()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend.md),
[`lap_ind_trend_extremes()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend_extremes.md)
