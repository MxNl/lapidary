skip_if_not_installed("ggplot2")
skip_if_not_installed("scico")
skip_if_not_installed("sf")

library(ggplot2)

# A representative call per builder (extend as builders are added).
builder_inputs <- local({
  ind <- lap_indicators(gems_ger_sample, c("amplitude", "memory", "flashiness"))
  chg <- lap_indicator_change(
    gems_ger_sample, "amplitude",
    periods = list(reference = c(1991, 2010), recent = c(2011, 2022))
  )
  dl <- lap_indicator_delta(chg, "reference", "recent")
  hex_dl <- lap_aggregate_to_hex(gems_ger_wells_sample, dl)
  list(
    lap_plot_hex_map = function() lap_plot_hex_map(germany_hex_sample, mean_gwl),
    lap_plot_point_map = function() {
      lap_plot_point_map(gems_ger_wells_sample, surface_elevation, basemap = FALSE)
    },
    lap_plot_distribution = function() lap_plot_distribution(ind, ind_amplitude),
    lap_plot_indicator_scatter = function() {
      lap_plot_indicator_scatter(ind, ind_memory_weeks, ind_flashiness)
    },
    lap_plot_delta_map = function() lap_plot_delta_map(hex_dl, ind_amplitude),
    lap_plot_period_ridges = function() lap_plot_period_ridges(chg, ind_amplitude),
    lap_plot_change_scatter = function() lap_plot_change_scatter(dl, ind_amplitude)
  )
})

# Is a scale one of the *_lapidary colour / fill scales (or a lap_na_guide shape)?
is_lap_scale <- function(s) {
  aes <- s$aesthetics
  if (identical(aes, "shape")) {
    return(TRUE)
  }
  any(c("fill", "colour") %in% aes) &&
    (inherits(s, "ScaleBinned") || inherits(s, "ScaleContinuous"))
}

test_that("every lap_plot_* builder follows the contract", {
  builders <- grep("^lap_plot_", getNamespaceExports("lapidary"), value = TRUE)
  expect_setequal(builders, names(builder_inputs))

  for (nm in builders) {
    fn <- get(nm, envir = asNamespace("lapidary"))
    fmls <- names(formals(fn))
    expect_true(
      all(c("data", "variant", "lang", "annotate", "base_size", "preset") %in% fmls),
      info = nm
    )

    make <- builder_inputs[[nm]]
    p1 <- make()
    p2 <- make()
    expect_true(inherits(p1, "ggplot") || inherits(p1, "patchwork"), info = nm)
    expect_no_error(ggplot_build(p1))

    # deterministic: same layer data on a second call
    d1 <- lapply(ggplot_build(p1)$data, function(d) d[order(names(d))])
    d2 <- lapply(ggplot_build(p2)$data, function(d) d[order(names(d))])
    expect_equal(d1, d2, info = nm)

    # any colour / fill scale present must be a lapidary one
    if (inherits(p1, "ggplot")) {
      col_scales <- Filter(
        function(s) any(c("fill", "colour") %in% s$aesthetics), p1$scales$scales
      )
      if (length(col_scales)) {
        expect_true(all(vapply(col_scales, is_lap_scale, logical(1))), info = nm)
      }
    }
  }
})
