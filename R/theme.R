#' The lapidary ggplot2 theme
#'
#' A minimal, map-friendly theme shared by every lapidary graphic. It strips
#' panel furniture, uses the design-token colours for the chosen `variant` and
#' scales all type sizes from a single `base_size`, so the *same* plot object
#' can be rendered small for the web and large for an A0 poster just by
#' changing `base_size` (see [ggsave_lapidary()], which does this for you).
#'
#' @param variant `"light"` (default) or `"dark"`.
#' @param base_size Base font size in points. Downstream builders typically
#'   leave this at the default and let [ggsave_lapidary()] override it.
#' @param map If `TRUE` (default) also blanks axis text/ticks/grid, which is
#'   what the hex-map builders want; set `FALSE` for time-series panels.
#' @param tokens A token list from [lap_tokens()]; computed from `variant`
#'   if `NULL`.
#'
#' @return A [ggplot2::theme] object.
#' @export
#' @examples
#' \dontrun{
#' library(ggplot2)
#' ggplot(mtcars, aes(mpg, wt)) +
#'   geom_point() +
#'   theme_lapidary(variant = "dark", map = FALSE)
#' }
theme_lapidary <- function(variant = c("light", "dark"),
                           base_size = 11,
                           map = TRUE,
                           tokens = NULL) {
  rlang::check_installed("ggplot2", "for `theme_lapidary()`")
  variant <- rlang::arg_match(variant)
  tk <- tokens %||% lap_tokens(variant)

  fam_title <- resolve_family(tk$font$title, tk$font$fallback_title)
  fam_body <- resolve_family(tk$font$body, tk$font$fallback_body)
  sz <- tk$size
  col <- tk$colour

  base <- ggplot2::theme_minimal(base_size = base_size, base_family = fam_body)

  t <- base + ggplot2::theme(
    text = ggplot2::element_text(colour = col$ink, family = fam_body),
    plot.title = ggplot2::element_text(
      family = fam_title, size = ggplot2::rel(sz$title),
      colour = col$ink, hjust = 0.5,
      margin = ggplot2::margin(b = base_size)
    ),
    plot.subtitle = element_markdown_or_text(
      family = fam_body, size = ggplot2::rel(sz$subtitle),
      colour = col$ink_muted, hjust = 0.5, lineheight = tk$lineheight$subtitle,
      margin = ggplot2::margin(b = base_size)
    ),
    plot.caption = ggplot2::element_text(
      family = fam_body, size = ggplot2::rel(sz$caption),
      colour = col$ink_muted, hjust = 1
    ),
    plot.background = ggplot2::element_rect(fill = col$background, colour = NA),
    panel.background = ggplot2::element_rect(fill = col$panel, colour = NA),
    panel.spacing = ggplot2::unit(tk$spacing$panel, "pt"),
    plot.margin = ggplot2::margin(
      tk$spacing$plot_margin, tk$spacing$plot_margin,
      tk$spacing$plot_margin, tk$spacing$plot_margin
    ),
    legend.title = ggplot2::element_text(
      family = fam_body, size = ggplot2::rel(sz$legend_text), colour = col$ink_muted
    ),
    legend.text = ggplot2::element_text(
      family = fam_body, size = ggplot2::rel(sz$legend_text), colour = col$ink_muted
    ),
    strip.text = ggplot2::element_text(
      family = fam_body, colour = col$ink_muted, size = ggplot2::rel(sz$annotation)
    ),
    axis.title = ggplot2::element_text(
      family = fam_body, size = ggplot2::rel(sz$axis_title), colour = col$ink_muted
    ),
    axis.text = ggplot2::element_text(
      family = fam_body, size = ggplot2::rel(sz$axis_text), colour = col$ink_muted
    )
  )

  if (map) {
    t <- t + ggplot2::theme(
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
    )
  } else {
    t <- t + ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank()
    )
  }
  t
}

# Use ggtext::element_markdown() when available (the subtitles use <span> colour
# spans), else a plain element_text().
element_markdown_or_text <- function(...) {
  if (requireNamespace("ggtext", quietly = TRUE)) {
    ggtext::element_markdown(...)
  } else {
    ggplot2::element_text(...)
  }
}

# Return `family` if registered for the current device, else `fallback`.
resolve_family <- function(family, fallback) {
  registered <- tryCatch(sysfonts::font_families(), error = function(e) character())
  if (family %in% registered) family else fallback
}
