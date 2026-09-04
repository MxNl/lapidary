# Helpers for the lap_plot_* builder tests.

# Force the serif / sans fallback fonts for the duration of a test, so vdiffr
# snapshots do not depend on whether "Oleo Script" / "Dosis" are registered on
# the host.
local_lapidary_fallback_fonts <- function(env = parent.frame()) {
  testthat::local_mocked_bindings(
    resolve_family = function(family, fallback) fallback,
    .package = "lapidary",
    .env = env
  )
}

# The exported lap_plot_* builders in the lapidary namespace.
lap_plot_builders <- function() {
  ns <- asNamespace("lapidary")
  nms <- grep("^lap_plot_", getNamespaceExports("lapidary"), value = TRUE)
  stats::setNames(lapply(nms, get, envir = ns), nms)
}
