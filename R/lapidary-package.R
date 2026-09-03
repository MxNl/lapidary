#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom dbplyr tbl_lazy
#' @importFrom rlang .data .env %||%
## usethis namespace: end
NULL

# lapidary calls sf as `sf::` throughout, which does *not* load sf's namespace
# at package-load time. But the packaged `gwl_wells` / hex sample layers carry
# an `"sf"` class, and manipulating one (e.g. `subset(germany_hex_sample, ...)`
# then `ggplot2::geom_sf()`) needs sf's S3 methods (`[.sf`, ...) registered or
# the `sf_column` attribute is silently dropped. This import forces sf to load
# with lapidary so those methods are always available.
#' @importFrom sf st_geometry
NULL

# Bare column names used as tidy-select argument defaults (see R/utils-tidyselect.R).
utils::globalVariables(c(
  ".", "gwl", "gwl_norm", "mean_gwl", "well_id", "year", "date", "precip"
))
