# Regenerate the packaged sample datasets.
#
# Normally driven by the {targets} pipeline (`targets::tar_make()`); this script
# is the standalone equivalent for a quick refresh. Requires the GEMS-GER cache
# to be populated:
#   lapidary::lap_gems_ger_download()
#   lapidary::lap_gems_ger_build_parquet(meteo = FALSE)

devtools::load_all(".", quiet = TRUE)
library(dplyr)
library(sf)

n_wells <- 40L
reference_period <- list(Z1 = c(1991L, 2020L))

wells <- lap_read_gems_ger_wells(attributes = "core")

# A spatially spread sample: bin wells onto a coarse grid, take one per cell.
set.seed(1)
grid <- lap_make_hex_grid(lap_germany_border(), cellsize = 90000)
binned <- st_join(wells, grid, join = st_intersects) |>
  st_drop_geometry() |>
  filter(!is.na(hex_id)) |>
  group_by(hex_id) |>
  slice_sample(n = 1) |>
  ungroup()
sample_wells <- sort(sample(binned$well_id, min(n_wells, nrow(binned))))

gwl <- lap_read_gems_ger(wells = sample_wells) |>
  lap_use_water_year() |>
  lap_add_reference_period(periods = reference_period)

gems_ger_sample <- gwl
gems_ger_wells_sample <- wells[wells$well_id %in% sample_wells, ]

long_term <- lap_summarise_wells(gwl, by = "well_id")
germany_hex_sample <- lap_aggregate_to_hex(
  gems_ger_wells_sample,
  values = long_term[, c("well_id", "mean_gwl", "sd_gwl")],
  cellsize = 25000
)

usethis::use_data(
  gems_ger_sample, gems_ger_wells_sample, germany_hex_sample,
  overwrite = TRUE
)
