# Join GEMS-GER meteorological forcings onto a groundwater series

Reads the requested forcing columns from `meteo.parquet` (build it with
[`lap_gems_ger_build_parquet()`](https://mxnl.github.io/lapidary/reference/lap_gems_ger_build_parquet.md)
`meteo = TRUE`) and left-joins them onto a GEMS-GER `gwl_ts` by
`well_id` and `date`. The result is still a `gwl_ts`; the joined columns
are what
[`lap_ind_climate_signal()`](https://mxnl.github.io/lapidary/reference/lap_ind_climate_signal.md)
needs as its `driver`.

## Usage

``` r
lap_join_meteo(x, vars = "all", version = "latest")
```

## Arguments

- x:

  A `gwl_ts` from
  [`lap_read_gems_ger()`](https://mxnl.github.io/lapidary/reference/lap_read_gems_ger.md)
  (its `source` must be `"gems-ger"`).

- vars:

  Forcing columns to join. Either `"all"`, or a character vector of
  names from `gems_ger_meteo_cols` (`HYRAS_pr`, `DWD_evapo_p`, ...),
  optionally **named** to rename on join, e.g.
  `c(precip = "HYRAS_pr", pet = "DWD_evapo_p")`.

- version:

  Version key or `"latest"`.

## Value

`x` with the forcing columns added (a `gwl_ts`).

## See also

[`lap_ind_climate_signal()`](https://mxnl.github.io/lapidary/reference/lap_ind_climate_signal.md),
[`lap_gems_ger_build_parquet()`](https://mxnl.github.io/lapidary/reference/lap_gems_ger_build_parquet.md)

## Examples

``` r
if (FALSE) { # \dontrun{
lap_read_gems_ger() |>
  lap_join_meteo(c(precip = "HYRAS_pr")) |>
  lap_normalise_gwl("sgi") |>
  lap_indicators("climate_signal", value = gwl_norm, driver = precip)
} # }
```
