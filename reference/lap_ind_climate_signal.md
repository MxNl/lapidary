# Climate response time and the climate-removed (anthropogenic) trend

Cross-correlates the well's SGI (`value`, standardised - see
[`lap_ind_drought()`](https://mxnl.github.io/lapidary/reference/lap_ind_drought.md))
against a co-located climate `driver` (precipitation, or P - PET),
standardised as an SPI/SPEI-analog over accumulation windows. Add the
driver with
[`lap_join_meteo()`](https://mxnl.github.io/lapidary/reference/lap_join_meteo.md).

## Usage

``` r
lap_ind_climate_signal(
  data,
  value = gwl_norm,
  date = "date",
  driver = precip,
  max_acc = 48L,
  max_lag = 24L,
  alpha = 0.05,
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
  optional date column (used only to order the series).

- driver:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  the climate driver column (e.g. precipitation).

- max_acc, max_lag:

  Largest accumulation window / lag to search, in months.

- alpha:

  Significance level for `ind_residual_trend_significant`.

- ...:

  Ignored (uniform indicator signature).

## Value

A one-row tibble with the seven columns above.

## Details

- `ind_accum_months`:

  driver accumulation window of maximum correlation

- `ind_climate_lag_months`:

  lag at maximum correlation

- `ind_response_months`:

  `ind_accum_months / 2 + ind_climate_lag_months` - the "peak-to-peak"
  propagation delay (Ebeling et al. 2025)

- `ind_climate_cc`:

  that maximum cross-correlation - how climate-driven the well is

- `ind_residual_trend_slope`, `ind_residual_trend_p_value`,
  `ind_residual_trend_significant`:

  Theil-Sen slope + Mann-Kendall test on the annual-mean residual of
  `lm(SGI ~ SPI)` - the long-term change *not* explained by climate.
  Compare with `ind_trend_slope`.

## References

Ebeling, P. et al. (2025) *HESS* 29, 2925. Retike, K. et al. (2020)
*HESS* 24, 501 (residual screening for anthropogenic effects).

## See also

Other indicators:
[`lap_ind_amplitude()`](https://mxnl.github.io/lapidary/reference/lap_ind_amplitude.md),
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
[`lap_ind_trend_acceleration()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend_acceleration.md),
[`lap_ind_trend_extremes()`](https://mxnl.github.io/lapidary/reference/lap_ind_trend_extremes.md)
