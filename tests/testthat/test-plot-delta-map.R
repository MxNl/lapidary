skip_if_not_installed("ggplot2")
skip_if_not_installed("scico")
skip_if_not_installed("sf")

library(ggplot2)

periods <- list(reference = c(1991, 2010), recent = c(2011, 2022))
chg <- lap_indicator_change(gems_ger_sample, c("amplitude", "trend"), periods = periods)
dl <- lap_indicator_delta(chg, "reference", "recent")
hex_dl <- lap_aggregate_to_hex(gems_ger_wells_sample, dl)

test_that("display = 'change' is a divergent choropleth of the _change column", {
  p <- lap_plot_delta_map(hex_dl, ind_amplitude)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))

  fill_scale <- Filter(function(s) "fill" %in% s$aesthetics, p$scales$scales)
  expect_length(fill_scale, 1L)
  expect_s3_class(fill_scale[[1]], "ScaleBinned")
  # the mapped column is the _change one (built layer carries its values)
  built <- ggplot_build(p)$data[[length(ggplot_build(p)$data)]]
  expect_true("fill" %in% names(built))
  expect_match(p$labels$fill, "Amplitude")
  expect_match(p$labels$caption, "change", ignore.case = TRUE)
})

test_that("display = 'paired' returns a shared-scale patchwork", {
  skip_if_not_installed("patchwork")
  p <- lap_plot_delta_map(hex_dl, ind_amplitude, display = "paired")
  expect_s3_class(p, "patchwork")
  expect_no_error(ggplot2::ggplot_build(p[[1]]))
  expect_no_error(ggplot2::ggplot_build(p[[2]]))
})

test_that("display = 'arrow' draws one glyph per non-NA hexagon", {
  p <- lap_plot_delta_map(hex_dl, ind_amplitude, display = "arrow")
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))
  colour_scale <- Filter(function(s) "colour" %in% s$aesthetics, p$scales$scales)
  expect_length(colour_scale, 1L)
})

test_that("a 'none' delta_kind column errors toward lap_indicator_delta", {
  expect_error(
    lap_plot_delta_map(hex_dl, ind_trend_p_value),
    "delta_kind|lap_indicator_delta"
  )
})

test_that("wrong data shape errors toward the hex primitive", {
  expect_error(lap_plot_delta_map(dl, ind_amplitude), "lap_aggregate_to_hex")
})

test_that("margin attaches a marginal for display = 'change'", {
  skip_if_not_installed("patchwork")
  p <- lap_plot_delta_map(hex_dl, ind_amplitude, margin = "histogram")
  expect_s3_class(p, "patchwork")
})

# --- lap_plot_change_scatter -------------------------------------------------

test_that("lap_plot_change_scatter plots the start value against the change", {
  p <- lap_plot_change_scatter(dl, ind_amplitude)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))
  # x = starting value, y = change
  expect_match(p$labels$x, "reference", ignore.case = TRUE)
  expect_match(p$labels$y, "change", ignore.case = TRUE)
  # divergent colour scale + smooth + zero line
  colour_scale <- Filter(function(s) "colour" %in% s$aesthetics, p$scales$scales)
  expect_length(colour_scale, 1L)
  expect_gte(length(p$layers), 3L)
})

test_that("change_scatter axis labels carry the unit", {
  p <- lap_plot_change_scatter(dl, ind_amplitude)
  expect_match(p$labels$x, "(m)", fixed = TRUE)
  expect_match(p$labels$y, "change", ignore.case = TRUE)
})
