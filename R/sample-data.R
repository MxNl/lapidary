# Regenerating the packaged sample datasets ---------------------------------
#
# Maintainer-only helpers, not exported. `_targets.R` and
# `data-raw/make_sample_data.R` both call these (via `lapidary:::`) so the two
# routes produce identical `data/*.rda`. They deliberately set the global RNG
# seed - that is what data-generation scripts do.

# A spatially spread sample of well ids: bin wells onto a coarse hex grid, take
# one well per non-empty cell, then trim to `n`.
lap_sample_well_ids <- function(wells, n = 40L, seed = 1L, bin_cellsize = 90000) {
  set.seed(seed)
  grid <- lap_make_hex_grid(lap_germany_border(), cellsize = bin_cellsize)
  binned <- sf::st_drop_geometry(sf::st_join(wells, grid, join = sf::st_intersects))
  binned <- binned[!is.na(binned$hex_id), , drop = FALSE]
  per_cell <- vapply(
    split(as.character(binned$well_id), binned$hex_id),
    function(ids) ids[[sample.int(length(ids), 1L)]],
    character(1)
  )
  sort(sample(per_cell, min(n, length(per_cell))))
}

# Build the three packaged datasets from a time series + well layer.
lap_build_sample_data <- function(gwl_ts, wells, hex_cellsize = 25000,
                                  reference_period = list(Z1 = c(1991L, 2020L))) {
  gwl <- gwl_ts |>
    lap_use_water_year() |>
    lap_add_reference_period(periods = reference_period)
  ids <- unique(gwl$well_id)
  wells_sub <- wells[wells$well_id %in% ids, ]
  long_term <- lap_summarise_wells(gwl, by = "well_id")
  hex <- lap_aggregate_to_hex(
    wells_sub,
    values = long_term[, c("well_id", "mean_gwl", "sd_gwl")],
    cellsize = hex_cellsize
  )
  list(
    gems_ger_sample = gwl,
    gems_ger_wells_sample = mark_crs_utf8(wells_sub),
    germany_hex_sample = mark_crs_utf8(hex)
  )
}

# The CRS WKT that sf stores carries a degree sign in its area-of-use text;
# mark it UTF-8 so a packaged sf object is a NOTE, not a WARNING, in R CMD check.
mark_crs_utf8 <- function(x) {
  g <- attr(x, "sf_column")
  cr <- attr(x[[g]], "crs")
  if (!is.null(cr$wkt)) {
    cr$wkt <- enc2utf8(cr$wkt)
    Encoding(cr$wkt) <- "UTF-8"
    attr(x[[g]], "crs") <- cr
  }
  x
}
