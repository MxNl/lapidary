test_that("lap_ind_amplitude is max - min of the level", {
  df <- data.frame(
    well_id = "a", date = as.Date("2000-01-01") + 0:9,
    gwl = c(10, 12, 9, 15, 11, 8, 13, 14, 10, 9)
  )
  out <- lap_ind_amplitude(df)
  expect_named(out, "ind_amplitude")
  expect_equal(out$ind_amplitude, 15 - 8)
})

test_that("lap_ind_extreme_months finds the annual extreme months (circular)", {
  # min in December, max in June, two years -> circular means land there
  df <- do.call(rbind, lapply(2000:2002, function(y) {
    data.frame(
      well_id = "a",
      date = as.Date(sprintf("%d-%02d-15", y, 1:12)),
      gwl = c(5, 5, 5, 5, 5, 20, 5, 5, 5, 5, 5, 1)
    )
  }))
  out <- lap_ind_extreme_months(df)
  expect_equal(out$ind_min_month, 12, tolerance = 1e-6)
  expect_equal(out$ind_max_month, 6, tolerance = 1e-6)
})

test_that("lap_ind_trend recovers a known slope and NA-guards short series", {
  set.seed(1)
  weeks <- seq(as.Date("1991-01-07"), as.Date("2020-12-28"), by = "1 week")
  df <- data.frame(
    well_id = "a", date = weeks,
    gwl = 100 - 0.05 * as.numeric(weeks - weeks[1]) / 365.25 + rnorm(length(weeks), 0, 0.1)
  )
  out <- lap_ind_trend(df)
  expect_named(out, c("ind_trend_slope", "ind_trend_p_value", "ind_trend_significant"))
  expect_equal(out$ind_trend_slope, -0.05, tolerance = 0.02)
  expect_true(out$ind_trend_significant)

  short <- df[df$date < as.Date("1995-01-01"), ]
  expect_true(is.na(lap_ind_trend(short, min_years = 10)$ind_trend_slope))
})

test_that("lap_indicators binds one row per well with ind_ columns", {
  x <- new_gwl_ts(make_ts_fixture(1991:1995))
  ind <- lap_indicators(x, c(lap_ind_amplitude, lap_ind_extreme_months))
  expect_equal(nrow(ind), 2L)
  expect_setequal(ind$well_id, c("a", "b"))
  expect_true(all(startsWith(setdiff(names(ind), "well_id"), "ind_")))
})

test_that(".funs accepts functions, a single function, a list, string keys and 'all'", {
  x <- new_gwl_ts(make_ts_fixture())
  one <- lap_indicators(x, lap_ind_amplitude)
  many <- lap_indicators(x, list(lap_ind_amplitude))
  key <- lap_indicators(x, "amplitude")
  expect_equal(one, many)
  expect_equal(one, key)

  by_key <- lap_indicators(x, c("amplitude", "trend"))
  by_fun <- lap_indicators(x, c(lap_ind_amplitude, lap_ind_trend))
  expect_equal(by_key, by_fun)

  all <- lap_indicators(new_gwl_ts(make_ts_fixture(1991:2000)), "all")
  expect_setequal(
    setdiff(names(all), "well_id"),
    unlist(strsplit(lap_indicator_registry()$columns, ", "))
  )
})

test_that(".funs is required and unknown keys are rejected", {
  x <- new_gwl_ts(make_ts_fixture())
  expect_error(lap_indicators(x), "required")
  expect_error(lap_indicators(x, "nope"), "Unknown indicator key")
  expect_error(lap_indicators(x, 42), "keys or")
})

test_that("lap_indicator_registry lists one row per registered indicator", {
  reg <- lap_indicator_registry()
  expect_s3_class(reg, "tbl_df")
  expect_setequal(reg$key, c("amplitude", "extreme_months", "trend"))
  expect_type(reg$needs_date, "logical")
  expect_true(all(nzchar(reg$columns)))
  expect_true(all(nzchar(reg$description)))
})

test_that("a date-needing indicator on a frame without a date column errors cleanly", {
  df <- data.frame(well_id = c("a", "a"), gwl = c(1, 2))
  expect_error(lap_indicators(df, "extreme_months"), "date")
  expect_error(lap_ind_trend(df), "date")
})

test_that("lap_add_indicators left-joins onto an existing table (and keeps sf)", {
  x <- new_gwl_ts(make_ts_fixture(1991:1995))
  base <- lap_summarise_wells(x, by = well_id)
  out <- base |>
    lap_add_indicators(x, "amplitude") |>
    lap_add_indicators(x, lap_ind_trend)
  expect_true(all(c("ind_amplitude", "ind_trend_slope") %in% names(out)))
  expect_equal(nrow(out), nrow(base))
  expect_error(lap_add_indicators(base, x), "required")

  wells <- sf::st_as_sf(
    data.frame(well_id = c("a", "b"), x = c(9, 10), y = c(50, 51)),
    coords = c("x", "y"), crs = 4326
  )
  wsf <- lap_add_indicators(wells, x, "all")
  expect_s3_class(wsf, "sf")
  expect_true("ind_amplitude" %in% names(wsf))
})
