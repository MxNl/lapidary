#' lapidary options
#'
#' `lapidary` reads a handful of options, each overridable by an environment
#' variable. Options win over environment variables.
#'
#' \describe{
#'   \item{`lapidary.cache_dir` / `LAPIDARY_CACHE_DIR`}{Directory for downloaded
#'     and derived datasets. Defaults to [tools::R_user_dir()].}
#'   \item{`lapidary.lang` / `LAPIDARY_LANG`}{Default language for user-facing
#'     labels, one of `"en"` or `"de"`. Defaults to `"en"`.}
#' }
#'
#' @name lapidary-options
#' @keywords internal
NULL

lap_opt <- function(name, env, default) {
  opt <- getOption(paste0("lapidary.", name))
  if (!is.null(opt)) {
    return(opt)
  }
  ev <- Sys.getenv(env, unset = NA_character_)
  if (!is.na(ev) && nzchar(ev)) {
    return(ev)
  }
  default
}
