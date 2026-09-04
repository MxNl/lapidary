#' Aggregate per-well values onto a hexagonal grid
#'
#' Spatially joins well points to a hex grid and summarises one or more value
#' columns per hexagon. Regular numeric columns are averaged (mean); columns
#' named in `circular` are averaged with [lap_circular_mean_month()]; a well count
#' `n_wells` is always added.
#'
#' Pass `by` to aggregate *within groups* - e.g. feed the long output of
#' [lap_indicator_change()] with `by = period` to get one row per hexagon and
#' period (without `by`, the repeated `well_id`s would collapse the periods).
#'
#' @param wells A `gwl_wells` layer (or any `sf` POINT layer with `well_id`).
#' @param values A data frame keyed by `well_id` holding the columns to
#'   aggregate, or `NULL` to use numeric columns already on `wells`.
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> value columns to
#'   aggregate (bare names, strings, helpers). Default: all numeric columns of
#'   `values` (or `wells`), minus any `by` columns.
#' @param circular <[`tidy-select`][dplyr::dplyr_tidy_select]> subset of `cols`
#'   to average circularly (months). Default: none.
#' @param by <[`tidy-select`][dplyr::dplyr_tidy_select]> grouping column(s) in
#'   `values` (or `wells`) - the aggregation runs per hexagon *and* group, and
#'   the output has one row per combination. Default: none. A grouping column's
#'   type (e.g. the ordered `period` factor) is preserved.
#' @param complete When `by` is set, keep every hexagon in *every* observed
#'   group (with `NA` values / `n_wells = 0` where that hexagon had no wells in
#'   that group), so a facetted map draws the full grid in each panel. `TRUE`
#'   by default; set `FALSE` to keep only the hexagon-group combinations that
#'   actually have wells. No effect without `by`.
#' @param grid A hex grid from [lap_make_hex_grid()]. If `NULL`, one is built from
#'   `region`.
#' @param region Passed to [lap_make_hex_grid()] when `grid` is `NULL`. Defaults to
#'   [lap_germany_border()].
#' @param cellsize Passed to [lap_make_hex_grid()].
#'
#' @return An `sf` polygon layer: the grid plus one column per aggregated value,
#'   any `by` column(s), and `n_wells`. Without `by`, hexagons with no wells
#'   keep `NA` values. With `by` and the default `complete = TRUE`, every
#'   hexagon appears once per observed group (`NA` values / `n_wells = 0`
#'   where that hexagon-group combination has no wells) - ready to facet by
#'   `by` with the full grid in every panel; with `complete = FALSE` a
#'   hexagon with no wells in *any* group instead keeps a single row with `NA`
#'   in the `by` column(s).
#' @export
lap_aggregate_to_hex <- function(wells,
                             values = NULL,
                             cols = NULL,
                             circular = NULL,
                             by = NULL,
                             complete = TRUE,
                             grid = NULL,
                             region = NULL,
                             cellsize = 25000) {
  cols_quo <- rlang::enquo(cols)
  circular_quo <- rlang::enquo(circular)
  by_quo <- rlang::enquo(by)
  check_gwl_wells(wells)
  wells <- sf::st_transform(wells, gwl_wells_crs)

  if (!is.null(values)) {
    values <- tibble::as_tibble(values)
    if (!"well_id" %in% names(values)) {
      cli::cli_abort("{.arg values} must have a {.field well_id} column.")
    }
    values[["well_id"]] <- as.character(values[["well_id"]])
    # inner join: wells absent from `values` are dropped from the aggregation
    wells <- sf::st_as_sf(dplyr::inner_join(
      wells["well_id"], values,
      by = "well_id"
    ))
  }

  flat <- sf::st_drop_geometry(wells)
  by_nm <- if (rlang::quo_is_null(by_quo)) {
    character()
  } else {
    lap_eval_select(flat, by_quo, arg = "by")
  }

  numeric_cols <- names(which(vapply(flat, is.numeric, logical(1))))
  cols <- if (rlang::quo_is_null(cols_quo)) {
    numeric_cols
  } else {
    lap_eval_select(flat, cols_quo, arg = "cols")
  }
  cols <- setdiff(intersect(cols, numeric_cols), by_nm)
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

  grp <- interaction(joined[c("hex_id", by_nm)], drop = TRUE, lex.order = TRUE)
  parts <- split(joined, grp, drop = TRUE)
  agg <- dplyr::bind_rows(lapply(parts, function(part) {
    row <- c(
      list(hex_id = part[["hex_id"]][[1]]),
      as.list(part[1, by_nm, drop = FALSE]),
      list(n_wells = nrow(part))
    )
    for (col in cols) {
      row[[col]] <- if (col %in% circular) {
        lap_circular_mean_month(part[[col]])
      } else {
        mean(part[[col]], na.rm = TRUE)
      }
    }
    tibble::as_tibble(row)
  }))

  if (length(by_nm) && isTRUE(complete) && nrow(agg)) {
    # scaffold: every hexagon x every observed group combination, so a
    # facetted map has the full grid (grey "no data" hexes included) in
    # every panel, not just where a hexagon happened to have wells.
    combos <- unique(agg[by_nm])
    combos <- combos[do.call(order, unname(as.list(combos))), , drop = FALSE]
    hex_ids <- grid[["hex_id"]]
    n <- nrow(combos)
    scaffold <- tibble::as_tibble(c(
      list(hex_id = rep(hex_ids, each = n)),
      lapply(combos, function(col) col[rep(seq_len(n), times = length(hex_ids))])
    ))
    out <- dplyr::left_join(scaffold, agg, by = c("hex_id", by_nm))
  } else {
    out <- dplyr::left_join(sf::st_drop_geometry(grid), agg, by = "hex_id")
  }
  out[["n_wells"]][is.na(out[["n_wells"]])] <- 0L
  geom <- sf::st_geometry(grid)[match(out[["hex_id"]], grid[["hex_id"]])]
  sf::st_sf(out, geometry = geom)
}
