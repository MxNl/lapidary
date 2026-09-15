skip_if_not_installed("ggplot2")
skip_if_not_installed("scico")

library(ggplot2)

comp <- local({
  gc <- lap_add_quantile_class(gems_ger_sample[1:1000, ])
  lap_summarise_composition(gc, gwl_class)
})

test_that("lap_plot_stream builds a 100%-stacked area with one lapidary scale", {
  p <- lap_plot_stream(comp, gwl_class, annotate = "caption")
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot_build(p))

  fill_scale <- Filter(function(s) "fill" %in% s$aesthetics, p$scales$scales)
  expect_length(fill_scale, 1L)
  expect_match(p$labels$caption, "100", fixed = TRUE)
})

test_that("border_colour defaults to no outline and is overridable", {
  none <- ggplot_build(lap_plot_stream(comp, gwl_class))$data[[1]]$colour
  expect_true(all(is.na(none)))

  outlined <- ggplot_build(
    lap_plot_stream(comp, gwl_class, border_colour = "white")
  )$data[[1]]$colour
  expect_true(all(outlined == "white"))
})

test_that("the lowest factor level stacks at the bottom", {
  lvl <- factor(c("a", "b", "c"), levels = c("a", "b", "c"), ordered = TRUE)
  df <- data.frame(
    date = rep(as.Date(c("2020-01-06", "2020-01-13")), each = 3),
    cls = rep(lvl, 2),
    n = rep(1, 6)
  )
  p <- lap_plot_stream(df, cls)
  built <- ggplot_build(p)$data[[1]]
  # geom_area pads with zero-height alignment rows at the x extremes; keep
  # only real (non-degenerate) rows, then look at one actual x position
  real <- built[built$ymax > built$ymin, ]
  first_x <- real[real$x == min(real$x), ]
  bottom <- first_x[which.min(first_x$ymin), ]
  top <- first_x[which.max(first_x$ymax), ]
  # group 1 == the first factor level ("a")
  expect_equal(bottom$group, 1)
  expect_equal(top$group, 3)
})

test_that("smooth averages n within each category across x", {
  raw <- lap_plot_stream(comp, gwl_class)
  smoothed <- lap_plot_stream(comp, gwl_class, smooth = 5)
  d1 <- ggplot_build(raw)$data[[1]]$y
  d2 <- ggplot_build(smoothed)$data[[1]]$y
  expect_false(identical(d1, d2))
})

test_that("the legend is reversed to match the stack (low at the bottom of both)", {
  p <- lap_plot_stream(comp, gwl_class)
  fill_scale <- Filter(function(s) "fill" %in% s$aesthetics, p$scales$scales)[[1]]
  expect_true(isTRUE(fill_scale$guide$params$reverse))

  # an explicit guide from the caller is respected, not overridden
  custom <- lap_plot_stream(comp, gwl_class, guide = ggplot2::guide_legend(reverse = FALSE))
  custom_scale <- Filter(function(s) "fill" %in% s$aesthetics, custom$scales$scales)[[1]]
  expect_false(isTRUE(custom_scale$guide$params$reverse))
})

test_that("curve interpolates onto a finer grid; curve = FALSE keeps the raw buckets", {
  literal <- lap_plot_stream(comp, gwl_class, curve = FALSE)
  curved <- lap_plot_stream(comp, gwl_class, curve = TRUE, n_grid = 4000)
  n_literal <- nrow(ggplot_build(literal)$data[[1]])
  n_curved <- nrow(ggplot_build(curved)$data[[1]])
  expect_gt(n_curved, n_literal)
  # still a proper 100%-stack after interpolation: shares sum to 1 at any
  # real (non-padding) x
  built <- ggplot_build(curved)$data[[1]]
  real <- built[built$ymax > built$ymin, ]
  at_one_x <- real[real$x == real$x[[1]], ]
  expect_equal(max(at_one_x$ymax), 1, tolerance = 1e-6)
})

test_that("direction defaults to -1 (reversed palette)", {
  default <- lap_plot_stream(comp, gwl_class, curve = FALSE)
  forward <- lap_plot_stream(comp, gwl_class, curve = FALSE, direction = 1)
  fill_default <- ggplot_build(default)$data[[1]]$fill[[1]]
  fill_forward <- ggplot_build(forward)$data[[1]]$fill[[1]]
  expect_false(identical(fill_default, fill_forward))
})

test_that("a missing n column errors toward lap_summarise_composition", {
  expect_error(
    lap_plot_stream(data.frame(date = Sys.Date(), cls = "a"), cls),
    "lap_summarise_composition"
  )
})
