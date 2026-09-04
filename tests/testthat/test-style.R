test_that("lap_tokens returns coherent light and dark variants", {
  lt <- lap_tokens("light")
  dk <- lap_tokens("dark")
  expect_equal(lt$variant, "light")
  expect_equal(dk$colour$panel, "#040720")
  expect_identical(lt$colour$recharge, dk$colour$recharge)
  expect_true(all(c("title", "subtitle", "caption") %in% names(lt$size)))
})

test_that("palette roles resolve and reject unknown names", {
  expect_true(all(c("months", "magnitude", "anomaly") %in% lap_pal_roles()))
  expect_error(lapidary:::resolve_palette("bogus"), "Unknown palette role")
})

test_that("preset lookup works and errors on unknown", {
  p <- lap_preset("a1")
  expect_equal(p$dpi, 300)
  expect_true(p$width > 0 && p$height > 0)
  expect_error(lap_preset("a99"), "Unknown preset")
})

test_that("theme_lapidary builds for both variants and modes", {
  skip_if_not_installed("ggplot2")
  expect_s3_class(theme_lapidary("light", map = TRUE), "theme")
  expect_s3_class(theme_lapidary("dark", base_size = 40, map = FALSE), "theme")
})

test_that("scale + theme render without a font/dpi error at web and a1", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  library(ggplot2)
  p <- ggplot(data.frame(x = 1:10, y = 1:10, z = 1:10), aes(x, y, colour = z)) +
    geom_point() +
    scale_colour_lapidary_c("magnitude") +
    theme_lapidary(map = FALSE)
  for (preset in c("web", "a1")) {
    f <- withr::local_tempfile(fileext = ".png")
    expect_no_error(ggsave_lapidary(p, f, preset = preset))
    expect_true(file.exists(f))
  }
})

test_that("lap_prettify_label cleans variable names and passes non-strings through", {
  expect_equal(
    lap_prettify_label(c("mean_gwl", "ind_trend_slope", "ind_climate_cc", "n_wells")),
    c("Mean GWL", "Trend slope", "Climate CC", "N wells")
  )
  expect_identical(lap_prettify_label(NA_character_), NA_character_)
  expect_identical(lap_prettify_label(ggplot2::waiver()), ggplot2::waiver())
})

test_that("scale_*_lapidary_c is binned with a prettified title, or smooth on demand", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  binned <- scale_fill_lapidary_c("magnitude")
  expect_s3_class(binned, "ScaleBinned")
  # the `name` function turns the auto label into a readable title
  expect_equal(binned$make_title(ggplot2::waiver(), binned$name, "mean_gwl"), "Mean GWL")

  smooth <- scale_fill_lapidary_c("magnitude", binned = FALSE)
  expect_false(inherits(smooth, "ScaleBinned"))

  # an explicit name wins over the prettifier
  expect_equal(
    scale_fill_lapidary_c("magnitude", name = "Custom")$make_title(
      ggplot2::waiver(), "Custom", "mean_gwl"
    ),
    "Custom"
  )
})

test_that("lap_na_guide adds a second legend and the plot still renders", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  library(ggplot2)
  d <- data.frame(x = 1:6, y = 1, z = c(NA, NA, 1, 2, 3, 4))
  p <- ggplot(d, aes(x, y, fill = z)) +
    geom_tile() +
    scale_fill_lapidary_c("magnitude") +
    lap_na_guide(label = "no data") +
    theme_lapidary(map = FALSE)
  f <- withr::local_tempfile(fileext = ".png")
  expect_no_error(suppressWarnings(ggsave_lapidary(p, f, preset = "web")))
  expect_true(file.exists(f))
  aes_mapped <- unlist(lapply(p$scales$scales, function(s) s$aesthetics))
  expect_true(all(c("fill", "shape") %in% aes_mapped)) # dummy shape scale added
})

test_that("lap_format_range swaps ASCII Inf / minus for real glyphs", {
  minus_inf <- "(−∞, 0]"
  expect_identical(lap_format_range("(-Inf, 0]"), minus_inf)
  expect_identical(lap_format_range("[1, Inf)"), "[1, ∞)")
  expect_identical(lap_format_range("[-1, 1]"), "[−1, 1]")
  expect_identical(lap_format_range("[0, 1]"), "[0, 1]")
  expect_identical(lap_format_range(NA_character_), NA_character_)
})

test_that("scale_*_lapidary_c can append an indicator range to the legend title", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  inf <- "∞"
  w <- ggplot2::waiver()

  on <- scale_fill_lapidary_c("magnitude", range = TRUE)
  ttl <- on$make_title(w, on$name, "ind_trend_slope")
  expect_match(ttl, "Trend slope", fixed = TRUE)
  expect_match(ttl, inf, fixed = TRUE)

  off <- scale_fill_lapidary_c("magnitude")
  expect_identical(off$make_title(w, off$name, "ind_trend_slope"), "Trend slope")

  # unknown variable -> no range, just the prettified name
  expect_identical(on$make_title(w, on$name, "mean_gwl"), "Mean GWL")

  # explicit string name wins, no range
  ex <- scale_fill_lapidary_c("magnitude", name = "Custom", range = TRUE)
  expect_identical(ex$make_title(w, ex$name, "ind_trend_slope"), "Custom")

  # smooth (binned = FALSE) path also appends
  sm <- scale_fill_lapidary_c("magnitude", binned = FALSE, range = TRUE)
  expect_match(
    sm$make_title(w, sm$name, "ind_seasonality_strength"), "[0, 1]",
    fixed = TRUE
  )

  # the option flips the default
  withr::local_options(lapidary.scale_range = TRUE)
  opt <- scale_fill_lapidary_c("magnitude")
  expect_match(opt$make_title(w, opt$name, "ind_trend_slope"), inf, fixed = TRUE)
})

# --- robust (outlier-squishing) limits --------------------------------

test_that("resolve_robust_probs maps the robust argument", {
  rr <- function(x) lapidary:::resolve_robust_probs(x)
  expect_null(rr(FALSE))
  expect_null(rr(NULL))
  expect_equal(rr(TRUE), c(0.02, 0.98))
  expect_equal(rr(0.9), c(0.1, 0.9))
  expect_equal(rr(c(0.05, 0.95)), c(0.05, 0.95))
  expect_equal(rr(c(0.95, 0.05)), c(0.05, 0.95))
  expect_error(rr(0.4), "between 0.5 and 1")
  expect_error(rr(1.2), "between 0.5 and 1")
  expect_error(rr("x"), "must be")
  expect_error(rr(c(0.1, 0.2, 0.3)), "length")
  expect_error(rr(c(-0.1, 0.9)), "0 <= lo < hi")
})

test_that("lap_robust_limits clips to percentiles, symmetric about a midpoint", {
  set.seed(1)
  v <- c(rnorm(200), 50)
  expect_equal(
    lapidary:::lap_robust_limits(v, c(0.1, 0.9)),
    unname(stats::quantile(v, c(0.1, 0.9), type = 7))
  )
  expect_equal(mean(lapidary:::lap_robust_limits(v, c(0.1, 0.9), midpoint = 0)), 0)
})

test_that("robust binned scale tightens limits and marks the clipped end", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  library(ggplot2)
  set.seed(1)
  d <- data.frame(x = seq_len(101), y = 1, z = c(rnorm(100), 50))
  p <- ggplot(d, aes(x, y, fill = z)) +
    geom_tile() +
    scale_fill_lapidary_c("magnitude", robust = 0.9)
  b <- ggplot_build(p)
  s <- b$plot$scales$scales[[1]]
  expect_s3_class(s, "LapScaleBinnedRobust")
  lim <- s$get_limits()
  expect_lt(lim[[2]], 5) # nowhere near the 50 outlier
  expect_equal(lim, unname(stats::quantile(d$z, c(0.1, 0.9), type = 7)), tolerance = 0.5)

  labs <- get_guide_data(b, "fill")$.label
  expect_match(labs[[length(labs)]], "^≥ ")
  expect_false(any(grepl("≥", labs[-length(labs)])))

  ld <- layer_data(p)
  expect_equal(sum(is.na(ld$fill)), 0L)
  expect_identical(ld$fill[[101]], ld$fill[[which.max(d$z[d$z < 10])]])
})

test_that("robust marking is silent when nothing is clipped / when off", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  library(ggplot2)
  set.seed(1)
  d <- data.frame(x = seq_len(60), y = 1, z = c(rnorm(59), 20))
  b <- ggplot_build(
    ggplot(d, aes(x, y, fill = z)) + geom_tile() +
      scale_fill_lapidary_c("magnitude", robust = c(0, 1))
  )
  expect_false(any(grepl("≤|≥", get_guide_data(b, "fill")$.label)))

  off <- scale_fill_lapidary_c("magnitude")
  false <- scale_fill_lapidary_c("magnitude", robust = FALSE)
  expect_false(inherits(false, "LapScaleBinnedRobust"))
  expect_identical(class(off), class(false))
})

test_that("an explicit limits wins over robust", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  library(ggplot2)
  set.seed(1)
  d <- data.frame(x = seq_len(101), y = 1, z = c(rnorm(100), 50))
  b <- ggplot_build(
    ggplot(d, aes(x, y, fill = z)) + geom_tile() +
      scale_fill_lapidary_c("magnitude", robust = 0.9, limits = c(-4, 60))
  )
  s <- b$plot$scales$scales[[1]]
  expect_equal(s$get_limits(), c(-4, 60))
  expect_false(any(grepl("≤|≥", get_guide_data(b, "fill")$.label)))
})

test_that("robust re-print is stable (reset clears accumulated values)", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  library(ggplot2)
  set.seed(1)
  d <- data.frame(x = seq_len(101), y = 1, z = c(rnorm(100), 50))
  p <- ggplot(d, aes(x, y, fill = z)) + geom_tile() +
    scale_fill_lapidary_c("magnitude", robust = 0.9)
  l1 <- get_guide_data(ggplot_build(p), "fill")$.label
  l2 <- get_guide_data(ggplot_build(p), "fill")$.label
  l3 <- get_guide_data(ggplot_build(p), "fill")$.label
  expect_identical(l1, l2)
  expect_identical(l2, l3)
})

test_that("lapidary.scale_robust option sets the default", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  withr::local_options(lapidary.scale_robust = 0.9)
  s <- scale_fill_lapidary_c("magnitude")
  expect_s3_class(s, "LapScaleBinnedRobust")
  expect_equal(s$lap_probs, c(0.1, 0.9))
})

test_that("robust divergent scale keeps the midpoint centred", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  library(ggplot2)
  set.seed(1)
  d <- data.frame(x = seq_len(122), y = 1, z = c(rnorm(120), -30, 40))
  b <- ggplot_build(
    ggplot(d, aes(x, y, fill = z)) + geom_tile() +
      scale_fill_lapidary_c("anomaly", midpoint = 0, robust = c(0.05, 0.95))
  )
  lim <- b$plot$scales$scales[[1]]$get_limits()
  expect_equal(mean(lim), 0, tolerance = 1e-8)
  expect_equal(sum(is.na(layer_data(b$plot)$fill)), 0L)
})

test_that("robust smooth path squishes without a glyph", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scico")
  library(ggplot2)
  set.seed(1)
  d <- data.frame(x = seq_len(101), y = 1, z = c(rnorm(100), 50))
  p <- ggplot(d, aes(x, y, fill = z)) + geom_tile() +
    scale_fill_lapidary_c("magnitude", binned = FALSE, robust = 0.9)
  s <- ggplot_build(p)$plot$scales$scales[[1]]
  expect_s3_class(s, "LapScaleContinuousRobust")
  expect_lt(s$get_limits()[[2]], 5)
  expect_equal(sum(is.na(layer_data(p)$fill)), 0L)
})
