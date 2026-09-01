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

# Central string registry. Keyed by string id; each entry has one field per
# supported language. Extend this list as builders and captions are added.
lap_labels <- list(
  app_title = list(
    en = "Groundwater in Germany",
    de = "Grundwasser in Deutschland"
  ),
  made_in_r = list(
    en = "Made in R",
    de = "Erstellt in R"
  ),
  by_author = list(
    en = "By {author}",
    de = "Von {author}"
  ),
  data_source = list(
    en = "Data: {source}",
    de = "Daten: {source}"
  ),
  months_abbr = list(
    en = c("J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"),
    de = c("J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D")
  ),
  month_names = list(
    en = c(
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ),
    de = c(
      "Januar", "Februar", "M\u00e4rz", "April", "Mai", "Juni",
      "Juli", "August", "September", "Oktober", "November", "Dezember"
    )
  ),
  groundwater_level = list(
    en = "Groundwater level",
    de = "Grundwasserstand"
  ),
  normalised_level = list(
    en = "Normalised groundwater level",
    de = "Normierter Grundwasserstand"
  ),
  year = list(en = "Year", de = "Jahr"),
  trend_per_decade = list(
    en = "Trend (m per decade)",
    de = "Trend (m pro Dekade)"
  ),
  wells_per_hexagon = list(
    en = "Wells per hexagon",
    de = "Messstellen pro Wabe"
  )
)

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
