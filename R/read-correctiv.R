# CORRECTIV reader --------------------------------------------------------------
#
# A second concrete source, to keep the ingest abstraction honest. CORRECTIV.Lokal
# compiled monthly groundwater statistics per monitoring well from the German
# state authorities:
#   https://github.com/correctiv/grundwasser-data
#     monthly/<state>_monthly.csv : ms_nr, year, month, min_gwl, mean_gwl, max_gwl
#     messstellen.csv             : ms_nr, bundesland, ..., latitude, longitude, ...
#
# Note: CORRECTIV levels are monthly aggregates and their datum convention is
# not always documented per state, so `variable` is the generic "gwl_m".

correctiv_base_url <- "https://raw.githubusercontent.com/correctiv/grundwasser-data/main"
correctiv_states <- c(
  "bw", "by", "be", "bb", "hb", "hh", "he", "mv",
  "ni", "nw", "rp", "sl", "sn", "st", "sh", "th"
)

#' CORRECTIV groundwater dataset metadata
#' @return A list with `source`, `licence`, `citation`, `url`, `crs`, `variable`.
#' @export
lap_correctiv_meta <- function() {
  list(
    source = "correctiv",
    licence = "see repository (CORRECTIV.Lokal)",
    citation = "CORRECTIV.Lokal, grundwasser-data (github.com/correctiv/grundwasser-data)",
    url = "https://github.com/correctiv/grundwasser-data",
    crs = 4326L,
    variable = "gwl_m"
  )
}

#' Download the CORRECTIV groundwater CSVs
#'
#' @param dir Cache root. Defaults to [lap_cache_dir()].
#' @param overwrite Force re-download.
#' @param quiet Suppress progress output.
#'
#' @return The directory holding the downloaded CSVs, invisibly.
#' @export
lap_correctiv_download <- function(dir = lap_cache_dir(),
                               overwrite = FALSE, quiet = FALSE) {
  dest <- file.path(dir, "sources", "correctiv", "download")
  dir.create(file.path(dest, "monthly"), recursive = TRUE, showWarnings = FALSE)
  lap_download_cached(
    file.path(correctiv_base_url, "messstellen.csv"),
    file.path(dest, "messstellen.csv"),
    overwrite = overwrite, quiet = quiet
  )
  for (st in correctiv_states) {
    lap_download_cached(
      sprintf("%s/monthly/%s_monthly.csv", correctiv_base_url, st),
      file.path(dest, "monthly", sprintf("%s_monthly.csv", st)),
      overwrite = overwrite, quiet = quiet
    )
  }
  invisible(dest)
}

#' Build the CORRECTIV Parquet artifact
#'
#' @param overwrite Overwrite an existing Parquet file.
#' @param value Which monthly statistic becomes `gwl`: `"mean"` (default),
#'   `"min"` or `"max"`. The other two are kept as extra columns.
#'
#' @return The Parquet path, invisibly.
#' @export
lap_correctiv_build_parquet <- function(overwrite = FALSE,
                                    value = c("mean", "min", "max")) {
  value <- rlang::arg_match(value)
  dl <- file.path(lap_cache_dir(), "sources", "correctiv", "download")
  if (!dir.exists(dl)) lap_correctiv_download()
  glob <- file.path(dl, "monthly", "*_monthly.csv")
  out <- file.path(lap_parquet_dir("correctiv", "1.0", create = TRUE), "gwl.parquet")

  lap_csvs_to_parquet(
    glob, out,
    select_sql = sprintf(
      "ms_nr AS well_id,
       make_date(CAST(year AS INTEGER), CAST(month AS INTEGER), 15) AS date,
       %s_gwl AS gwl, 'observed' AS gwl_flag,
       min_gwl, mean_gwl, max_gwl",
      value
    ),
    filename = FALSE,
    overwrite = overwrite
  )
  invisible(out)
}

#' Read CORRECTIV groundwater levels as a `gwl_ts`
#'
#' @inheritParams lap_read_gwl
#' @return A `gwl_ts` (`source` = `"correctiv"`).
#' @export
lap_read_correctiv <- function(wells = NULL, date_range = NULL, vars = "gwl") {
  out <- lap_read_gwl(
    source = "correctiv", version = "1.0",
    wells = wells, date_range = date_range, vars = vars
  )
  out[["variable"]] <- lap_correctiv_meta()$variable
  out
}

#' Read CORRECTIV well metadata as a `gwl_wells` layer
#'
#' @return A `gwl_wells` `sf` layer in EPSG:25832.
#' @export
lap_read_correctiv_wells <- function() {
  csv <- file.path(
    lap_cache_dir(), "sources", "correctiv", "download", "messstellen.csv"
  )
  if (!file.exists(csv)) lap_correctiv_download()
  df <- utils::read.csv(csv)
  df <- df[stats::complete.cases(df[, c("longitude", "latitude")]), , drop = FALSE]
  df[["well_id"]] <- as.character(df[["ms_nr"]])
  keep <- intersect(
    c("well_id", "bundesland", "behoerde", "kreis", "trend_normalized", "trend_bin"),
    names(df)
  )
  df$.x <- df$longitude
  df$.y <- df$latitude
  new_gwl_wells(df[, c(keep, ".x", ".y")], coords = c(".x", ".y"), crs = 4326L)
}
