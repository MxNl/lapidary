# Regenerate the packaged sample datasets (data/*.rda).
#
# The canonical route is the {targets} pipeline:
#   targets::tar_make()
# This script is the standalone equivalent - it calls the *same* internal
# helpers (R/sample-data.R), so both produce identical output. Requires the
# GEMS-GER cache to be populated:
#   lapidary::lap_gems_ger_download()
#   lapidary::lap_gems_ger_build_parquet(meteo = FALSE)

devtools::load_all(".", quiet = TRUE)

cfg <- list(
  reference_period = list(Z1 = c(1991L, 2020L)),
  sample_n_wells = 40L,
  sample_seed = 1L,
  hex_cellsize = 25000
)

wells <- lap_read_gems_ger_wells(attributes = "core")
sample_wells <- lap_sample_well_ids(wells, n = cfg$sample_n_wells, seed = cfg$sample_seed)
gwl_raw <- lap_read_gems_ger(wells = sample_wells)

sample_data <- lap_build_sample_data(
  gwl_raw, wells,
  hex_cellsize = cfg$hex_cellsize,
  reference_period = cfg$reference_period
)

# Same save as the {targets} pipeline, so the two routes match byte-for-byte.
dir.create("data", showWarnings = FALSE)
for (nm in names(sample_data)) {
  assign(nm, sample_data[[nm]])
  save(list = nm,
    file = file.path("data", paste0(nm, ".rda")),
    compress = "bzip2", version = 2
  )
}
