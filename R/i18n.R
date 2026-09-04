#' Supported interface languages
#'
#' @return A character vector of language codes.
#' @export
#' @examples
#' lap_langs()
lap_langs <- function() {
  c("en", "de")
}

#' Get or set the default label language
#'
#' Resolves the language used by label/caption helpers when `lang` is not given
#' explicitly. Reads the `lapidary.lang` option or `LAPIDARY_LANG` environment
#' variable, falling back to `"en"`.
#'
#' @param lang Optional language code to validate and return. If `NULL` (default)
#'   the configured default is returned.
#'
#' @return A single valid language code.
#' @export
#' @examples
#' lap_lang()
#' old <- options(lapidary.lang = "de")
#' lap_lang()
#' options(old)
lap_lang <- function(lang = NULL) {
  if (is.null(lang)) {
    lang <- lap_opt("lang", "LAPIDARY_LANG", "en")
  }
  lang <- as.character(lang)[[1]]
  if (!lang %in% lap_langs()) {
    cli::cli_abort(c(
      "Unsupported language {.val {lang}}.",
      i = "Supported languages: {.val {lap_langs()}}."
    ))
  }
  lang
}

#' Supported visual variants
#'
#' @return A character vector: `"light"`, `"dark"`.
#' @export
#' @examples
#' lap_variants()
lap_variants <- function() {
  c("light", "dark")
}

#' Get or set the default visual variant
#'
#' Resolves the light/dark variant used by [theme_lapidary()] and the plot
#' builders when `variant` is not given explicitly. Reads the
#' `lapidary.variant` option or `LAPIDARY_VARIANT` environment variable,
#' falling back to `"light"`. The dark-first counterpart of [lap_lang()].
#'
#' @param variant Optional variant to validate and return; `NULL` (default)
#'   returns the configured default.
#'
#' @return A single valid variant string.
#' @export
#' @examples
#' lap_variant()
#' old <- options(lapidary.variant = "dark")
#' lap_variant()
#' options(old)
lap_variant <- function(variant = NULL) {
  if (is.null(variant)) {
    variant <- lap_opt("variant", "LAPIDARY_VARIANT", "light")
  }
  variant <- as.character(variant)[[1]]
  if (!variant %in% lap_variants()) {
    cli::cli_abort(c(
      "Unknown visual variant {.val {variant}}.",
      i = "Variants: {.val {lap_variants()}}."
    ))
  }
  variant
}

# The `lap_labels` string registry lives in R/i18n-labels.R (data only).

#' Translate a registry string
#'
#' Looks up `id` in the `lapidary` string registry and returns the value for
#' `lang`. Simple `{name}` placeholders are filled from `...`.
#'
#' @param id String id present in the registry.
#' @param lang Language code; defaults to [lap_lang()].
#' @param ... Named values substituted into `{placeholder}` tokens.
#'
#' @return A character vector (usually length 1, but e.g. `month_names` is 12).
#' @export
#' @examples
#' lap_tr("app_title", "de")
#' lap_tr("by_author", author = "Max")
lap_tr <- function(id, lang = NULL, ...) {
  lang <- lap_lang(lang)
  entry <- lap_labels[[id]]
  if (is.null(entry)) {
    cli::cli_abort("Unknown label id {.val {id}}.")
  }
  value <- entry[[lang]] %||% entry[["en"]]
  dots <- list(...)
  if (length(dots)) {
    for (nm in names(dots)) {
      value <- gsub(paste0("{", nm, "}"), as.character(dots[[nm]]),
        value,
        fixed = TRUE
      )
    }
  }
  value
}

#' A "how to read this chart" explainer string
#'
#' Looks up `howto_<builder>` in the string registry (see [lap_tr()]) and fills
#' the `{recharge}` / `{discharge}` / `{below}` / `{above}` colour placeholders
#' from the design tokens of `variant`, so the prose colour-matches the plot.
#' The plot builders call this for their default `plot.caption`; call it
#' directly to place the explainer elsewhere.
#'
#' @param builder Builder name without the `lap_plot_` prefix, e.g. `"hex_map"`.
#' @param lang Language code; defaults to [lap_lang()].
#' @param variant `"light"` / `"dark"`; defaults to [lap_variant()].
#' @param ... Further named `{placeholder}` values passed to [lap_tr()].
#'
#' @return A single string (may contain `<span>` markup for \pkg{ggtext}).
#' @export
#' @examples
#' lap_howto("hex_map")
#' lap_howto("hex_map", lang = "de")
lap_howto <- function(builder, lang = NULL, variant = NULL, ...) {
  col <- lap_tokens(lap_variant(variant))$colour
  lap_tr(
    paste0("howto_", builder), lang,
    recharge = col$recharge, discharge = col$discharge,
    below = col$below_reference, above = col$above_reference,
    ...
  )
}
