# Shared design tokens ------------------------------------------------------
#
# A single source of truth for the colours, fonts, sizes and spacing that make
# lapidary graphics look like one family, in a light and a dark variant. These
# feed `theme_lapidary()`, the `scale_*_lapidary()` helpers and (from milestone
# 2) the plot builders. The values are ported from the `playground.R`
# prototype.

#' lapidary design tokens
#'
#' Returns a nested list of design tokens for one visual `variant`. Downstream
#' code should read tokens through this function rather than hard-coding
#' values, so that a restyle happens in one place.
#'
#' @param variant `"light"` (default) or `"dark"`.
#'
#' @return A list with elements `variant`, `colour` (named colours), `font`
#'   (family names + a logical `available`), `size` (type sizes, relative to a
#'   base size of 1), `spacing` and `effect` (e.g. shadow sigma).
#' @export
#' @examples
#' lap_tokens()$colour$recharge
#' lap_tokens("dark")$colour$panel
lap_tokens <- function(variant = c("light", "dark")) {
  variant <- rlang::arg_match(variant)

  common <- list(
    recharge = "#506ea7",
    discharge = "#b38435",
    below_reference = "#ff3d7f",
    above_reference = "#3fb8af",
    missing = "grey90"
  )

  colour <- if (variant == "dark") {
    c(common, list(
      panel = "#040720",
      background = "#040720",
      ink = "white",
      ink_muted = "grey70",
      endpoint = "white",
      grid = "grey30"
    ))
  } else {
    c(common, list(
      panel = "#ffffff",
      background = "#ffffff",
      ink = "grey15",
      ink_muted = "grey40",
      endpoint = "#040720",
      grid = "grey85"
    ))
  }

  fonts <- lap_font_families()

  list(
    variant = variant,
    colour = colour,
    font = fonts,
    # Sizes as multipliers of the theme `base_size`.
    size = list(
      title = 2.6,
      subtitle = 1.2,
      caption = 0.8,
      axis_title = 1.0,
      axis_text = 0.85,
      legend_text = 0.85,
      annotation = 0.9
    ),
    spacing = list(
      panel = 0,
      plot_margin = 0,
      legend_key = 3
    ),
    effect = list(
      shadow_sigma = 12,
      shadow_colour = if (variant == "dark") "black" else "grey60",
      shadow_offset = 3
    ),
    lineheight = list(subtitle = 1.05)
  )
}

#' Font family names used by lapidary
#'
#' @return A list with `title`, `subtitle`/`body` family names and a logical
#'   `available` flag (whether the families are registered for the current
#'   graphics device; see [lap_fonts()]).
#' @export
lap_font_families <- function() {
  title <- "Oleo Script"
  body <- "Dosis"
  registered <- tryCatch(sysfonts::font_families(), error = function(e) character())
  list(
    title = title,
    subtitle = body,
    body = body,
    fallback_title = "serif",
    fallback_body = "sans",
    available = all(c(title, body) %in% registered)
  )
}
