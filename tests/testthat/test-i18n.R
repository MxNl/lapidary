test_that("tr returns per-language strings and fills placeholders", {
  expect_equal(lap_tr("app_title", "en"), "Groundwater in Germany")
  expect_equal(lap_tr("app_title", "de"), "Grundwasser in Deutschland")
  expect_equal(lap_tr("by_author", "en", author = "Max"), "By Max")
  expect_equal(lap_tr("by_author", "de", author = "Max"), "Von Max")
  expect_length(lap_tr("month_names", "de"), 12)
})

test_that("tr errors on an unknown id", {
  expect_error(lap_tr("nope"), "Unknown label id")
})

test_that("every registry entry has all supported languages", {
  reg <- lapidary:::lap_labels
  for (id in names(reg)) {
    expect_setequal(names(reg[[id]]), lap_langs())
  }
})

test_that("lap_lang resolves option, default and rejects bad codes", {
  withr::with_options(list(lapidary.lang = NULL), expect_equal(lap_lang(), "en"))
  withr::with_options(list(lapidary.lang = "de"), expect_equal(lap_lang(), "de"))
  expect_error(lap_lang("fr"), "Unsupported language")
})
