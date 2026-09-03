# DuckDB query engine over Parquet artifacts ---------------------------------
#
# lapidary keeps its canonical cached data as Parquet files and uses DuckDB as
# the query engine. DuckDB reads and writes Parquet natively, so `arrow` is not
# required (it is only an optional accelerator for `collect()`).

#' Open a DuckDB connection
#'
#' @param dbdir Database file, or `":memory:"` (default).
#' @param read_only Open read-only.
#'
#' @return A DBI connection (see [DBI::dbConnect()]). Close it with
#'   [lap_disconnect()].
#' @export
lap_duckdb_con <- function(dbdir = ":memory:", read_only = FALSE) {
  rlang::check_installed(c("DBI", "duckdb"), "for the DuckDB query engine")
  DBI::dbConnect(duckdb::duckdb(), dbdir = dbdir, read_only = read_only)
}

#' Close a DuckDB connection
#'
#' Accepts a connection, or a lazy `dplyr` table backed by one (including the
#' result of [dplyr::filter()] etc. applied to a [lap_gwl_tbl()]). Idempotent.
#'
#' @param x A DBI connection or a lazy `tbl`.
#' @return `NULL`, invisibly.
#' @export
lap_disconnect <- function(x) {
  con <- if (inherits(x, "DBIConnection")) {
    x
  } else if (inherits(x, "tbl_sql")) {
    # survives dplyr verbs, unlike a plain attribute
    tryCatch(x$src$con, error = function(e) NULL)
  } else {
    NULL
  }
  if (inherits(con, "DBIConnection") && DBI::dbIsValid(con)) {
    DBI::dbDisconnect(con, shutdown = TRUE)
  }
  invisible(NULL)
}

#' Directory holding a source's Parquet artifacts
#'
#' @param source Source key (e.g. `"gems-ger"`).
#' @param version Version string, or `"latest"` (resolved to the newest built
#'   version directory unless `create = TRUE`).
#' @param create Create the directory. When `TRUE`, `"latest"` is *not*
#'   resolved (there may be nothing to resolve yet) - pass a concrete version.
#'
#' @return A path string.
#' @export
lap_parquet_dir <- function(source, version = "latest", create = FALSE) {
  if (!create) version <- resolve_parquet_version(source, version)
  lap_cache_source_dir(source, "parquet", version, create = create)
}

# Resolve `"latest"` to the newest version directory that actually holds a
# built Parquet dataset for `source`. A concrete version is returned as-is.
resolve_parquet_version <- function(source, version = "latest",
                                    call = rlang::caller_env()) {
  if (!identical(version, "latest")) {
    return(version)
  }
  root <- lap_cache_source_dir(source, "parquet")
  versions <- if (dir.exists(root)) {
    basename(list.dirs(root, recursive = FALSE))
  } else {
    character()
  }
  versions <- versions[file.exists(file.path(root, versions, "gwl.parquet"))]
  if (!length(versions)) {
    cli::cli_abort(c(
      "No built Parquet dataset for source {.val {source}}.",
      i = "Build it first (e.g. {.run lapidary::lap_gems_ger_build_parquet()})."
    ), call = call)
  }
  ord <- tryCatch(
    order(numeric_version(versions), decreasing = TRUE),
    error = function(e) order(versions, decreasing = TRUE)
  )
  versions[ord][[1]]
}

#' Lazy table over a source's groundwater Parquet dataset
#'
#' Returns a lazy `dplyr` table (backed by DuckDB) over the core groundwater
#' Parquet file for `source`. Filtering and aggregation on the result are
#' pushed down to DuckDB; call [dplyr::collect()] to materialise, or use
#' [lap_read_gwl()] which returns a validated `gwl_ts`.
#'
#' @param source Source key. Default `"gems-ger"`.
#' @param version Version string, or `"latest"` (the newest built version).
#' @param which One of `"gwl"` (core levels) or `"meteo"` (forcing variables).
#' @param con Optional existing DuckDB connection. If `NULL` a fresh in-memory
#'   connection is opened; close it afterwards with [lap_disconnect()] (which
#'   also accepts the result of `dplyr` verbs applied to this table). For a
#'   long-running app, open one connection yourself and pass it here. See also
#'   [lap_gwl_query()] for one-shot lazy pipelines.
#'
#' @return A lazy `tbl`.
#' @export
lap_gwl_tbl <- function(source = "gems-ger",
                    version = "latest",
                    which = c("gwl", "meteo"),
                    con = NULL) {
  which <- rlang::arg_match(which)
  path <- file.path(lap_parquet_dir(source, version), paste0(which, ".parquet"))
  if (!file.exists(path)) {
    cli::cli_abort(c(
      "No {.file {which}.parquet} for source {.val {source}}.",
      i = "Expected {.path {path}}.",
      i = "Build it first, e.g. with {.run lapidary::lap_gems_ger_build_parquet()}."
    ))
  }
  if (is.null(con)) con <- lap_duckdb_con()
  dplyr::tbl(con, dplyr::sql(sprintf("SELECT * FROM read_parquet(%s)", dbq(path))))
}

#' Run a lazy query against a source and collect the result
#'
#' Opens a DuckDB connection (or uses `con`), hands the lazy [lap_gwl_tbl()] to
#' `fn`, collects the result, and closes the connection if it opened one. This
#' is the safe way to do a lazy filter/aggregate without managing the
#' connection lifetime yourself.
#'
#' @param fn A function (or `\(tbl) ...` / `~ ...` formula) taking the lazy
#'   table and returning a lazy or eager result.
#' @inheritParams lap_gwl_tbl
#'
#' @return A tibble (the collected result).
#' @export
#' @examples
#' \dontrun{
#' lap_gwl_query("gems-ger", fn = \(t) dplyr::filter(t, well_id == "MW_1"))
#' }
lap_gwl_query <- function(fn, source = "gems-ger", version = "latest",
                          which = c("gwl", "meteo"), con = NULL) {
  fn <- rlang::as_function(fn)
  own_con <- is.null(con)
  if (own_con) con <- lap_duckdb_con()
  if (own_con) on.exit(lap_disconnect(con), add = TRUE)
  tb <- lap_gwl_tbl(source = source, version = version, which = which, con = con)
  res <- fn(tb)
  if (inherits(res, "tbl_lazy")) res <- dplyr::collect(res)
  tibble::as_tibble(res)
}

#' Read a validated groundwater time series from the Parquet cache
#'
#' Convenience wrapper around [lap_gwl_tbl()] that applies optional filters, pulls
#' the data into memory and returns a [new_gwl_ts()].
#'
#' @param source Source key. Default `"gems-ger"`.
#' @param version Version string, or `"latest"` (the newest built version).
#' @param wells Optional character vector of `well_id`s to keep.
#' @param date_range Optional length-2 `Date` (or coercible) vector.
#' @param variable Value passed to [new_gwl_ts()] for the `variable` column
#'   (names the quantity + units, e.g. `"gwl_m_asl"`).
#'
#' @return A `gwl_ts`.
#' @export
lap_read_gwl <- function(source = "gems-ger",
                     version = "latest",
                     wells = NULL,
                     date_range = NULL,
                     variable = "gwl_m_asl") {
  tb <- lap_gwl_tbl(source = source, version = version)
  on.exit(lap_disconnect(tb), add = TRUE)
  if (!is.null(wells)) {
    wells <- as.character(wells)
    tb <- dplyr::filter(tb, .data$well_id %in% .env$wells)
  }
  if (!is.null(date_range)) {
    date_range <- format(as.Date(date_range))
    lo <- date_range[[1]]
    hi <- date_range[[2]]
    tb <- dplyr::filter(tb, .data$date >= !!lo, .data$date <= !!hi)
  }
  df <- dplyr::collect(tb)
  df[["date"]] <- as.Date(df[["date"]])
  df <- dplyr::arrange(df, .data$well_id, .data$date)
  new_gwl_ts(df, variable = variable, source = source)
}

#' Write a groundwater data frame to the Parquet cache
#'
#' Uses DuckDB `COPY ... TO` so no `arrow` install is needed.
#'
#' @param x A data frame (long, with at least `well_id`, `date`, `gwl`).
#' @param source Source key.
#' @param version Concrete version string (not `"latest"`).
#' @param which `"gwl"` or `"meteo"`.
#' @param overwrite Overwrite an existing file.
#'
#' @return The Parquet file path, invisibly.
#' @export
lap_write_gwl_parquet <- function(x, source, version = "1.0",
                              which = c("gwl", "meteo"), overwrite = FALSE) {
  which <- rlang::arg_match(which)
  if (identical(version, "latest")) {
    cli::cli_abort("{.arg version} must be a concrete version string, not {.val latest}.")
  }
  out_dir <- lap_parquet_dir(source, version, create = TRUE)
  path <- file.path(out_dir, paste0(which, ".parquet"))
  if (file.exists(path) && !overwrite) {
    cli::cli_abort("{.path {path}} exists; pass {.code overwrite = TRUE}.")
  }
  con <- lap_duckdb_con()
  on.exit(lap_disconnect(con), add = TRUE)
  duckdb::duckdb_register(con, "x_in", tibble::as_tibble(x))
  DBI::dbExecute(con, sprintf(
    "COPY (SELECT * FROM x_in) TO %s (FORMAT PARQUET, COMPRESSION ZSTD)", dbq(path)
  ))
  invisible(path)
}

#' Convert a directory of per-well CSV files into one Parquet file
#'
#' DuckDB globs and unions the CSVs in a single query. Column selection and
#' renaming are handled by `select_sql` (a SQL `SELECT` list).
#'
#' @param csv_glob Glob pattern matching the CSV files.
#' @param out_path Output Parquet file.
#' @param select_sql SQL select-list mapping source columns to the canonical
#'   schema, e.g. `"filename AS src, GWL AS gwl"`.
#' @param filename Whether to expose the source path as a `filename` column
#'   (needed when the well id is encoded in the file name).
#' @param overwrite Overwrite an existing output.
#'
#' @return `out_path`, invisibly.
#' @export
lap_csvs_to_parquet <- function(csv_glob, out_path, select_sql = "*",
                            filename = TRUE, overwrite = FALSE) {
  if (file.exists(out_path) && !overwrite) {
    cli::cli_abort("{.path {out_path}} exists; pass {.code overwrite = TRUE}.")
  }
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  con <- lap_duckdb_con()
  on.exit(lap_disconnect(con), add = TRUE)
  read_expr <- sprintf(
    "read_csv_auto(%s, union_by_name = true, filename = %s)",
    dbq(csv_glob), if (filename) "true" else "false"
  )
  DBI::dbExecute(con, sprintf(
    "COPY (SELECT %s FROM %s) TO %s (FORMAT PARQUET, COMPRESSION ZSTD)",
    select_sql, read_expr, dbq(out_path)
  ))
  invisible(out_path)
}

# SQL single-quote a string literal.
dbq <- function(x) {
  paste0("'", gsub("'", "''", x, fixed = TRUE), "'")
}

#' Column names DuckDB assigns to a read expression
#'
#' Useful because `read_csv_auto()` names an unnamed leading column
#' `column0` / `column00` / ... depending on the total column count.
#'
#' @param read_expr A SQL table expression (e.g. a `read_csv_auto(...)` call).
#' @param con Optional connection.
#' @return A character vector of column names.
#' @keywords internal
lap_duckdb_columns <- function(read_expr, con = NULL) {
  own <- is.null(con)
  if (own) con <- lap_duckdb_con()
  if (own) on.exit(lap_disconnect(con), add = TRUE)
  DBI::dbGetQuery(con, sprintf("DESCRIBE SELECT * FROM %s LIMIT 0", read_expr))$column_name
}
