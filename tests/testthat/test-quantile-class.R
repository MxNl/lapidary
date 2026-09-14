test_that("lap_add_quantile_class adds an ordered 7-band factor", {
  out <- lap_add_quantile_class(gems_ger_sample)
  expect_true("gwl_class" %in% names(out))
  expect_true(is.ordered(out$gwl_class))
  expect_setequal(
    levels(out$gwl_class),
    c("Very low", "Low", "Below normal", "Normal", "Above normal", "High", "Very high")
  )
})

test_that("classes are monotone in the raw value, per well", {
  out <- lap_add_quantile_class(gems_ger_sample)
  one <- out[out$well_id == out$well_id[[1]], ]
  one <- one[order(one$gwl), ]
  # non-NA class codes must be non-decreasing as the raw value increases
  codes <- as.integer(one$gwl_class)
  codes <- codes[!is.na(codes)]
  expect_true(all(diff(codes) >= 0))
})

test_that("into, breaks and labels are configurable", {
  out <- lap_add_quantile_class(
    gems_ger_sample,
    breaks = c(0, .5, 1), labels = c("lo", "hi"), into = "band"
  )
  expect_true("band" %in% names(out))
  expect_setequal(levels(out$band), c("lo", "hi"))

  expect_error(
    lap_add_quantile_class(gems_ger_sample, breaks = c(0, .5, 1), labels = c("a", "b", "c")),
    "labels"
  )
})

test_that("lang controls the default labels", {
  en <- lap_add_quantile_class(gems_ger_sample[1:200, ], lang = "en")
  de <- lap_add_quantile_class(gems_ger_sample[1:200, ], lang = "de")
  expect_identical(levels(en$gwl_class)[[1]], "Very low")
  expect_identical(levels(de$gwl_class)[[1]], "Sehr niedrig")
})

test_that("a constant well is classified NA with a warning", {
  df <- data.frame(
    well_id = "w1", date = as.Date("2020-01-01") + (0:9) * 7, gwl = 5
  )
  expect_warning(out <- lap_add_quantile_class(df), "no spread")
  expect_true(all(is.na(out$gwl_class)))
})

test_that("reference restricts which rows set the breakpoints, not which rows get classified", {
  set.seed(1)
  dates <- as.Date("2000-01-01") + (0:519) * 7 # 10 years, weekly
  yr <- as.integer(format(dates, "%Y"))
  # reference decade (2000-2004): tight around 10; later decade (2005-2009):
  # levels much higher, i.e. a well that has "recovered"/risen structurally
  gwl <- ifelse(yr < 2005, 10 + stats::rnorm(length(dates), sd = 0.2), 10 + 3)
  df <- data.frame(well_id = "w1", date = dates, gwl = gwl)

  out <- lap_add_quantile_class(df, reference = c(2000, 2004))
  # rows far outside the reference window's tight range must land in the
  # open-ended top band, not become NA
  later <- out[yr >= 2005, ]
  expect_true(all(as.character(later$gwl_class) == "Very high"))
})

test_that("wrong-shape input errors toward a data frame", {
  expect_error(
    lap_add_quantile_class(gems_ger_wells_sample),
    "column|value|gwl"
  )
})
