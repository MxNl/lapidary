skip_if_not_installed("ggplot2")
skip_if_not_installed("scico")

library(ggplot2)

ind <- lap_indicators(gems_ger_sample, c("amplitude", "trend"))

test_that("lap_plot_distribution builds histogram / density with a gradient fill", {
  for (g in c("histogram", "density")) {
    p <- lap_plot_distribution(ind, ind_amplitude, geom = g)
    expect_s3_class(p, "ggplot")
    expect_no_error(ggplot_build(p))
    fill_scale <- Filter(function(s) "fill" %in% s$aesthetics, p$scales$scales)
    expect_length(fill_scale, 1L)
  }
})

test_that("the x-axis label carries the catalogue unit (once)", {
  expect_identical(
    lap_plot_distribution(ind, ind_amplitude)$labels$x, "Amplitude (m)"
  )
  # ind_trend_slope -> "Trend slope (m/year)"
  expect_match(
    lap_plot_distribution(ind, ind_trend_slope)$labels$x, "(m/year)", fixed = TRUE
  )
})

test_that("group facets the histogram", {
  ind2 <- ind
  ind2$band <- rep(c("a", "b"), length.out = nrow(ind2))
  p <- lap_plot_distribution(ind2, ind_amplitude, group = band)
  expect_true(inherits(p$facet, "FacetWrap"))
})

test_that("raincloud / dots need ggdist", {
  skip_if(requireNamespace("ggdist", quietly = TRUE))
  expect_error(
    lap_plot_distribution(ind, ind_amplitude, geom = "raincloud"), "ggdist"
  )
})

test_that("raincloud builds when ggdist is available", {
  skip_if_not_installed("ggdist")
  p <- lap_plot_distribution(ind, ind_amplitude, geom = "raincloud")
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))
})

test_that("wrong data shape errors toward the primitive", {
  expect_error(
    lap_plot_distribution(sf::st_sf(a = 1, geometry = sf::st_sfc(sf::st_point(0:1))), a),
    "lap_indicators"
  )
})
