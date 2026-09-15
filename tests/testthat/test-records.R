test_that("a well's first year is not evaluated - it seeds the running record instead", {
  df <- data.frame(
    well_id = "w1", date = as.Date(c("2020-03-01", "2020-11-01")), gwl = c(5, 1)
  )
  out <- lap_add_record_flags(df)
  expect_true(all(is.na(out$is_new_min)))
  expect_true(all(is.na(out$is_new_max)))
})

test_that("the first year is not evaluated; a tied subsequent year sets no record either", {
  df <- data.frame(
    well_id = "w1",
    date = as.Date(c(
      "2018-03-01", "2018-07-01", "2018-11-01", # first year: NA, not evaluated
      "2019-02-01", "2019-08-01" # ties the values seeded by 2018: no record
    )),
    gwl = c(5, 6, 4, 4, 4)
  )
  out <- lap_add_record_flags(df)
  expect_true(all(is.na(out$is_new_min[1:3])))
  expect_true(all(is.na(out$is_new_max[1:3])))
  expect_true(all(!out$is_new_min[4:5]))
  expect_true(all(!out$is_new_max[4:5]))
})

test_that("a year that beats history flags exactly its own extreme timestep", {
  df <- data.frame(
    well_id = "w1",
    date = as.Date(c(
      "2018-03-01", "2018-07-01", "2018-11-01", # 2018: first year - not evaluated (NA)
      "2019-02-01", "2019-08-01", # 2019: ties 2018's seeded min/max, no record
      "2020-01-01", "2020-06-01", "2020-06-02", "2020-12-01" # 2020: min 2, max 9
    )),
    gwl = c(5, 6, 4, 4, 4, 3, 9, 3, 2)
  )
  out <- lap_add_record_flags(df)
  expect_identical(which(out$is_new_min), which(out$date == as.Date("2020-12-01")))
  expect_identical(which(out$is_new_max), which(out$date == as.Date("2020-06-01")))
  expect_equal(sum(out$is_new_min, na.rm = TRUE), 1L)
  expect_equal(sum(out$is_new_max, na.rm = TRUE), 1L)
})

test_that("a tied annual extreme flags only the first chronological occurrence", {
  df <- data.frame(
    well_id = "w1",
    date = as.Date(c("2018-01-01", "2019-01-01", "2019-06-01", "2019-09-01")),
    gwl = c(5, 1, 1, 1) # 2019's minimum (1) occurs three times
  )
  out <- lap_add_record_flags(df)
  # 2018-01-01 is the (only-observation) first year - NA, not evaluated
  expect_identical(which(out$is_new_min), which(out$date == as.Date("2019-01-01")))
})

test_that("a subsequent tie with the running record is not a new record", {
  df <- data.frame(
    well_id = "w1",
    date = as.Date(c("2018-06-01", "2019-06-01", "2020-06-01")),
    gwl = c(5, 2, 2) # 2020 ties 2019's new low; not itself a new record
  )
  out <- lap_add_record_flags(df)
  expect_true(out$is_new_min[out$date == as.Date("2019-06-01")])
  expect_false(out$is_new_min[out$date == as.Date("2020-06-01")])
})

test_that("NA values are excluded from a year's extreme and don't break the running comparison", {
  df <- data.frame(
    well_id = "w1",
    date = as.Date(c("2018-06-01", "2019-03-01", "2019-06-01", "2020-06-01")),
    gwl = c(5, NA, 2, 1)
  )
  out <- lap_add_record_flags(df)
  expect_false(out$is_new_min[is.na(out$gwl)])
  expect_true(out$is_new_min[out$date == as.Date("2019-06-01")])
  expect_true(out$is_new_min[out$date == as.Date("2020-06-01")])
})

test_that("a well-year with only NA values is skipped entirely", {
  df <- data.frame(
    well_id = "w1",
    date = as.Date(c("2018-06-01", "2019-06-01", "2020-06-01")),
    gwl = c(5, NA, 1)
  )
  out <- lap_add_record_flags(df)
  # 2020 must still be compared against 2018 (the only real prior year), not
  # skipped just because 2019 had no data
  expect_true(out$is_new_min[out$date == as.Date("2020-06-01")])
})

test_that("multiple wells are evaluated independently", {
  df <- data.frame(
    well_id = rep(c("w1", "w2"), each = 4),
    date = rep(as.Date(c("2018-06-01", "2019-06-01", "2020-06-01", "2021-06-01")), 2),
    gwl = c(5, 4, 3, 2, 1, 1, 1, 1)
  )
  out <- lap_add_record_flags(df)
  w2 <- out[out$well_id == "w2", ]
  w2 <- w2[order(w2$date), ]
  # 2018 (first year) is NA, not evaluated; 2019-2021 all tie at 1, never
  # beating the running record seeded (silently) by 2018
  expect_true(is.na(w2$is_new_min[1]))
  expect_true(all(!w2$is_new_min[-1]))
})

test_that("flags are computed chronologically, independent of input row order", {
  df <- data.frame(
    well_id = "w1",
    date = as.Date(c("2018-06-01", "2019-06-01", "2020-06-01")),
    gwl = c(5, 2, 1)
  )
  shuffled <- df[c(3, 1, 2), ]
  out <- lap_add_record_flags(shuffled)
  out <- out[order(out$date), ]
  expect_identical(out$is_new_min, c(NA, TRUE, TRUE))
})

test_that("into_min / into_max / into_balance rename the output columns", {
  df <- data.frame(
    well_id = "w1", date = as.Date(c("2018-06-01", "2019-06-01")), gwl = c(5, 1)
  )
  out <- lap_add_record_flags(df, into_min = "low", into_max = "high", into_balance = "net")
  expect_true(all(c("low", "high", "net") %in% names(out)))
  expect_false(any(c("is_new_min", "is_new_max", "record_balance") %in% names(out)))
})

test_that("record_balance is +1/-1 on a record row, 0 elsewhere, and sums correctly", {
  df <- data.frame(
    well_id = "w1",
    date = as.Date(c(
      "2018-03-01", "2018-07-01", "2018-11-01", # 2018: first year - not evaluated (NA)
      "2019-06-01", # 2019: new low (2 < 4)
      "2020-06-01" # 2020: new high (9 > 6)
    )),
    gwl = c(5, 6, 4, 2, 9)
  )
  out <- lap_add_record_flags(df)
  expect_identical(out$record_balance, c(NA_integer_, NA_integer_, NA_integer_, -1L, 1L))
  # summing record_balance per bucket equals summing is_new_max - is_new_min
  # separately (the whole point of the single-column shortcut) - only over
  # buckets that actually have a real (non-first-year) contribution
  cal <- lap_summarise_calendar(out, record_balance)
  cal_two <- lap_summarise_calendar(out, is_new_min, is_new_max)
  net_from_two <- stats::aggregate(
    n ~ year + unit,
    data = transform(cal_two, n = ifelse(name == "new_max", n, -n)),
    FUN = sum
  )
  merged <- merge(cal, net_from_two, by = c("year", "unit"))
  expect_equal(merged$n.x, merged$n.y)
  expect_equal(nrow(cal), 2L) # 2018's all-NA months are dropped entirely
})
