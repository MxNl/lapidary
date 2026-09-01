#' GEMS-GER sample groundwater time series
#'
#' A small, spatially spread subset of the GEMS-GER dataset for examples,
#' tests and vignettes: weekly groundwater levels (m above sea level) for
#' ~40 monitoring wells, 1991-2022, already passed through [lap_use_water_year()]
#' and [lap_add_reference_period()].
#'
#' @format A [gwl_ts] tibble with columns `well_id`, `date`, `gwl`, `variable`,
#'   `source`, `gwl_flag`, `water_year`, `water_month`, `reference_period`.
#' @source GEMS-GER, Wunsch, Liesch & Broda (2026), doi:10.5281/zenodo.15530171,
#'   licence CC-BY-NC-ND 4.0. See [lap_gems_ger_meta()].
"gems_ger_sample"

#' GEMS-GER sample well metadata
#'
#' Well locations and static attributes for the wells in [gems_ger_sample].
#'
#' @format A [gwl_wells] `sf` layer (EPSG:25832) with `well_id` and curated
#'   static attributes (`surface_elevation`, `well_depth`, `aquifer_medium`,
#'   `pressure_state`, ...).
#' @source As [gems_ger_sample].
"gems_ger_wells_sample"

#' Example hexagon aggregation over Germany
#'
#' Mean and standard deviation of groundwater level per 25 km hexagon,
#' aggregated from [gems_ger_wells_sample]. For demonstrating the map builders;
#' the sparse well sample means most hexagons are empty.
#'
#' @format An `sf` polygon layer with `hex_id`, `n_wells`, `mean_gwl`, `sd_gwl`.
#' @source Derived from [gems_ger_sample] via [lap_aggregate_to_hex()].
"germany_hex_sample"
