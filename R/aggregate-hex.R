#' Aggregate per-well values onto a hexagonal grid
#'
#' Spatially joins well points to a hex grid and summarises one or more value
#' columns per hexagon. Regular numeric columns are averaged (mean); columns
#' named in `circular` are averaged with [lap_circular_mean_month()]; a well count
#' `n_wells` is always added.
#'
#' @param wells A `gwl_wells` layer (or any `sf` POINT layer with `well_id`).
#' @param values A data frame keyed by `well_id` holding the columns to
#'   aggregate, or `NULL` to use numeric columns already on `wells`.
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> value columns to
#'   aggregate (bare names, strings, helpers). Default: all numeric columns of
#'   `values` (or `wells`).
#' @param circular <[`tidy-select`][dplyr::dplyr_tidy_select]> subset of `cols`
#'   to average circularly (months). Default: none.
#' @param grid A hex grid from [lap_make_hex_grid()]. If `NULL`, one is built from
#'   `region`.
#' @param region Passed to [lap_make_hex_grid()] when `grid` is `NULL`. Defaults to
#'   [lap_germany_border()].
#' @param cellsize Passed to [lap_make_hex_grid()].
#'
#' @return An `sf` polygon layer: the grid plus one column per aggregated value
#'   and `n_wells`. Hexagons with no wells keep `NA` values.
#' @export
lap_aggregate_to_hex <- function(wells,
                             values = NULL,
                             cols = NULL,
                             circular = NULL,
                             grid = NULL,
                             region = NULL,
                             cellsize = 25000) {
  cols_quo <- rlang::enquo(cols)
  circular_quo <- rlang::enquo(circular)
  check_gwl_wells(wells)
  wells <- sf::st_transform(wells, gwl_wells_crs)

  if (!is.null(values)) {
    values <- tibble::as_tibble(values)
    if (!"well_id" %in% names(values)) {
      cli::cli_abort("{.arg values} must have a {.field well_id} column.")
    }
    values[["well_id"]] <- as.character(values[["well_id"]])
    wells <- merge(
      wells[, "well_id"], values,
      by = "well_id", all.x = FALSE
    )
  }

  flat <- sf::st_drop_geometry(wells)
  numeric_cols <- names(which(vapply(flat, is.numeric, logical(1))))
  cols <- if (rlang::quo_is_null(cols_quo)) {
    numeric_cols
  } else {
    lap_eval_select(flat, cols_quo, arg = "cols")
  }
  cols <- intersect(cols, numeric_cols)
  if (!length(cols)) {
    cli::cli_abort("No numeric value columns to aggregate.")
  }
  circular <- if (rlang::quo_is_null(circular_quo)) {
    character()
  } else {
    lap_eval_select(flat, circular_quo, arg = "circular")
  }
  bad_circular <- setdiff(circular, cols)
  if (length(bad_circular)) {
    cli::cli_warn("Ignoring {.field {bad_circular}} in {.arg circular}: not among aggregated columns.")
  }

  if (is.null(grid)) {
    if (is.null(region)) region <- lap_germany_border()
    grid <- lap_make_hex_grid(region, cellsize = cellsize)
  }

  joined <- sf::st_join(wells, grid, join = sf::st_intersects)
  joined <- sf::st_drop_geometry(joined)
  joined <- joined[!is.na(joined[["hex_id"]]), , drop = FALSE]

  parts <- split(joined, joined[["hex_id"]])
  agg <- lapply(parts, function(part) {
    row <- list(hex_id = part[["hex_id"]][[1]], n_wells = nrow(part))
    for (col in cols) {
      row[[col]] <- if (col %in% circular) {
        lap_circular_mean_month(part[[col]])
      } else {
        mean(part[[col]], na.rm = TRUE)
      }
    }
    as.data.frame(row, stringsAsFactors = FALSE)
  })
  agg <- do.call(rbind, agg)

  out <- merge(grid, agg, by = "hex_id", all.x = TRUE)
  out[["n_wells"]][is.na(out[["n_wells"]])] <- 0L
  out
}
