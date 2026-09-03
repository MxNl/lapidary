# CORRECTIV reader against tiny offline fixtures.

local_correctiv_fixture_cache <- function(env = parent.frame()) {
  skip_if_not_installed("duckdb")
  dir <- withr::local_tempdir(.local_envir = env)
  dl <- file.path(dir, "sources", "correctiv", "download")
  dir.create(file.path(dl, "monthly"), recursive = TRUE)
  src <- testthat::test_path("fixtures", "correctiv")
  file.copy(file.path(src, "messstellen.csv"), dl)
  file.copy(
    list.files(file.path(src, "monthly"), full.names = TRUE),
    file.path(dl, "monthly")
  )
  withr::local_options(list(lapidary.cache_dir = dir), .local_envir = env)
  dir
}

test_that("lap_correctiv_build_parquet + lap_read_correctiv produce a valid gwl_ts", {
  local_correctiv_fixture_cache()

  out <- lap_correctiv_build_parquet(overwrite = TRUE)
  expect_true(file.exists(out))

  x <- lap_read_correctiv()
  expect_s3_class(x, "gwl_ts")
  expect_no_error(validate_gwl_ts(x))
  expect_equal(unique(x$source), "correctiv")
  expect_equal(unique(x$variable), "gwl_m")
  expect_setequal(unique(x$well_id), c("be-1", "be-2", "bb-1"))
  # monthly rows land on the 15th
  expect_true(all(as.integer(format(x$date, "%d")) == 15L))
})

test_that("value = choose which monthly statistic becomes gwl", {
  local_correctiv_fixture_cache()
  lap_correctiv_build_parquet(overwrite = TRUE, value = "min")
  x <- lap_read_correctiv(wells = "be-1")
  # gwl should equal the min_gwl extra column
  expect_equal(x$gwl, x$min_gwl)
})

test_that("lap_read_correctiv_wells returns a projected gwl_wells layer, dropping wells without coords", {
  local_correctiv_fixture_cache()
  w <- lap_read_correctiv_wells()
  expect_s3_class(w, "gwl_wells")
  expect_equal(sf::st_crs(w)$epsg, 25832L)
  expect_setequal(w$well_id, c("be-1", "be-2", "bb-1")) # "xx-9" has no lat/long
})
