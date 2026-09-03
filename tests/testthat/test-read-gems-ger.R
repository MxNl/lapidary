# Exercises the real ingest path (CSV -> DuckDB -> Parquet -> gwl_ts) against
# the tiny GEMS-GER-shaped fixtures, in an isolated cache directory.

local_gems_fixture_cache <- function(env = parent.frame()) {
  skip_if_not_installed("duckdb")
  dir <- withr::local_tempdir(.local_envir = env)
  ex <- file.path(dir, "sources", "gems-ger", "extracted", "1.0")
  dir.create(file.path(ex, "dynamic"), recursive = TRUE)
  dir.create(file.path(ex, "static"), recursive = TRUE)
  file.copy(
    list.files(file.path(gems_fixture_dir(), "dynamic"), full.names = TRUE),
    file.path(ex, "dynamic")
  )
  file.copy(
    list.files(file.path(gems_fixture_dir(), "static"), full.names = TRUE),
    file.path(ex, "static")
  )
  withr::local_options(list(lapidary.cache_dir = dir), .local_envir = env)
  dir
}

test_that("lap_gems_ger_build_parquet + lap_read_gems_ger produce a valid gwl_ts", {
  local_gems_fixture_cache()

  built <- lap_gems_ger_build_parquet(meteo = FALSE, overwrite = TRUE)
  expect_true(file.exists(built))

  x <- lap_read_gems_ger()
  expect_s3_class(x, "gwl_ts")
  expect_no_error(validate_gwl_ts(x))
  expect_setequal(unique(x$well_id), c("MW_1", "MW_2"))
  expect_equal(unique(x$variable), "gwl_m_asl")
  expect_equal(unique(x$source), "gems-ger")
  expect_s3_class(x$gwl_flag, "factor")
  expect_true(all(as.character(x$gwl_flag) %in% c("observed", "imputed")))
  expect_true(any(x$gwl_flag == "imputed"))
})

test_that("well and date filters push down", {
  local_gems_fixture_cache()
  lap_gems_ger_build_parquet(meteo = FALSE, overwrite = TRUE)

  one <- lap_read_gems_ger(wells = "MW_2")
  expect_equal(unique(one$well_id), "MW_2")

  window <- lap_read_gems_ger(date_range = as.Date(c("1992-01-01", "1992-12-31")))
  expect_true(all(format(window$date, "%Y") == "1992"))
})

test_that("lap_read_gems_ger_wells returns a projected gwl_wells layer", {
  local_gems_fixture_cache()
  w <- lap_read_gems_ger_wells()
  expect_s3_class(w, "gwl_wells")
  expect_equal(sf::st_crs(w)$epsg, 25832L)
  expect_setequal(w$well_id, c("MW_1", "MW_2"))
  expect_true(all(c("surface_elevation", "aquifer_medium") %in% names(w)))
})

test_that("lap_join_meteo left-joins forcing columns onto a GEMS-GER gwl_ts", {
  local_gems_fixture_cache()
  lap_gems_ger_build_parquet(meteo = FALSE, overwrite = TRUE)
  x <- lap_read_gems_ger()

  # a minimal meteo.parquet (only HYRAS_pr, as in the fixtures)
  meteo <- data.frame(
    well_id = x$well_id, date = x$date,
    HYRAS_pr = 3 + (as.integer(x$date) %% 11)
  )
  lap_write_gwl_parquet(meteo, "gems-ger", "1.0", which = "meteo", overwrite = TRUE)

  j <- lap_join_meteo(x, c(precip = "HYRAS_pr"))
  expect_s3_class(j, "gwl_ts")
  expect_true("precip" %in% names(j))
  expect_false("HYRAS_pr" %in% names(j))
  expect_equal(nrow(j), nrow(x))
  expect_false(anyNA(j$precip))

  # unnamed vars keep their source name
  expect_true("HYRAS_pr" %in% names(lap_join_meteo(x, "HYRAS_pr")))

  expect_error(lap_join_meteo(x, "NOPE"), "Unknown forcing column")
  not_gems <- new_gwl_ts(
    data.frame(well_id = "w", date = as.Date("2000-01-01"), gwl = 1),
    source = "correctiv"
  )
  expect_error(lap_join_meteo(not_gems, "HYRAS_pr"), "GEMS-GER")
})

test_that("lap_gems_ger_meta carries citation and licence", {
  m <- lap_gems_ger_meta()
  expect_match(m$licence, "CC-BY-NC-ND")
  expect_match(m$citation, "GEMS-GER")
  expect_equal(m$crs, 3035L)
})
