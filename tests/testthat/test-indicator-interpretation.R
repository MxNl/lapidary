test_that("every seeded interpretation has low + high in every language", {
  reg <- lapidary:::lap_interpretations
  expect_gt(length(reg), 0L)
  for (col in names(reg)) {
    expect_setequal(names(reg[[col]]), lap_langs())
    for (l in lap_langs()) {
      v <- reg[[col]][[l]]
      expect_setequal(names(v), c("low", "high"))
      expect_true(all(nzchar(v)))
    }
  }
})

test_that("seeded columns are real ind_* columns", {
  cols <- names(lapidary:::lap_interpretations)
  known <- lap_indicator_registry(long = TRUE)$column
  expect_true(all(cols %in% known))
})

test_that("indicator_interpretation resolves language and falls back to NULL", {
  f <- lapidary:::indicator_interpretation
  en <- f("ind_climate_cc", "en")
  expect_identical(names(en), c("low", "high"))
  expect_false(identical(f("ind_climate_cc", "de"), en))
  expect_null(f("ind_not_a_real_column"))
})
