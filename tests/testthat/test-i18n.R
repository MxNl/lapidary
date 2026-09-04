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

test_that("lap_variant resolves option, default and rejects bad values", {
  withr::with_options(list(lapidary.variant = NULL), expect_equal(lap_variant(), "light"))
  withr::with_options(list(lapidary.variant = "dark"), expect_equal(lap_variant(), "dark"))
  expect_equal(lap_variant("dark"), "dark")
  expect_error(lap_variant("neon"), "Unknown visual variant")
  expect_setequal(lap_variants(), c("light", "dark"))
})

test_that("lap_howto looks up the builder explainer and injects accent colours", {
  h <- lap_howto("hex_map")
  expect_type(h, "character")
  expect_length(h, 1L)
  expect_match(h, "hexagon", ignore.case = TRUE)
  expect_identical(lap_howto("hex_map", lang = "de"), lap_tr("howto_hex_map", "de"))
})

test_that("every howto_* key is present in all languages", {
  reg <- lapidary:::lap_labels
  for (id in grep("^howto_", names(reg), value = TRUE)) {
    expect_setequal(names(reg[[id]]), lap_langs())
    for (l in lap_langs()) expect_true(nzchar(reg[[id]][[l]]))
  }
})
