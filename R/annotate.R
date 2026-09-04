# "How to read this chart" annotations (see docs/adr/0012). ----------------

#' Add a "how to read this chart" explainer to a plot
#'
#' Places a short explainer either in `plot.caption` (default) or as an
#' on-panel corner box. The [lap_plot_map] builders call this for their default
#' `annotate = "caption"`; call it directly to override placement or add an
#' explainer to a plot the builders did not make.
#'
#' @param plot A ggplot object.
#' @param key Builder name without the `lap_plot_` prefix (e.g. `"hex_map"`),
#'   used to look up the registry string. Ignored if `text` is given.
#' @param text Explainer text (may contain `<span>` markup for \pkg{ggtext}).
#'   `NULL` (default) uses `lap_howto(key)`.
#' @param placement `"caption"` (append to `plot.caption`) or `"callout"` (an
#'   on-panel box).
#' @param corner For `"callout"`: which corner. One of `"bottom-right"`
#'   (default), `"bottom-left"`, `"top-right"`, `"top-left"`.
#' @param lang,variant Passed to [lap_howto()] when `text` is `NULL`.
#' @param tokens A [lap_tokens()] list; computed from `variant` if `NULL`.
#'
#' @return `plot` with the annotation added.
#' @seealso [lap_howto()], [lap_plot_map]
#' @export
#' @examples
#' \dontrun{
#' library(ggplot2)
#' data(germany_hex_sample, package = "lapidary")
#' lap_plot_hex_map(germany_hex_sample, mean_gwl, annotate = NA) |>
#'   lap_annotate_howto("hex_map", placement = "callout")
#' }
lap_annotate_howto <- function(plot, key = NULL, text = NULL,
                               placement = c("caption", "callout"),
                               corner = c(
                                 "bottom-right", "bottom-left",
                                 "top-right", "top-left"
                               ),
                               lang = NULL, variant = NULL, tokens = NULL) {
  rlang::check_installed("ggplot2", "for `lap_annotate_howto()`")
  if (!inherits(plot, "ggplot")) {
    cli::cli_abort("{.arg plot} must be a {.cls ggplot} object.")
  }
  placement <- rlang::arg_match(placement)
  corner <- rlang::arg_match(corner)
  tk <- tokens %||% lap_tokens(lap_variant(variant))
  text <- text %||% lap_howto(key, lang = lang, variant = variant)

  if (placement == "caption") {
    prev <- plot$labels$caption
    keep <- !is.null(prev) && !inherits(prev, "waiver") && nzchar(prev)
    plot <- plot +
      ggplot2::labs(caption = if (keep) paste0(prev, "\n", text) else text) +
      ggplot2::theme(plot.caption = howto_caption_element(tk))
    return(plot)
  }

  # callout: a translucent richtext box pinned to a panel corner
  rlang::check_installed("ggtext", "for `placement = \"callout\"`")
  x <- if (grepl("left", corner)) -Inf else Inf
  y <- if (grepl("top", corner)) Inf else -Inf
  plot + ggtext::geom_richtext(
    data = data.frame(x = x, y = y, .howto = text),
    mapping = ggplot2::aes(x = .data$x, y = .data$y, label = .data$.howto),
    inherit.aes = FALSE,
    hjust = if (grepl("left", corner)) 0 else 1,
    vjust = if (grepl("top", corner)) 1 else 0,
    size = 3, lineheight = 1.25,
    colour = tk$colour$ink_muted,
    fill = scales::alpha(tk$colour$panel, 0.82),
    label.colour = NA, label.r = grid::unit(2, "pt"),
    label.padding = grid::unit(rep(4, 4), "pt")
  )
}
