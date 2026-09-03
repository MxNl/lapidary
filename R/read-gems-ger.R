# GEMS-GER reader -----------------------------------------------------------
#
# GEMS-GER (Wunsch, Liesch & Broda, ESSD 2026; doi:10.5281/zenodo.15530171):
#   * 3,207 monitoring wells, gapless weekly groundwater levels 1991-2022
#   * one CSV per well: `dynamic/MW_<n>.csv`
#       col 1 (unnamed) = date (Monday of the ISO week)
#       `GWL`           = groundwater level, m above sea level
#       15 meteo forcing columns (HYRAS_*, DWD_*, ERA5_*)
#       `GWL_flag`      = TRUE observed / FALSE imputed
#   * `static/static_features_MW_1toMW_3207.csv`: 52 static attributes,
#       incl. `MW_ID`, `Easting (EPSG:3035)`, `Northing (EPSG:3035)`,
#       `Elevation`, `Depth`, `AquiferMed`, `PreState`, ...
#   * licence CC-BY-NC-ND 4.0.

gems_ger_records <- list(
  "1.0" = list(record = "16736908", data_md5 = "bb4ee350e317748e94f8b397719d55b2")
)
gems_ger_latest <- "1.0"

# The 15 meteorological / hydrological forcing columns.
gems_ger_meteo_cols <- c(
  "HYRAS_pr", "HYRAS_tas", "HYRAS_tasmax", "HYRAS_tasmin", "HYRAS_hurs",
  "DWD_evapo_p", "DWD_evapo_r", "DWD_evapo_fao", "DWD_soil_moist",
  "DWD_soil_temp5cm", "ERA5_sro", "ERA5_ssro", "ERA5_sdwe", "ERA5_sm", "ERA5_sf"
)

resolve_gems_version <- function(version) {
  if (identical(version, "latest")) gems_ger_latest else version
}

#' GEMS-GER dataset metadata
#'
#' @param version Version key (`"1.0"`) or `"latest"`.
#' @return A list with `version`, `record`, `doi`, `concept_doi`, `licence`,
#'   `citation`, `url`, `crs` and `variable`.
#' @export
#' @examples
#' lap_gems_ger_meta()
lap_gems_ger_meta <- function(version = "latest") {
  version <- resolve_gems_version(version)
  rec <- gems_ger_records[[version]]
  if (is.null(rec)) cli::cli_abort("Unknown GEMS-GER version {.val {version}}.")
  list(
    version = version,
    record = rec$record,
    doi = paste0("10.5281/zenodo.", rec$record),
    concept_doi = "10.5281/zenodo.15530171",
    licence = "CC-BY-NC-ND-4.0",
    citation = paste0(
      "Wunsch, A., Liesch, T. & Broda, S. (2026). GEMS-GER: A Machine Learning ",
      "Benchmark Dataset of Long-Term Groundwater Levels in Germany with ",
      "Meteorological Forcings and Site-Specific Environmental Features. ",
      "Earth System Science Data. doi:10.5281/zenodo.15530171"
    ),
    url = paste0("https://zenodo.org/records/", rec$record),
    crs = 3035L,
    variable = "gwl_m_asl"
  )
}

#' Download and extract the GEMS-GER dataset
#'
#' Fetches `GEMS-GER_data.zip` (~290 MB) from Zenodo into the lapidary cache
#' and unzips it. Skips work already done.
#'
#' @param version Version key or `"latest"`.
#' @param dir Cache root. Defaults to [lap_cache_dir()].
#' @param overwrite Force re-download.
#' @param quiet Suppress progress output.
#'
#' @return Path to the extracted directory (holding `dynamic/` and `static/`),
#'   invisibly.
#' @export
lap_gems_ger_download <- function(version = "latest",
                              dir = lap_cache_dir(),
                              overwrite = FALSE,
                              quiet = FALSE) {
  meta <- lap_gems_ger_meta(version)
  base <- file.path(dir, "sources", "gems-ger")
  zip <- file.path(base, "download", "GEMS-GER_data.zip")
  url <- sprintf(
    "https://zenodo.org/api/records/%s/files/GEMS-GER_data.zip/content", meta$record
  )
  lap_download_cached(url, zip,
    md5 = gems_ger_records[[meta$version]]$data_md5,
    overwrite = overwrite, quiet = quiet
  )
  exdir <- file.path(base, "extracted", meta$version)
  lap_unzip_once(zip, exdir, sentinel = "static")
  if (!quiet) {
    cli::cli_alert_info(
      "GEMS-GER {meta$version} ready ({.emph {meta$licence}} - non-commercial, no derivatives)."
    )
  }
  invisible(exdir)
}

lap_gems_ger_data_dir <- function(version = "latest") {
  version <- resolve_gems_version(version)
  d <- lap_cache_dir("sources", "gems-ger", "extracted", version)
  if (!dir.exists(file.path(d, "dynamic"))) {
    cli::cli_abort(c(
      "GEMS-GER {version} is not downloaded.",
      i = "Run {.run lapidary::lap_gems_ger_download()} first."
    ))
  }
  d
}

#' Build the GEMS-GER Parquet artifacts
#'
#' Converts the per-well CSVs into `gwl.parquet` (`well_id`, `date`, `gwl`,
#' `gwl_flag`) and, optionally, `meteo.parquet` (`well_id`, `date`, forcing
#' columns) in the lapidary cache. DuckDB does the conversion in one query;
#' run once per dataset version.
#'
#' @param version Version key or `"latest"`.
#' @param overwrite Overwrite existing Parquet files.
#' @param meteo Also build `meteo.parquet`.
#'
#' @return The Parquet paths, invisibly.
#' @export
lap_gems_ger_build_parquet <- function(version = "latest",
                                   overwrite = FALSE,
                                   meteo = TRUE) {
  version <- resolve_gems_version(version)
  glob <- file.path(lap_gems_ger_data_dir(version), "dynamic", "*.csv")
  out_dir <- lap_parquet_dir("gems-ger", version, create = TRUE)

  want <- c("gwl.parquet", if (meteo) "meteo.parquet")
  have <- file.exists(file.path(out_dir, want))
  if (!overwrite && all(have)) {
    cli::cli_alert_info("GEMS-GER Parquet already built in {.path {out_dir}}; skipping.")
    return(invisible(file.path(out_dir, want)))
  }

  # The date column is the (unnamed) first column; DuckDB names it
  # column0/column00/... depending on the column count, so detect it.
  one <- list.files(file.path(lap_gems_ger_data_dir(version), "dynamic"),
    pattern = "\\.csv$", full.names = TRUE
  )[[1]]
  date_col <- lap_duckdb_columns(sprintf("read_csv_auto(%s)", dbq(one)))[[1]]

  well_id <- "regexp_extract(filename, '([^/\\\\]+)\\.csv$', 1)"
  date <- sprintf('CAST("%s" AS DATE)', date_col)

  gwl_path <- file.path(out_dir, "gwl.parquet")
  if (overwrite || !file.exists(gwl_path)) {
    lap_csvs_to_parquet(
      glob, gwl_path,
      select_sql = sprintf(
        "%s AS well_id, %s AS date, GWL AS gwl,
         CASE WHEN GWL_flag THEN 'observed' ELSE 'imputed' END AS gwl_flag",
        well_id, date
      ),
      overwrite = TRUE
    )
  }
  built <- gwl_path

  if (meteo) {
    meteo_path <- file.path(out_dir, "meteo.parquet")
    if (overwrite || !file.exists(meteo_path)) {
      sel <- paste(sprintf('"%s"', gems_ger_meteo_cols), collapse = ", ")
      lap_csvs_to_parquet(
        glob, meteo_path,
        select_sql = sprintf("%s AS well_id, %s AS date, %s", well_id, date, sel),
        overwrite = TRUE
      )
    }
    built <- c(built, meteo_path)
  }
  cli::cli_alert_success("Built {length(built)} Parquet file{?s} in {.path {out_dir}}.")
  invisible(built)
}

#' Read GEMS-GER groundwater levels as a `gwl_ts`
#'
#' Requires [lap_gems_ger_build_parquet()] to have been run for `version`.
#'
#' @inheritParams lap_read_gwl
#' @return A `gwl_ts` (`variable` = `"gwl_m_asl"`, `source` = `"gems-ger"`).
#' @export
lap_read_gems_ger <- function(version = "latest", wells = NULL,
                              date_range = NULL) {
  lap_read_gwl(
    source = "gems-ger", version = version,
    wells = wells, date_range = date_range,
    variable = lap_gems_ger_meta(version)$variable
  )
}

#' Read GEMS-GER well metadata as a `gwl_wells` layer
#'
#' @param version Version key or `"latest"`.
#' @param attributes Which static columns to keep: `"core"` (a curated subset),
#'   `"all"`, or a character vector of column names (original casing).
#'
#' @return A `gwl_wells` `sf` layer in EPSG:25832.
#' @export
lap_read_gems_ger_wells <- function(version = "latest", attributes = "core") {
  version <- resolve_gems_version(version)
  csv <- file.path(
    lap_gems_ger_data_dir(version), "static", "static_features_MW_1toMW_3207.csv"
  )
  if (!file.exists(csv)) {
    csv <- list.files(
      file.path(lap_gems_ger_data_dir(version), "static"),
      pattern = "\\.csv$", full.names = TRUE
    )[[1]]
  }
  raw <- utils::read.csv(csv, check.names = FALSE, encoding = "UTF-8")
  raw <- raw[, names(raw) != "", drop = FALSE]

  core <- c(
    well_id = "MW_ID", proj_id = "Proj_ID", operator = "Operator",
    surface_elevation = "Elevation", well_depth = "Depth",
    screen_top = "UpFilter", screen_bottom = "LoFilter",
    screen_length = "ScrLength", aquifer_medium = "AquiferMed",
    pressure_state = "PreState", hydro_region = "HYRAUM_HD",
    easting = "Easting (EPSG:3035)", northing = "Northing (EPSG:3035)"
  )

  df <- data.frame(well_id = as.character(raw[["MW_ID"]]), check.names = FALSE)
  keep <- if (identical(attributes, "all")) {
    setdiff(names(raw), "MW_ID")
  } else if (identical(attributes, "core")) {
    intersect(unname(core), names(raw))
  } else {
    intersect(attributes, names(raw))
  }
  for (col in keep) {
    nm <- names(core)[match(col, core)]
    if (is.na(nm)) nm <- to_snake_case(col)
    df[[nm]] <- raw[[col]]
  }

  new_gwl_wells(df, coords = c("easting", "northing"), crs = lap_gems_ger_meta(version)$crs)
}

#' Join GEMS-GER meteorological forcings onto a groundwater series
#'
#' Reads the requested forcing columns from `meteo.parquet` (build it with
#' [lap_gems_ger_build_parquet()] `meteo = TRUE`) and left-joins them onto a
#' GEMS-GER `gwl_ts` by `well_id` and `date`. The result is still a `gwl_ts`;
#' the joined columns are what [lap_ind_climate_signal()] needs as its `driver`.
#'
#' @param x A `gwl_ts` from [lap_read_gems_ger()] (its `source` must be
#'   `"gems-ger"`).
#' @param vars Forcing columns to join. Either `"all"`, or a character vector of
#'   names from `gems_ger_meteo_cols` (`HYRAS_pr`, `DWD_evapo_p`, ...),
#'   optionally **named** to rename on join, e.g.
#'   `c(precip = "HYRAS_pr", pet = "DWD_evapo_p")`.
#' @param version Version key or `"latest"`.
#'
#' @return `x` with the forcing columns added (a `gwl_ts`).
#' @seealso [lap_ind_climate_signal()], [lap_gems_ger_build_parquet()]
#' @export
#' @examples
#' \dontrun{
#' lap_read_gems_ger() |>
#'   lap_join_meteo(c(precip = "HYRAS_pr")) |>
#'   lap_normalise_gwl("sgi") |>
#'   lap_indicators("climate_signal", value = gwl_norm, driver = precip)
#' }
lap_join_meteo <- function(x, vars = "all", version = "latest") {
  check_gwl_ts(x)
  src <- unique(stats::na.omit(as.character(x[["source"]])))
  if (!identical(src, "gems-ger")) {
    cli::cli_abort(c(
      "{.arg x} must be a GEMS-GER series (from {.fn lap_read_gems_ger}).",
      i = "Its {.field source} is {.val {src}}."
    ))
  }
  map <- resolve_meteo_vars(vars)
  cols <- unname(map)
  wells <- unique(as.character(x[["well_id"]]))
  dr <- range(as.Date(x[["date"]]), na.rm = TRUE)
  lo <- format(dr[[1]])
  hi <- format(dr[[2]])

  m <- lap_gwl_query(
    function(t) {
      t <- dplyr::filter(
        t, .data$well_id %in% !!wells,
        .data$date >= !!lo, .data$date <= !!hi
      )
      dplyr::select(t, dplyr::all_of(c("well_id", "date", cols)))
    },
    source = "gems-ger", version = version, which = "meteo"
  )
  m[["date"]] <- as.Date(m[["date"]])
  names(m)[match(cols, names(m))] <- names(map)

  out <- dplyr::left_join(tibble::as_tibble(x), m, by = c("well_id", "date"))
  new_gwl_ts(out)
}

# Validate / normalise the `vars` argument of lap_join_meteo() to a named
# character vector `new_name = source_column`.
resolve_meteo_vars <- function(vars, call = rlang::caller_env()) {
  if (identical(vars, "all")) {
    return(stats::setNames(gems_ger_meteo_cols, gems_ger_meteo_cols))
  }
  nms <- names(vars)
  vars <- as.character(vars)
  if (is.null(nms)) nms <- rep("", length(vars))
  nms[!nzchar(nms)] <- vars[!nzchar(nms)]
  bad <- setdiff(vars, gems_ger_meteo_cols)
  if (length(bad)) {
    cli::cli_abort(c(
      "Unknown forcing column{?s} {.val {bad}}.",
      i = "Available: {.val {gems_ger_meteo_cols}}."
    ), call = call)
  }
  stats::setNames(vars, nms)
}

# Minimal snake_case cleaner (avoids a janitor dependency).
to_snake_case <- function(x) {
  x <- gsub("\\(EPSG:[0-9]+\\)", "", x)
  x <- trimws(x)
  x <- gsub("[^A-Za-z0-9]+", "_", x)
  tolower(gsub("^_|_$", "", x))
}
