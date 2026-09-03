#' Administrative border of Germany
#'
#' A cached [sf] polygon of Germany from `rnaturalearth`, projected to
#' EPSG:25832. The result is memoised for the session.
#'
#' @param scale Map scale passed to [rnaturalearth::ne_countries()]:
#'   `"small"`, `"medium"` or `"large"`.
#'
#' @return An `sf` object with a single (MULTI)POLYGON feature.
#' @export
#' @examples
#' \dontrun{
#' lap_germany_border()
#' }
lap_germany_border <- function(scale = c("medium", "small", "large")) {
  scale <- rlang::arg_match(scale)
  key <- paste0("germany_border_", scale)
  cached <- the$spatial[[key]]
  if (!is.null(cached)) {
    return(cached)
  }
  rlang::check_installed("rnaturalearth", "for `lap_germany_border()`")
  border <- rnaturalearth::ne_countries(
    country = "Germany", scale = scale, returnclass = "sf"
  )
  border <- sf::st_transform(border, gwl_wells_crs)
  the$spatial[[key]] <- border
  border
}

# Session-level cache environment.
the <- new.env(parent = emptyenv())
the$spatial <- list()

#' Build a hexagonal grid covering a region
#'
#' @param region An `sf` polygon (e.g. [lap_germany_border()]) or any `sf` object
#'   whose bounding box / union defines the extent.
#' @param cellsize Hexagon size in CRS units (metres for EPSG:25832).
#'   Default `25000`.
#' @param clip If `TRUE`, keep only hexagons intersecting `region`.
#'
#' @return An `sf` polygon layer with a `hex_id` column.
#' @export
lap_make_hex_grid <- function(region, cellsize = 25000, clip = TRUE) {
  if (!inherits(region, "sf") && !inherits(region, "sfc")) {
    cli::cli_abort("{.arg region} must be an {.cls sf} / {.cls sfc} object.")
  }
  region <- sf::st_transform(sf::st_as_sf(region), gwl_wells_crs)
  grid <- sf::st_make_grid(region, cellsize = cellsize, square = FALSE)
  grid <- sf::st_sf(geometry = grid)
  if (clip) {
    hits <- lengths(sf::st_intersects(grid, sf::st_union(region))) > 0
    grid <- grid[hits, , drop = FALSE]
  }
  grid[["hex_id"]] <- seq_len(nrow(grid))
  grid[, c("hex_id", "geometry")]
}

#' Circular mean of a month-of-year value
#'
#' Averaging "month of annual minimum" naively is wrong (December and January
#' are one month apart, not eleven). This maps months onto the unit circle,
#' averages, and maps back to the `[1, 12]` range.
#'
#' @param month Numeric vector of months (may be fractional, 1-12).
#' @param na.rm Drop `NA`s before averaging.
#'
#' @return A single numeric month in `(0, 12]`.
#' @export
#' @examples
#' lap_circular_mean_month(c(12, 1, 2))
lap_circular_mean_month <- function(month, na.rm = TRUE) {
  if (na.rm) month <- month[!is.na(month)]
  if (!length(month)) {
    return(NA_real_)
  }
  ang <- (month - 1) / 12 * 2 * pi
  mean_ang <- atan2(mean(sin(ang)), mean(cos(ang)))
  m <- (mean_ang / (2 * pi) * 12) %% 12 + 1 # in [1, 13)
  if (m > 12.5) m <- m - 12 # keep the result in (0.5, 12.5]
  m
}

# Signed month difference b - a, wrapped to (-6, 6]: "b is this many months
# later than a" (negative = earlier). Vectorised.
circular_month_diff <- function(a, b) {
  d <- (b - a) %% 12
  ifelse(d > 6, d - 12, d)
}

# Circular standard deviation of months, expressed in months (0 = perfectly
# regular, up to ~3.4 for a uniform spread).
circular_month_sd <- function(month, na.rm = TRUE) {
  if (na.rm) month <- month[!is.na(month)]
  if (length(month) < 2) {
    return(NA_real_)
  }
  ang <- (month - 1) / 12 * 2 * pi
  r <- sqrt(mean(cos(ang))^2 + mean(sin(ang))^2)
  if (r <= 0) {
    return(NA_real_)
  }
  sqrt(-2 * log(r)) / (2 * pi) * 12
}
