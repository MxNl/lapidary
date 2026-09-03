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

test_that("lap_indicators accepts a single function and a list", {
  x <- new_gwl_ts(make_ts_fixture())
  one <- lap_indicators(x, lap_ind_amplitude)
  many <- lap_indicators(x, list(lap_ind_amplitude))
  expect_equal(one, many)
  expect_error(lap_indicators(x, .funs = "nope"), "lap_ind")
})

test_that("a date-needing indicator on a frame without a date column errors cleanly", {
  df <- data.frame(well_id = c("a", "a"), gwl = c(1, 2))
  expect_error(lap_indicators(df, lap_ind_extreme_months), "date")
  expect_error(lap_ind_trend(df), "date")
})

test_that("lap_summarise_wells(indicators=) folds indicators into one pass", {
  x <- new_gwl_ts(make_ts_fixture(1991:1995))
  s <- lap_summarise_wells(x, by = well_id, indicators = c(lap_ind_amplitude, lap_ind_trend))
  expect_true(all(c("mean_gwl", "ind_amplitude", "ind_trend_slope") %in% names(s)))
  expect_equal(nrow(s), 2L)

  # identical to computing separately and joining
  manual <- dplyr::left_join(
    lap_summarise_wells(x, by = well_id),
    lap_indicators(x, c(lap_ind_amplitude, lap_ind_trend)),
    by = "well_id"
  )
  expect_equal(s, manual)
})

test_that("indicators require a well-level grouping", {
  x <- new_gwl_ts(make_ts_fixture())
  expect_error(
    lap_summarise_wells(x, by = c(well_id, year), indicators = lap_ind_amplitude),
    "well-level"
  )
})

test_that("lap_add_indicators left-joins onto an existing table (and keeps sf)", {
  x <- new_gwl_ts(make_ts_fixture(1991:1995))
  base <- lap_summarise_wells(x, by = well_id)
  out <- base |>
    lap_add_indicators(x, lap_ind_amplitude) |>
    lap_add_indicators(x, lap_ind_trend)
  expect_true(all(c("ind_amplitude", "ind_trend_slope") %in% names(out)))
  expect_equal(nrow(out), nrow(base))

  wells <- sf::st_as_sf(
    data.frame(well_id = c("a", "b"), x = c(9, 10), y = c(50, 51)),
    coords = c("x", "y"), crs = 4326
  )
  wsf <- lap_add_indicators(wells, x, lap_ind_amplitude)
  expect_s3_class(wsf, "sf")
  expect_true("ind_amplitude" %in% names(wsf))
})
