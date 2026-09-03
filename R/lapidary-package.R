#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom dbplyr tbl_lazy
#' @importFrom rlang .data .env %||%
## usethis namespace: end
NULL

# Bare column names used as tidy-select argument defaults (see R/utils-tidyselect.R).
utils::globalVariables(c(
  ".", "gwl", "gwl_norm", "mean_gwl", "well_id", "year", "date", "precip"
))
