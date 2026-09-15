test_that("shares sum to 1 in every bucket and empty categories get n = 0", {
  gc <- lap_add_quantile_class(gems_ger_sample)
  comp <- lap_summarise_composition(gc, gwl_class)

  expect_setequal(names(comp), c("date", "gwl_class", "n", "share"))
  totals <- as.numeric(tapply(comp$share, comp$date, sum))
  expect_equal(totals, rep(1, length(totals)), tolerance = 1e-9)
  # every bucket lists all 7 levels, even the zero-count ones
  expect_true(all(table(comp$date) == 7L))
  expect_true(any(comp$n == 0L))
})

test_that("a well contributes once per bucket even with finer input resolution", {
  # two wells, both observed twice within the same ISO week
  df <- data.frame(
    well_id = rep(c("w1", "w2"), each = 2),
    date = as.Date(c("2020-01-06", "2020-01-07", "2020-01-06", "2020-01-08")),
    cls = factor(c("a", "a", "b", "b"), levels = c("a", "b"), ordered = TRUE)
  )
  comp <- lap_summarise_composition(df, cls, period = "week")
  expect_equal(nrow(comp), 2L) # one week bucket x 2 levels
  expect_equal(sum(comp$n), 2L) # 2 wells, not 4 rows
})

test_that("period buckets to month / year", {
  gc <- lap_add_quantile_class(gems_ger_sample[1:500, ])
  by_month <- lap_summarise_composition(gc, gwl_class, period = "month")
  by_year <- lap_summarise_composition(gc, gwl_class, period = "year")
  expect_true(all(format(by_month$date, "%d") == "01"))
  expect_true(all(format(by_year$date, "%m-%d") == "01-01"))
})

test_that("wrong data shape errors", {
  expect_error(
    lap_summarise_composition(gems_ger_wells_sample, well_id),
    "date|column"
  )
})

# --- lap_summarise_calendar --------------------------------------------

test_that("lap_summarise_calendar sums event columns into a long year x unit table", {
  df <- data.frame(
    date = as.Date("2020-01-01") + (0:59) * 7,
    is_new_min = rep(c(TRUE, FALSE, FALSE, FALSE), length.out = 60),
    is_new_max = rep(c(FALSE, FALSE, TRUE, FALSE), length.out = 60)
  )
  cal <- lap_summarise_calendar(df, is_new_min, is_new_max)
  expect_setequal(names(cal), c("year", "unit", "name", "n"))
  expect_setequal(cal$name, c("new_min", "new_max")) # "is_" prefix stripped
  expect_true(all(cal$n >= 0))
  expect_equal(sum(cal$n[cal$name == "new_min"]), sum(df$is_new_min))
  expect_equal(sum(cal$n[cal$name == "new_max"]), sum(df$is_new_max))
})

test_that("a bucket with data but no event still gets a real n = 0", {
  df <- data.frame(
    date = as.Date(c("2020-01-01", "2020-01-08")),
    is_new_min = c(FALSE, FALSE)
  )
  cal <- lap_summarise_calendar(df, is_new_min)
  expect_equal(nrow(cal), 1L) # both weeks fall in Jan 2020 -> one bucket
  expect_equal(cal$n, 0L)
})

test_that("period = 'week' pairs ISO week with its ISO week-year", {
  # 2021-01-01 is a Friday in ISO week 53 of 2020
  df <- data.frame(date = as.Date("2021-01-01"), is_new_min = TRUE)
  cal <- lap_summarise_calendar(df, is_new_min, period = "week")
  expect_equal(cal$year, 2020)
  expect_equal(cal$unit, 53)
})

test_that("lap_summarise_calendar requires at least one column to sum", {
  expect_error(
    lap_summarise_calendar(data.frame(date = Sys.Date())),
    "at least one column"
  )
})
