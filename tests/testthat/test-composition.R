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
