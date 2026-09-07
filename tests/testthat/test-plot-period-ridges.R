skip_if_not_installed("ggplot2")
skip_if_not_installed("scico")

library(ggplot2)

periods <- list(
  early = c(1991, 2000), mid = c(2001, 2010), late = c(2011, 2022)
)
chg <- lap_indicator_change(gems_ger_sample, "amplitude", periods = periods)

test_that("lap_plot_period_ridges draws a gradient ridge per period, earliest on top", {
  skip_if_not_installed("ggridges")
  p <- lap_plot_period_ridges(chg, ind_amplitude)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))

  # one lapidary fill scale, no guide
  fill_scale <- Filter(function(s) "fill" %in% s$aesthetics, p$scales$scales)
  expect_length(fill_scale, 1L)

  # earliest period on top: y break labels run late -> mid -> early bottom-up
  built <- ggplot_build(p)
  y_scale <- built$layout$panel_params[[1]]$y
  expect_identical(y_scale$get_labels(), c("late", "mid", "early"))

  expect_match(p$labels$caption, "ridge", ignore.case = TRUE)
})

test_that("the value axis carries the directional interpretation", {
  skip_if_not_installed("ggridges")
  # ind_amplitude is seeded -> auto directional label with arrows
  auto <- lap_plot_period_ridges(chg, ind_amplitude)$labels$x
  expect_match(auto, "swing")
  expect_match(auto, "Amplitude \\(m\\)")
  expect_true(grepl("\u2190", auto) && grepl("\u2192", auto))

  # explicit override wins, for any column
  ovr <- lap_plot_period_ridges(
    chg, ind_amplitude, low_label = "tiny", high_label = "huge"
  )$labels$x
  expect_match(ovr, "tiny")
  expect_match(ovr, "huge")

  # interpret = FALSE -> plain unit label
  expect_identical(
    lap_plot_period_ridges(chg, ind_amplitude, interpret = FALSE)$labels$x,
    "Amplitude (m)"
  )
})

test_that("period column is required (before the ggridges guard)", {
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
