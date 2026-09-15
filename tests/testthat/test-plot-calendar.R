skip_if_not_installed("ggplot2")
skip_if_not_installed("scico")

library(ggplot2)

cal <- local({
  fl <- lap_add_record_flags(gems_ger_sample[1:2000, ])
  lap_summarise_calendar(fl, is_new_min, is_new_max)
})
cal_balance <- local({
  fl <- lap_add_record_flags(gems_ger_sample)
  lap_summarise_calendar(fl, record_balance)
})

test_that("lap_plot_calendar builds a tile grid with one lapidary scale", {
  p <- lap_plot_calendar(cal, n)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))

  fill_scale <- Filter(function(s) "fill" %in% s$aesthetics, p$scales$scales)
  expect_length(fill_scale, 1L)
  expect_s3_class(fill_scale[[1]], "ScaleBinned") # lapidary_c default is binned
})

test_that("facet draws multiple panels sharing the one scale", {
  p <- lap_plot_calendar(cal, n, facet = name)
  expect_s3_class(p$facet, "FacetWrap")
  fill_scale <- Filter(function(s) "fill" %in% s$aesthetics, p$scales$scales)
  expect_length(fill_scale, 1L)
})

test_that("earliest year renders at the top", {
  built <- ggplot_build(lap_plot_calendar(cal, n))
  y_scale <- built$layout$panel_params[[1]]$y
  # ggplot's default discrete axis puts the first level at the bottom, so the
  # top-most (last) label must be the earliest year
  expect_identical(utils::tail(y_scale$get_labels(), 1), as.character(min(cal$year)))
})

test_that("month labels are applied automatically; unit_labels overrides", {
  built <- ggplot_build(lap_plot_calendar(cal, n))
  x_scale <- built$layout$panel_params[[1]]$x
  expect_identical(x_scale$get_labels(), lap_tr("months_short", "en"))

  built_custom <- ggplot_build(lap_plot_calendar(cal, n, unit_labels = month.abb))
  x_custom <- built_custom$layout$panel_params[[1]]$x
  expect_identical(x_custom$get_labels(), month.abb)
})

test_that("border_colour defaults to the background colour and is overridable", {
  default_border <- unique(ggplot_build(lap_plot_calendar(cal, n))$data[[1]]$colour)
  expect_identical(default_border, lap_tokens("light")$colour$background)

  none <- unique(ggplot_build(lap_plot_calendar(cal, n, border_colour = NA))$data[[1]]$colour)
  expect_true(all(is.na(none)))
})

test_that("a single divergent panel works from the record_balance shortcut", {
  p <- lap_plot_calendar(cal_balance, n, role = "anomaly", direction = -1, midpoint = 0, binned = FALSE)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))
  expect_null(p$facet$params$facets %||% NULL) # no faceting - one panel
  expect_true(inherits(p$facet, "FacetNull"))

  fill_scale <- Filter(function(s) "fill" %in% s$aesthetics, p$scales$scales)
  expect_length(fill_scale, 1L)
  # a divergent scale must actually be centred on 0
  expect_equal(fill_scale[[1]]$midpoint %||% fill_scale[[1]]$rescaler(0), 0.5,
    tolerance = 1e-6
  )
})

test_that("binned = FALSE gives value 0 the palette's true neutral colour", {
  # the package's binned-by-default scale has no notion of `midpoint` when it
  # picks its breaks, so 0 can land on a bin edge and inherit a non-neutral
  # bin's colour instead - binned = FALSE is a genuinely continuous gradient
  # and doesn't have that ambiguity
  p <- lap_plot_calendar(cal_balance, n, role = "anomaly", direction = -1, midpoint = 0, binned = FALSE)
  built <- ggplot_build(p)
  fill_at_zero <- unique(built$data[[1]]$fill[p$data$n == 0])
  neutral <- unique(scico::scico(3, palette = "vik", direction = -1))[[2]]
  expect_identical(fill_at_zero, neutral)
})

test_that("wrong data shape errors toward lap_summarise_calendar", {
  expect_error(
    lap_plot_calendar(data.frame(n = 1, month = 1), n),
    "lap_summarise_calendar"
  )
})
