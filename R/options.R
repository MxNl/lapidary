#' lapidary options
#'
#' `lapidary` reads a handful of options. Those with an environment-variable
#' counterpart take it as a fallback (the option wins); `lapidary.scale_range`
#' is option-only.
#'
#' \describe{
#'   \item{`lapidary.cache_dir` / `LAPIDARY_CACHE_DIR`}{Directory for downloaded
#'     and derived datasets. Defaults to [tools::R_user_dir()].}
#'   \item{`lapidary.lang` / `LAPIDARY_LANG`}{Default language for user-facing
#'     labels, one of `"en"` or `"de"`. Defaults to `"en"`.}
#'   \item{`lapidary.scale_range`}{Logical, default `FALSE`. When `TRUE` the
#'     continuous `scale_*_lapidary_c()` scales append a mapped `ind_*` column's
#'     theoretical range to the legend title (same as `range = TRUE`).}
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
