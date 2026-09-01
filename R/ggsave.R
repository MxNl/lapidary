# Output size / dpi presets -------------------------------------------------

lap_presets <- list(
  web = list(width = 20, height = 15, units = "cm", dpi = 96, base_size = 11),
  web_wide = list(width = 30, height = 15, units = "cm", dpi = 96, base_size = 11),
  a4 = list(width = 21.0, height = 29.7, units = "cm", dpi = 300, base_size = 10),
  a3 = list(width = 29.7, height = 42.0, units = "cm", dpi = 300, base_size = 12),
  a2 = list(width = 42.0, height = 59.4, units = "cm", dpi = 300, base_size = 16),
  a1 = list(width = 59.4, height = 84.1, units = "cm", dpi = 300, base_size = 22),
  a0 = list(width = 84.1, height = 118.9, units = "cm", dpi = 300, base_size = 30)
)

#' Output presets for lapidary graphics
#' @return A character vector of preset names.
#' @export
lap_preset_names <- function() names(lap_presets)

#' Look up an output preset
#'
#' @param preset A name from [lap_preset_names()].
#' @return A list with `width`, `height`, `units`, `dpi`, `base_size`.
#' @export
lap_preset <- function(preset = "web") {
  p <- lap_presets[[preset]]
  if (is.null(p)) {
    cli::cli_abort(c(
      "Unknown preset {.val {preset}}.",
      i = "Presets: {.val {lap_preset_names()}}."
    ))
  }
  p
}

#' Save a lapidary plot at a named size preset
#'
#' Wraps [ggplot2::ggsave()] with the poster/web size + dpi presets and,
#' crucially, sets `showtext`'s DPI to match so text metrics are correct in
#' print output (the recurring gotcha in the prototype). Uses the \pkg{ragg}
#' PNG device when available for crisper text.
#'
#' This does **not** re-theme the plot; build the plot with
#' `theme_lapidary(base_size = lap_preset(preset)$base_size)` (the
#' milestone-2 builders take a `preset`/`base_size` argument that does this).
#'
#' @param plot A ggplot (or patchwork) object.
#' @param filename Output path. The device is inferred from the extension
#'   (`.png`, `.pdf`, ...).
#' @param preset A name from [lap_preset_names()].
#' @param ... Overrides passed to [ggplot2::ggsave()] (`width`, `height`,
#'   `dpi`, ...).
#'
#' @return `filename`, invisibly.
#' @export
ggsave_lapidary <- function(plot, filename, preset = "web", ...) {
  rlang::check_installed("ggplot2", "for `ggsave_lapidary()`")
  p <- utils::modifyList(lap_preset(preset), list(...))
  is_pdf <- grepl("\\.pdf$", filename, ignore.case = TRUE)

  if (requireNamespace("showtext", quietly = TRUE)) {
    old <- showtext::showtext_opts(dpi = p$dpi)
    on.exit(showtext::showtext_opts(old), add = TRUE)
  }

  args <- list(
    filename = filename, plot = plot,
    width = p$width, height = p$height, units = p$units, dpi = p$dpi
  )
  if (!is_pdf && requireNamespace("ragg", quietly = TRUE) &&
    grepl("\\.png$", filename, ignore.case = TRUE)) {
    args$device <- ragg::agg_png
  }
  do.call(ggplot2::ggsave, args)
  cli::cli_alert_success("Wrote {.path {filename}} ({p$width}x{p$height} {p$units} @ {p$dpi} dpi).")
  invisible(filename)
}
