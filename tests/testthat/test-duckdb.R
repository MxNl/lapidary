# Parquet/DuckDB backend: version resolution and connection lifetime.

local_two_version_cache <- function(env = parent.frame()) {
  skip_if_not_installed("duckdb")
  dir <- withr::local_tempdir(.local_envir = env)
  withr::local_options(list(lapidary.cache_dir = dir), .local_envir = env)
  toy <- data.frame(
    well_id = "a", date = as.Date("2000-01-01") + 0:9, gwl = as.numeric(1:10),
    gwl_flag = "observed"
  )
  lap_write_gwl_parquet(toy, source = "toy", version = "1.0")
  lap_write_gwl_parquet(transform(toy, gwl = gwl + 1), source = "toy", version = "1.2")
  dir
}

test_that("`version = 'latest'` resolves to the newest built version", {
  local_two_version_cache()
  x <- lap_read_gwl(source = "toy") # default version = "latest"
  # v1.2 has gwl shifted +1
  expect_equal(x$gwl, as.numeric(2:11))
  expect_error(lap_read_gwl(source = "toy", version = "9.9"), regexp = "parquet|Parquet")
})

test_that("no built dataset gives an actionable error", {
  skip_if_not_installed("duckdb")
  withr::local_options(list(lapidary.cache_dir = withr::local_tempdir()))
  expect_error(lap_gwl_tbl("nope"), "Build it first")
})

test_that("lap_disconnect closes the connection even after dplyr verbs", {
  local_two_version_cache()
  tb <- lap_gwl_tbl("toy")
  con <- tb$src$con
  expect_true(DBI::dbIsValid(con))
  tb2 <- dplyr::filter(tb, .data$well_id == "a") |> dplyr::mutate(z = gwl * 2)
  lap_disconnect(tb2)
  expect_false(DBI::dbIsValid(con))
})

test_that("lap_gwl_query runs a lazy pipeline and closes its own connection", {
  local_two_version_cache()
  res <- lap_gwl_query(\(t) dplyr::summarise(t, n = dplyr::n(), mx = max(gwl, na.rm = TRUE)),
    source = "toy"
  )
  expect_s3_class(res, "tbl_df")
  expect_equal(res$n, 10L)
  expect_equal(res$mx, 11)
})

test_that("lap_write_gwl_parquet refuses the literal 'latest'", {
  skip_if_not_installed("duckdb")
  withr::local_options(list(lapidary.cache_dir = withr::local_tempdir()))
  expect_error(
    lap_write_gwl_parquet(data.frame(well_id = "a", date = Sys.Date(), gwl = 1),
      source = "toy", version = "latest"
    ),
    "concrete version"
  )
})
