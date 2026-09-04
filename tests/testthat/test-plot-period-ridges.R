skip_if_not_installed("ggplot2")
skip_if_not_installed("scico")

library(ggplot2)

periods <- list(
  early = c(1991, 2000), mid = c(2001, 2010), late = c(2011, 2022)
)
chg <- lap_indicator_change(gems_ger_sample, "amplitude", periods = periods)

test_that("lap_plot_period_ridges draws one filled ridge per period", {
  p <- lap_plot_period_ridges(chg, ind_amplitude)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))

  # one lapidary fill scale, no guide
  fill_scale <- Filter(function(s) "fill" %in% s$aesthetics, p$scales$scales)
  expect_length(fill_scale, 1L)

  # y breaks are labelled with the period levels, in order
  built <- ggplot_build(p)
  y_scale <- built$layout$panel_params[[1]]$y
  expect_setequal(y_scale$get_labels(), c("early", "mid", "late"))

  # x axis carries the unit
  expect_identical(p$labels$x, "Amplitude (m)")
  expect_match(p$labels$caption, "ridge", ignore.case = TRUE)
})

test_that("period column is required", {
  expect_error(
    lap_plot_period_ridges(lap_indicators(gems_ger_sample, "amplitude"), ind_amplitude),
    "period"
  )
})

test_that("wrong data shape errors toward the primitive", {
  skip_if_not_installed("sf")
  expect_error(
    lap_plot_period_ridges(
      sf::st_sf(period = "a", ind_amplitude = 1, geometry = sf::st_sfc(sf::st_point(0:1))),
      ind_amplitude
    ),
    "lap_indicators|data frame"
  )
})
