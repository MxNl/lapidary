# Small deterministic fixtures shared by tests.

# A tidy long groundwater frame: 2 wells, 3 full years of weekly data, with a
# known linear decline in well "a" and a flat series in well "b".
make_ts_fixture <- function(years = 1991:1993) {
  weeks <- do.call(c, lapply(years, function(y) {
    seq(as.Date(paste0(y, "-01-07")), as.Date(paste0(y, "-12-30")), by = "1 week")
  }))
  n <- length(weeks)
  t <- seq_len(n)
  tibble::tibble(
    well_id = rep(c("a", "b"), each = n),
    date = rep(weeks, 2),
    gwl = c(
      100 - 0.02 * t + sin(2 * pi * t / 52), # declining + seasonal
      50 + sin(2 * pi * t / 52) # flat + seasonal
    ),
    variable = "gwl_m_asl",
    source = "fixture"
  )
}

# Path to the packaged raw GEMS-GER-shaped mini CSVs.
gems_fixture_dir <- function() {
  testthat::test_path("fixtures", "gems-ger")
}
