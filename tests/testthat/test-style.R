test_that("lap_tokens returns coherent light and dark variants", {
  lt <- lap_tokens("light")
  dk <- lap_tokens("dark")
  expect_equal(lt$variant, "light")
  expect_equal(dk$colour$panel, "#040720")
  expect_identical(lt$colour$recharge, dk$colour$recharge)
  expect_true(all(c("title", "subtitle", "caption") %in% names(lt$size)))
})

test_that("palette roles resolve and reject unknown names", {
  expect_true(all(c("months", "magnitude", "anomaly") %in% lap_pal_roles()))
  expect_error(lapidary:::resolve_palette("bogus"), "Unknown palette role")
})

test_that("preset lookup works and errors on unknown", {
  p <- lap_preset("a1")
  expect_equal(p$dpi, 300)
  expect_true(p$width > 0 && p$height > 0)
  expect_error(lap_preset("a99"), "Unknown preset")
})

test_that("theme_lapidary builds for both variants and modes", {
  skip_if_not_installed("ggplot2")
  expect_s3_class(theme_lapidary("light", map = TRUE), "theme")
  expect_s3_class(theme_lapidary("dark", base_size = 40, map = FALSE), "theme")
})

test_that("scale + theme render without a font/dpi error at web and a1", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  library(ggplot2)
  p <- ggplot(data.frame(x = 1:10, y = 1:10, z = 1:10), aes(x, y, colour = z)) +
    geom_point() +
    scale_colour_lapidary_c("magnitude") +
    theme_lapidary(map = FALSE)
  for (preset in c("web", "a1")) {
    f <- withr::local_tempfile(fileext = ".png")
    expect_no_error(ggsave_lapidary(p, f, preset = preset))
    expect_true(file.exists(f))
  }
})
