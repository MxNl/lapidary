skip_if_not_installed("ggplot2")
skip_if_not_installed("scico")
skip_if_not_installed("sf")

library(ggplot2)

ind <- lap_indicators(gems_ger_sample, c("memory", "flashiness", "amplitude"))

test_that("lap_plot_indicator_scatter builds with and without a colour column", {
  bare <- lap_plot_indicator_scatter(ind, ind_memory_weeks, ind_flashiness)
  expect_s3_class(bare, "ggplot")
  expect_no_error(ggplot_build(bare))
  # no colour -> no colour scale
  expect_length(
    Filter(function(s) "colour" %in% s$aesthetics, bare$scales$scales), 0L
  )

  coloured <- lap_plot_indicator_scatter(
    ind, ind_memory_weeks, ind_flashiness, colour = ind_amplitude, smooth = TRUE
  )
  expect_length(
    Filter(function(s) "colour" %in% s$aesthetics, coloured$scales$scales), 1L
  )
  # smooth adds a second layer
  expect_gte(length(coloured$layers), 2L)
})

test_that("scatter axis labels are prettified with units, no duplication", {
  p <- lap_plot_indicator_scatter(ind, ind_memory_weeks, ind_flashiness)
  expect_identical(p$labels$x, "Memory weeks") # not "Memory weeks (weeks)"
  expect_identical(p$labels$y, "Flashiness") # unitless
})

test_that("lap_attach_margin returns a patchwork sharing the fill scale", {
  skip_if_not_installed("patchwork")
  m <- lap_plot_hex_map(germany_hex_sample, mean_gwl)
  pw <- lap_attach_margin(m, germany_hex_sample, dplyr::all_of("mean_gwl"),
    type = "histogram"
  )
  expect_s3_class(pw, "patchwork")
  expect_no_error(ggplot2::ggplot_build(pw[[2]])) # the marginal
})

test_that("lap_plot_hex_map(margin =) returns a patchwork", {
  skip_if_not_installed("patchwork")
  p <- lap_plot_hex_map(germany_hex_sample, mean_gwl, margin = "density")
  expect_s3_class(p, "patchwork")

  # a month column is exempt (returns a plain ggplot)
  hex <- germany_hex_sample
  hex$ind_max_month <- (seq_len(nrow(hex)) %% 12) + 1
  expect_s3_class(
    lap_plot_hex_map(hex, ind_max_month, margin = "histogram"), "ggplot"
  )
})
