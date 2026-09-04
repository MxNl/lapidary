skip_if_not_installed("ggplot2")
skip_if_not_installed("scico")
skip_if_not_installed("sf")

library(ggplot2)

test_that("lap_plot_hex_map returns a themed ggplot with one lapidary scale", {
  p <- lap_plot_hex_map(germany_hex_sample, mean_gwl)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))

  scales <- p$scales$scales
  fill_scales <- Filter(function(s) "fill" %in% s$aesthetics, scales)
  expect_length(fill_scales, 1L)
  expect_s3_class(fill_scales[[1]], "ScaleBinned")

  # the how-to caption is on by default
  expect_match(p$labels$caption, "hexagon", ignore.case = TRUE)
  expect_equal(p$labels$fill, "Mean GWL")
})

test_that("annotate controls the how-to caption", {
  expect_null(lap_plot_hex_map(germany_hex_sample, mean_gwl, annotate = NA)$labels$caption)
  expect_identical(
    lap_plot_hex_map(germany_hex_sample, mean_gwl, annotate = "custom text")$labels$caption,
    "custom text"
  )
  withr::local_options(lapidary.annotate = NA)
  expect_null(lap_plot_hex_map(germany_hex_sample, mean_gwl)$labels$caption)
})

test_that("variant swaps the panel background and is honoured from the option", {
  light <- lap_plot_hex_map(germany_hex_sample, mean_gwl, variant = "light")
  dark <- lap_plot_hex_map(germany_hex_sample, mean_gwl, variant = "dark")
  expect_false(identical(
    light$theme$plot.background$fill, dark$theme$plot.background$fill
  ))
  withr::local_options(lapidary.variant = "dark")
  expect_identical(
    lap_plot_hex_map(germany_hex_sample, mean_gwl)$theme$plot.background$fill,
    dark$theme$plot.background$fill
  )
})

test_that("na_guide is added only when the value column has NAs", {
  with_na <- lap_plot_hex_map(germany_hex_sample, mean_gwl) # empty hexes -> NA
  no_na <- lap_plot_hex_map(germany_hex_sample, n_wells) # always 0+
  aes_of <- function(p) unlist(lapply(p$scales$scales, function(s) s$aesthetics))
  expect_true("shape" %in% aes_of(with_na))
  expect_false("shape" %in% aes_of(no_na))
})

test_that("a circular-month column gets the cyclic (non-binned) scale", {
  hex <- germany_hex_sample
  hex$ind_max_month <- ((seq_len(nrow(hex)) %% 12) + 1)
  p <- lap_plot_hex_map(hex, ind_max_month)
  fill_scale <- Filter(function(s) "fill" %in% s$aesthetics, p$scales$scales)[[1]]
  expect_false(inherits(fill_scale, "ScaleBinned"))
})

test_that("a non-sf / wrong shape errors with a pointer to the primitive", {
  expect_error(
    lap_plot_hex_map(as.data.frame(mtcars), mpg),
    "lap_aggregate_to_hex"
  )
})

test_that("a POINT layer dispatches to lap_plot_point_map", {
  p <- lap_plot_hex_map(gems_ger_wells_sample, surface_elevation)
  expect_s3_class(p, "ggplot")
  colour_scale <- Filter(function(s) "colour" %in% s$aesthetics, p$scales$scales)
  expect_length(colour_scale, 1L)
})

test_that("lap_plot_point_map builds and errors on a polygon layer", {
  p <- lap_plot_point_map(gems_ger_wells_sample, surface_elevation, basemap = FALSE)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))
  expect_error(lap_plot_point_map(germany_hex_sample, mean_gwl), "POINT")
})

test_that("preset supplies the poster base size", {
  p <- lap_plot_hex_map(germany_hex_sample, mean_gwl, preset = "a1")
  a1 <- lap_preset("a1")$base_size
  expect_equal(p$theme$text$size, a1)
})
