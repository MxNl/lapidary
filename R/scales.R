# Colour + fill scales ------------------------------------------------------
#
# Thin, stably-named wrappers around scico palettes so builders (and users)
# refer to a *role* ("months", "magnitude", "divergent") rather than a palette
# name that might change.

lap_palettes <- list(
  # cyclic - month-of-year / phase
  months = "romaO",
  # sequential - a magnitude / duration
  magnitude = "lapaz",
  magnitude_dark = "batlowK",
  # sequential - counts / density
  density = "grayC",
  # divergent - anomaly vs a reference
  anomaly = "vik"
)

#' Names of the lapidary palette roles
#' @return A character vector.
#' @export
lap_pal_roles <- function() names(lap_palettes)

resolve_palette <- function(role) {
  pal <- lap_palettes[[role]]
  if (is.null(pal)) {
    cli::cli_abort(c(
      "Unknown palette role {.val {role}}.",
      i = "Roles: {.val {lap_pal_roles()}}."
    ))
  }
  pal
}

#' lapidary continuous fill / colour scales
#'
#' `role` selects a scico palette by its purpose:
#' `"months"` (cyclic), `"magnitude"`/`"magnitude_dark"` (sequential),
#' `"density"` (sequential greys), `"anomaly"` (divergent).
#'
#' @param role One of [lap_pal_roles()].
#' @param ... Passed to [scico::scale_fill_scico()] /
#'   [scico::scale_colour_scico()] (e.g. `limits`, `direction`, `na.value`).
#' @param na.value Colour for `NA`. Defaults to the token `missing` colour.
#'
#' @return A ggplot2 scale.
#' @name scale_lapidary
#' @examples
#' \dontrun{
#' library(ggplot2)
#' ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
#'   geom_raster() +
#'   scale_fill_lapidary_c("magnitude")
#' }
NULL

#' @rdname scale_lapidary
#' @export
scale_fill_lapidary_c <- function(role = "magnitude", ...,
                                  na.value = lap_tokens()$colour$missing) {
  rlang::check_installed("scico", "for the lapidary scales")
  scico::scale_fill_scico(palette = resolve_palette(role), na.value = na.value, ...)
}

#' @rdname scale_lapidary
#' @export
scale_colour_lapidary_c <- function(role = "magnitude", ...,
                                    na.value = lap_tokens()$colour$missing) {
  rlang::check_installed("scico", "for the lapidary scales")
  scico::scale_colour_scico(palette = resolve_palette(role), na.value = na.value, ...)
}

#' @rdname scale_lapidary
#' @export
scale_color_lapidary_c <- scale_colour_lapidary_c

#' @rdname scale_lapidary
#' @export
scale_fill_lapidary_d <- function(role = "magnitude", ...,
                                  na.value = lap_tokens()$colour$missing) {
  rlang::check_installed("scico", "for the lapidary scales")
  scico::scale_fill_scico_d(palette = resolve_palette(role), na.value = na.value, ...)
}

#' @rdname scale_lapidary
#' @export
scale_colour_lapidary_d <- function(role = "magnitude", ...,
                                    na.value = lap_tokens()$colour$missing) {
  rlang::check_installed("scico", "for the lapidary scales")
  scico::scale_colour_scico_d(palette = resolve_palette(role), na.value = na.value, ...)
}

#' @rdname scale_lapidary
#' @export
scale_color_lapidary_d <- scale_colour_lapidary_d

#' A named vector of the semantic accent colours
#'
#' Handy for `scale_*_manual()` when mapping e.g. recharge vs discharge.
#'
#' @param variant `"light"` or `"dark"`.
#' @return A named character vector.
#' @export
lap_accents <- function(variant = c("light", "dark")) {
  col <- lap_tokens(rlang::arg_match(variant))$colour
  c(
    recharge = col$recharge,
    discharge = col$discharge,
    below_reference = col$below_reference,
    above_reference = col$above_reference
  )
}
