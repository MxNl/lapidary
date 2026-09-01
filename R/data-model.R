# Canonical data model ---------------------------------------------------------
#
# Every groundwater dataset lapidary ingests is normalised to two shapes:
#
#   * `gwl_ts`    - a tidy long tibble, one row per well x timestamp
#   * `gwl_wells` - an sf POINT layer, one row per well
#
# Analysis and plotting code only ever sees these shapes, so a new source is
# "supported" as soon as it has a reader that returns them.

#' Required columns of a `gwl_ts` table
#' @keywords internal
gwl_ts_required <- c(
  well_id  = "character",
  date     = "Date",
  gwl      = "numeric",
  variable = "character",
  source   = "character"
)

#' Optional-but-recognised columns of a `gwl_ts` table
#' @keywords internal
gwl_ts_optional <- c(
  gwl_flag = "factor"
)

#' The `gwl_ts` groundwater time-series class
#'
#' A `gwl_ts` is a [tibble][tibble::tibble] with at least the columns
#' `well_id` (character), `date` ([Date]), `gwl` (numeric), `variable`
#' (character, naming the quantity and its units, e.g. `"gwl_m_asl"`) and
#' `source` (character). An optional `gwl_flag` factor distinguishes
#' `"observed"` from `"imputed"` values. Extra columns (for example
#' meteorological forcing variables) are carried through untouched and ignored
#' by the analysis functions.
#'
#' @param x A data frame / tibble with the required columns.
#' @param variable Default value for the `variable` column when `x` lacks one.
#' @param source Default value for the `source` column when `x` lacks one.
#'
#' @return A `gwl_ts` object (a classed tibble).
#' @aliases gwl_ts
#' @export
#' @examples
#' df <- data.frame(
#'   well_id = "MW_1",
#'   date = as.Date("1991-01-07") + 7 * (0:3),
#'   gwl = c(12.1, 12.0, 11.8, 11.9)
#' )
#' new_gwl_ts(df, variable = "gwl_m_asl", source = "example")
new_gwl_ts <- function(x, variable = "gwl_m_asl", source = NA_character_) {
  x <- tibble::as_tibble(x)
  if (is.null(x[["variable"]])) x[["variable"]] <- variable
  if (is.null(x[["source"]])) x[["source"]] <- source
  if (!is.null(x[["date"]])) x[["date"]] <- as.Date(x[["date"]])
  if (!is.null(x[["well_id"]])) x[["well_id"]] <- as.character(x[["well_id"]])
  if (!is.null(x[["gwl"]])) x[["gwl"]] <- as.numeric(x[["gwl"]])
  if (!is.null(x[["gwl_flag"]]) && !is.factor(x[["gwl_flag"]])) {
    raw_flag <- as.character(x[["gwl_flag"]])
    bad <- setdiff(stats::na.omit(unique(raw_flag)), c("observed", "imputed"))
    if (length(bad)) {
      cli::cli_abort(c(
        "{.field gwl_flag} has unexpected value{?s} {.val {bad}}.",
        i = "Allowed: {.val observed} / {.val imputed} (or {.val NA})."
      ))
    }
    x[["gwl_flag"]] <- factor(raw_flag, levels = c("observed", "imputed"))
  }
  # Put the canonical columns first for readability.
  front <- intersect(
    c(names(gwl_ts_required), names(gwl_ts_optional)), names(x)
  )
  x <- x[, c(front, setdiff(names(x), front)), drop = FALSE]
  class(x) <- unique(c("gwl_ts", class(x)))
  validate_gwl_ts(x)
}

#' Validate a `gwl_ts` table
#'
#' @param x Object to validate.
#' @return `x`, invisibly, if valid; otherwise an error is thrown.
#' @export
validate_gwl_ts <- function(x) {
  check_gwl_ts(x)
  invisible(x)
}

#' Check that an object satisfies the `gwl_ts` contract
#'
#' Unlike [validate_gwl_ts()] this always inspects the object even if it is not
#' classed as `gwl_ts`, which makes it useful inside readers.
#'
#' @param x Object to check.
#' @param arg Argument name to use in error messages.
#' @param call Calling environment for error messages.
#'
#' @return `TRUE`, invisibly, on success; otherwise a classed error.
#' @export
check_gwl_ts <- function(x, arg = rlang::caller_arg(x),
                         call = rlang::caller_env()) {
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg {arg}} must be a data frame, not {.obj_type_friendly {x}}.",
      call = call
    )
  }
  missing <- setdiff(names(gwl_ts_required), names(x))
  if (length(missing)) {
    cli::cli_abort(c(
      "{.arg {arg}} is missing required column{?s} {.field {missing}}.",
      i = "A {.cls gwl_ts} needs {.field {names(gwl_ts_required)}}."
    ), call = call)
  }
  problems <- character()
  for (col in names(gwl_ts_required)) {
    ok <- switch(gwl_ts_required[[col]],
      character = is.character(x[[col]]),
      numeric = is.numeric(x[[col]]),
      Date = inherits(x[[col]], "Date")
    )
    if (!ok) {
      problems <- c(problems, sprintf(
        "%s must be %s", col, gwl_ts_required[[col]]
      ))
    }
  }
  if (!is.null(x[["gwl_flag"]]) &&
    !all(stats::na.omit(as.character(x[["gwl_flag"]])) %in%
      c("observed", "imputed"))) {
    problems <- c(problems, "gwl_flag values must be 'observed' or 'imputed'")
  }
  if (length(problems)) {
    cli::cli_abort(c(
      "{.arg {arg}} has invalid columns:",
      stats::setNames(problems, rep("x", length(problems)))
    ), call = call)
  }
  invisible(TRUE)
}

#' Coerce to `gwl_ts`
#'
#' @param x An object to coerce.
#' @param ... Passed to methods.
#' @return A `gwl_ts`.
#' @export
as_gwl_ts <- function(x, ...) {
  UseMethod("as_gwl_ts")
}

#' @export
as_gwl_ts.gwl_ts <- function(x, ...) {
  validate_gwl_ts(x)
}

#' @export
as_gwl_ts.data.frame <- function(x, variable = "gwl_m_asl",
                                 source = NA_character_, ...) {
  new_gwl_ts(x, variable = variable, source = source)
}

#' @importFrom tibble as_tibble
#' @exportS3Method tibble::as_tibble
as_tibble.gwl_ts <- function(x, ...) {
  class(x) <- setdiff(class(x), "gwl_ts")
  NextMethod()
}

#' @export
print.gwl_ts <- function(x, ...) {
  n_wells <- length(unique(x[["well_id"]]))
  rng <- if (nrow(x)) range(x[["date"]], na.rm = TRUE) else c(NA, NA)
  vars <- unique(stats::na.omit(x[["variable"]]))
  src <- unique(stats::na.omit(x[["source"]]))
  header <- sprintf(
    "<gwl_ts> %s rows | %s well%s | %s .. %s",
    format(nrow(x), big.mark = ","), n_wells, if (n_wells == 1) "" else "s",
    format(rng[1]), format(rng[2])
  )
  meta <- sprintf(
    "variable: %s%s", toString(vars),
    if (length(src)) paste0(" | source: ", toString(src)) else ""
  )
  cat(header, "\n", meta, "\n", sep = "")
  print(tibble::as_tibble(x), ...)
  invisible(x)
}

# gwl_wells -------------------------------------------------------------------

#' Required columns / properties of a `gwl_wells` layer
#' @keywords internal
gwl_wells_crs <- 25832L

#' Build a `gwl_wells` well-metadata layer
#'
#' @param x An `sf` POINT object, or a data frame plus `coords`.
#' @param coords When `x` is a plain data frame, a length-2 character vector of
#'   the x/y coordinate columns.
#' @param crs Coordinate reference system of the incoming coordinates. The
#'   result is transformed to EPSG:25832 (ETRS89 / UTM 32N).
#'
#' @return A `gwl_wells` object (a classed `sf` tibble) in EPSG:25832.
#' @aliases gwl_wells
#' @export
new_gwl_wells <- function(x, coords = c("x", "y"), crs = gwl_wells_crs) {
  if (!inherits(x, "sf")) {
    x <- sf::st_as_sf(tibble::as_tibble(x), coords = coords, crs = crs)
  }
  if (is.na(sf::st_crs(x))) {
    sf::st_crs(x) <- crs
  }
  x <- sf::st_transform(x, gwl_wells_crs)
  if (is.null(x[["well_id"]])) {
    cli::cli_abort("A {.cls gwl_wells} layer needs a {.field well_id} column.")
  }
  x[["well_id"]] <- as.character(x[["well_id"]])
  class(x) <- unique(c("gwl_wells", class(x)))
  x
}

#' Check that an object satisfies the `gwl_wells` contract
#'
#' @inheritParams check_gwl_ts
#' @return `TRUE` invisibly on success.
#' @export
check_gwl_wells <- function(x, arg = rlang::caller_arg(x),
                            call = rlang::caller_env()) {
  if (!inherits(x, "sf")) {
    cli::cli_abort("{.arg {arg}} must be an {.cls sf} object.", call = call)
  }
  if (is.null(x[["well_id"]])) {
    cli::cli_abort("{.arg {arg}} is missing the {.field well_id} column.",
      call = call
    )
  }
  geom_type <- as.character(unique(sf::st_geometry_type(x)))
  if (!all(geom_type %in% c("POINT", "MULTIPOINT"))) {
    cli::cli_abort(
      "{.arg {arg}} must be POINT geometry, not {.val {geom_type}}.",
      call = call
    )
  }
  invisible(TRUE)
}
