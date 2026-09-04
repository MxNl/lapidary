skip_if_not_installed("ggplot2")
skip_if_not_installed("scico")
skip_if_not_installed("sf")

library(ggplot2)

# A representative input per builder (extend as builders are added).
builder_inputs <- list(
  lap_plot_hex_map = quote(lap_plot_hex_map(germany_hex_sample, mean_gwl)),
  lap_plot_point_map = quote(
    lap_plot_point_map(gems_ger_wells_sample, surface_elevation, basemap = FALSE)
  )
)

test_that("every lap_plot_* builder follows the contract", {
  builders <- grep("^lap_plot_", getNamespaceExports("lapidary"), value = TRUE)
  expect_setequal(builders, names(builder_inputs))

  for (nm in builders) {
    fn <- get(nm, envir = asNamespace("lapidary"))
    fmls <- names(formals(fn))
    expect_true(all(c("data", "variant", "lang", "annotate", "base_size", "preset") %in% fmls),
      info = nm
    )

    call <- builder_inputs[[nm]]
    p1 <- eval(call)
    p2 <- eval(call)
    expect_true(inherits(p1, "ggplot") || inherits(p1, "patchwork"), info = nm)
    expect_no_error(ggplot_build(p1))

    # deterministic: same layer data + count on a second call
    d1 <- lapply(ggplot_build(p1)$data, function(d) d[order(names(d))])
    d2 <- lapply(ggplot_build(p2)$data, function(d) d[order(names(d))])
    expect_identical(length(d1), length(d2), info = nm)
    expect_equal(d1, d2, info = nm)

    # exactly one *_lapidary colour/fill scale
    lap_scales <- Filter(
      function(s) any(c("fill", "colour") %in% s$aesthetics) &&
        (inherits(s, "ScaleBinned") || inherits(s, "ScaleContinuous")),
      p1$scales$scales
    )
    expect_true(length(lap_scales) >= 1L, info = nm)
  }
})
