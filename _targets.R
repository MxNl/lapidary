# lapidary analysis pipeline (maintainer-side, not part of the package API)
# ----------------------------------------------------------------------------
# A cached DAG that regenerates the packaged sample data (and any future derived
# artifacts) with one `targets::tar_make()` after a dataset update. Nothing in
# the package or in downstream (Shiny / poster) code calls this file.
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

cfg <- list(
  version = "latest",
  reference_period = list(Z1 = c(1991L, 2020L)),
  sample_n_wells = 40L,
  sample_seed = 1L,
  hex_cellsize = 25000
)

# Write data/*.rda from the sample_data list (pipeline-only helper).
write_sample_data <- function(sample_data) {
  dir.create("data", showWarnings = FALSE)
  for (nm in names(sample_data)) {
    assign(nm, sample_data[[nm]])
    save(list = nm,
      file = file.path("data", paste0(nm, ".rda")),
      compress = "bzip2", version = 2
    )
  }
  file.path("data", paste0(names(sample_data), ".rda"))
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

  # 2. Wells + a reproducible, spatially spread sample of well ids.
  tar_target(wells_sf, {
    gems_download
    lapidary::lap_read_gems_ger_wells(version = config$version, attributes = "core")
  }),
  tar_target(sample_wells, lapidary:::lap_sample_well_ids(
    wells_sf,
    n = config$sample_n_wells, seed = config$sample_seed
  )),

  # 3. Time series for the sample wells.
  tar_target(gwl_sample_raw, {
    gems_parquet
    lapidary::lap_read_gems_ger(version = config$version, wells = sample_wells)
  }),

  # 4. Packaged sample datasets (data/*.rda), built by the shared helper.
  tar_target(sample_data, lapidary:::lap_build_sample_data(
    gwl_sample_raw, wells_sf,
    hex_cellsize = config$hex_cellsize,
    reference_period = config$reference_period
  )),
  tar_target(sample_data_files, write_sample_data(sample_data), format = "file")
)
