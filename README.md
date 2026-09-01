# lapidary

<!-- badges: start -->
<!-- badges: end -->

**lapidary** turns German groundwater-level time series into insightful,
poster- and web-ready graphics. It owns the *data wrangling, analysis and the
shared ggplot2 style scheme*; downstream packages (a Shiny website, a poster
builder) consume it.

The first dataset is [GEMS-GER](https://doi.org/10.5281/zenodo.15530171)
(3,207 wells, gapless weekly levels 1991–2022). The data model is
source-agnostic, so updated GEMS releases and other series (CORRECTIV, BGR,
state authorities) plug in through their own readers.

> Status: **milestone 1 — data + analysis foundation.** Plot builders and
> `patchwork` poster composition come in milestone 2. See `docs/adr/` for the
> design decisions and `NEWS.md` for what exists today.

## Conventions

* The core API is `lap_`-prefixed (`lap_read_gems_ger()`, `lap_summarise_wells()`, …).
* ggplot2 extension points keep the ecosystem convention: `theme_lapidary()`,
  `scale_fill_lapidary_c()`, `ggsave_lapidary()`.
* Column arguments use tidy evaluation — bare names, strings, or tidyselect
  helpers all work (`by = c(well_id, year)`, `by = "well_id"`, `by = all_of(x)`).

## Installation

```r
# install.packages("pak")
pak::pak("mxnl/lapidary")
```

DuckDB does the heavy lifting; `arrow` is optional.

## Quick start

```r
library(lapidary)

# One-time: download (~290 MB) and convert to a Parquet cache
lap_gems_ger_download()
lap_gems_ger_build_parquet(meteo = FALSE)

# Read a canonical `gwl_ts`
gwl <- lap_read_gems_ger(wells = c("MW_1", "MW_42"))

# Analysis primitives
gwl |>
  lap_use_water_year() |>
  lap_add_reference_period(periods = list(Z1 = c(1991, 2020))) |>
  lap_summarise_wells(by = c(well_id, year)) |>
  lap_gw_trend(value = mean_gwl, time = year)

# Spatial aggregation
wells <- lap_read_gems_ger_wells()
long_term <- lap_summarise_wells(gwl, by = well_id)
hex <- lap_aggregate_to_hex(wells, values = long_term[, c("well_id", "mean_gwl")])
```

Nothing above needs the download: `data(gems_ger_sample)` and
`data(germany_hex_sample)` ship a small subset.

## Style scheme

```r
library(ggplot2)
lap_fonts()

ggplot(germany_hex_sample) +
  geom_sf(aes(fill = mean_gwl), colour = NA) +
  scale_fill_lapidary_c("magnitude") +
  theme_lapidary(variant = "light") +
  labs(title = lap_tr("app_title", "en"))

# render at a size preset (also fixes showtext DPI)
ggsave_lapidary(last_plot(), "map.png", preset = "a2")
```

Set `options(lapidary.lang = "de")` for German labels.

## Regenerating derived data

```r
targets::tar_make()          # _targets.R at the repo root (maintainer-side)
```
