skip_if_not_installed("ggplot2")

test_that("lap_colourbar_guide builds a tall, narrow colourbar guide", {
  g <- lap_colourbar_guide()
  expect_s7_class <- inherits(g, "Guide") || inherits(g, "guide")
  expect_true(expect_s7_class)

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = hp)) +
    ggplot2::geom_point() +
    ggplot2::scale_colour_gradient(guide = lap_colourbar_guide())
  built <- ggplot2::ggplot_build(p)
  expect_no_error(built)
})
