test_that("lap_summarise_wells computes per-well-year stats and coverage", {
  x <- new_gwl_ts(make_ts_fixture(1991:1992))
  s <- lap_summarise_wells(x, by = c("well_id", "year"), expected_per_year = 52)
  expect_setequal(names(s), c(
    "well_id", "year", "min_gwl", "max_gwl", "mean_gwl",
    "median_gwl", "sd_gwl", "n_obs", "coverage"
  ))
  expect_equal(nrow(s), 4L)
  expect_true(all(s$min_gwl <= s$mean_gwl & s$mean_gwl <= s$max_gwl))
  expect_true(all(s$coverage > 0.9 & s$coverage <= 1.02))
})

test_that("grouping by well only yields NA coverage and one row per well", {
  x <- new_gwl_ts(make_ts_fixture())
  s <- lap_summarise_wells(x, by = "well_id")
  expect_equal(nrow(s), 2L)
  expect_true(all(is.na(s$coverage)))
})

test_that("in-memory and DuckDB paths agree", {
  skip_if_not_installed("duckdb")
  x <- new_gwl_ts(make_ts_fixture(1991:1993))

  mem <- lap_summarise_wells(x, by = c("well_id", "year"))

  con <- lap_duckdb_con()
  on.exit(lap_disconnect(con), add = TRUE)
  duckdb::duckdb_register(con, "t", tibble::as_tibble(x))
  lazy <- lap_summarise_wells(dplyr::tbl(con, "t"),
    by = c("well_id", "year"), collect = TRUE
  )

  mem <- mem[order(mem$well_id, mem$year), ]
  lazy <- lazy[order(lazy$well_id, lazy$year), ]
  expect_equal(mem$mean_gwl, lazy$mean_gwl, tolerance = 1e-8)
  expect_equal(mem$n_obs, as.integer(lazy$n_obs))
})

test_that("by/value accept bare names, strings and tidyselect helpers", {
  x <- new_gwl_ts(make_ts_fixture(1991:1992))
  bare <- lap_summarise_wells(x, by = c(well_id, year), value = gwl)
  strs <- lap_summarise_wells(x, by = c("well_id", "year"), value = "gwl")
  helper <- lap_summarise_wells(x, by = dplyr::all_of(c("well_id", "year")))
  expect_equal(bare, strs)
  expect_equal(bare, helper)
  expect_error(
    lap_summarise_wells(x, value = c(gwl, well_id)),
    "exactly one column"
  )
})

test_that("lap_wells_with_coverage filters on years and coverage", {
  s <- data.frame(
    well_id = c(rep("a", 25), rep("b", 5)),
    coverage = c(rep(1, 25), rep(1, 5))
  )
  expect_equal(lap_wells_with_coverage(s, min_years = 20), "a")
})
