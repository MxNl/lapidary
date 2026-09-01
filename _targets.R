# lapidary analysis pipeline (maintainer-side, not part of the package API)
# ----------------------------------------------------------------------------
# A cached DAG that chains lapidary's own functions so that derived data and
# the packaged sample data can be regenerated with one `targets::tar_make()`
# after a dataset update or when adding a source. Nothing in the package or in
# downstream (Shiny / poster) code calls this file.
#
# Run:   targets::tar_make()
# Graph: targets::tar_visnetwork()

library(targets)
library(tarchetypes)

# Use the installed lapidary if present, otherwise the source tree (dev).
if (!requireNamespace("lapidary", quietly = TRUE)) {
  requireNamespace("devtools")
  devtools::load_all(quiet = TRUE)
  lapidary_pkgs <- character()
} else {
  lapidary_pkgs <- "lapidary"
}

tar_option_set(
  packages = c(lapidary_pkgs, "dplyr", "sf"),
  format = "rds"
)

# --- configuration ---------------------------------------------------------
cfg <- list(
  source = "gems-ger",
  version = "latest",
  reference_period = list(Z1 = c(1991L, 2020L)),
  # A small, spatially spread well subset for the packaged sample data.
  sample_n_wells = 40L,
  hex_cellsize = 25000
)

# Helper kept here (pipeline-only, not exported).
write_sample_data <- function(gwl_sample, wells_sf, sample_wells, hex_example) {
  gems_ger_sample <- gwl_sample
  gems_ger_wells_sample <- wells_sf[wells_sf$well_id %in% sample_wells, ]
  germany_hex_sample <- hex_example
  usethis::use_data(
    gems_ger_sample, gems_ger_wells_sample, germany_hex_sample,
    overwrite = TRUE
  )
  c(
    "data/gems_ger_sample.rda",
    "data/gems_ger_wells_sample.rda",
    "data/germany_hex_sample.rda"
  )
}

list(
  tar_target(config, cfg, deployment = "main"),

  # 1. Raw data in the cache (side-effecting; tracked by the returned path).
  tar_target(
    gems_download,
    lapidary::lap_gems_ger_download(version = config$version, quiet = TRUE),
    format = "file"
  ),
  tar_target(
    gems_parquet,
    {
      gems_download
      lapidary::lap_gems_ger_build_parquet(version = config$version, meteo = FALSE)
    },
    format = "file"
  ),

  # 2. Wells + a reproducible sample of well ids.
  tar_target(wells_sf, {
    gems_download
    lapidary::lap_read_gems_ger_wells(version = config$version)
  }),
  tar_target(sample_wells, {
    withr::with_seed(
      1L,
      sample(wells_sf$well_id, min(config$sample_n_wells, nrow(wells_sf)))
    )
  }),

  # 3. Time series (full for analysis, subset for the package).
  tar_target(gwl_sample_raw, {
    gems_parquet
    lapidary::lap_read_gems_ger(version = config$version, wells = sample_wells)
  }),
  tar_target(
    gwl_sample,
    lapidary::lap_add_reference_period(
      lapidary::lap_use_water_year(gwl_sample_raw),
      periods = config$reference_period
    )
  ),

  # 4. Analysis primitives.
  tar_target(
    well_summary,
    lapidary::lap_summarise_wells(gwl_sample, by = c("well_id", "year"))
  ),
  tar_target(
    well_trend,
    lapidary::lap_gw_trend(well_summary, value = "mean_gwl", time = "year")
  ),

  # 5. Spatial example: mean level per hexagon over the sample.
  tar_target(hex_example, {
    long_term <- lapidary::lap_summarise_wells(gwl_sample, by = "well_id")
    lapidary::lap_aggregate_to_hex(
      dplyr::semi_join(wells_sf, long_term, by = "well_id"),
      values = long_term[, c("well_id", "mean_gwl")],
      cellsize = config$hex_cellsize
    )
  }),

  # 6. Write packaged sample data (data/*.rda).
  tar_target(sample_data_files, write_sample_data(
    gwl_sample, wells_sf, sample_wells, hex_example
  ), format = "file")
)
