#' Register the lapidary fonts
#'
#' Registers the Google fonts used by the lapidary style (Oleo Script for
#' titles, Dosis for everything else) via \pkg{sysfonts} and enables
#' \pkg{showtext}. Safe to call repeatedly. If the fonts or the packages are
#' unavailable (for example on a headless CI machine) it warns once and does
#' nothing, so downstream theme code must always provide fallback families.
#'
#' @param enable_showtext Whether to call [showtext::showtext_auto()].
#' @param quiet Suppress the informational message.
#'
#' @return `TRUE` if the fonts are registered, `FALSE` otherwise (invisibly).
#' @export
#' @examples
#' \dontrun{
#' lap_fonts()
#' }
lap_fonts <- function(enable_showtext = TRUE, quiet = FALSE) {
  if (!requireNamespace("sysfonts", quietly = TRUE) ||
    !requireNamespace("showtext", quietly = TRUE)) {
    if (!quiet) {
      cli::cli_warn("Install {.pkg sysfonts} and {.pkg showtext} to use the lapidary fonts.")
    }
    return(invisible(FALSE))
  }

  fam <- lap_font_families()
  have <- sysfonts::font_families()
  ok <- TRUE
  tryCatch(
    {
      if (!fam$title %in% have) sysfonts::font_add_google("Oleo Script", fam$title)
      if (!fam$body %in% have) sysfonts::font_add_google("Dosis", fam$body)
    },
    error = function(e) {
      ok <<- FALSE
      if (!quiet) {
        cli::cli_warn(c(
          "Could not download the lapidary Google fonts.",
          i = conditionMessage(e),
          i = "Theme code will fall back to {.val serif} / {.val sans}."
        ))
      }
    }
  )

  if (ok && enable_showtext) {
    showtext::showtext_auto()
  }
  invisible(ok)
}
