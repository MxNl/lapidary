#' lapidary cache directory
#'
#' Location for downloaded source datasets and derived artifacts (Parquet
#' trees, DuckDB files). Controlled by the `lapidary.cache_dir` option or the
#' `LAPIDARY_CACHE_DIR` environment variable; otherwise a per-user cache
#' directory from [tools::R_user_dir()].
#'
#' @param ... Optional path components appended to the cache directory with
#'   [file.path()].
#' @param create Whether to create the directory (and requested subpath) if it
#'   does not yet exist.
#'
#' @return A normalised absolute path (character scalar).
#' @export
#' @examples
#' lap_cache_dir(create = FALSE)
lap_cache_dir <- function(..., create = FALSE) {
  root <- lap_opt("cache_dir", "LAPIDARY_CACHE_DIR",
    default = tools::R_user_dir("lapidary", which = "cache")
  )
  path <- if (...length()) file.path(root, ...) else root
  if (create && !dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  path
}

#' Path to a source dataset inside the cache
#'
#' @param source Dataset key, e.g. `"gems-ger"`.
#' @param ... Further path components.
#' @param create Passed to [lap_cache_dir()].
#'
#' @return A path string.
#' @keywords internal
lap_cache_source_dir <- function(source, ..., create = FALSE) {
  lap_cache_dir("sources", source, ..., create = create)
}

#' Report on the lapidary cache
#'
#' Prints and returns the cache location and the size of each source directory.
#'
#' @return A data frame (invisibly) with columns `path`, `bytes`, `exists`.
#' @export
lap_cache_info <- function() {
  root <- lap_cache_dir(create = FALSE)
  sources_root <- file.path(root, "sources")
  dirs <- if (dir.exists(sources_root)) {
    list.dirs(sources_root, recursive = FALSE)
  } else {
    character()
  }
  rows <- lapply(c(root, dirs), function(p) {
    data.frame(
      path = p,
      bytes = if (dir.exists(p)) dir_size(p) else 0,
      exists = dir.exists(p),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  cli::cli_h1("lapidary cache")
  cli::cli_text("Root: {.path {root}}")
  for (i in seq_len(nrow(out))) {
    cli::cli_li("{.path {out$path[i]}}: {format_bytes(out$bytes[i])}")
  }
  invisible(out)
}

format_bytes <- function(x) {
  units <- c("B", "kB", "MB", "GB", "TB")
  if (is.na(x) || x <= 0) {
    return("0 B")
  }
  power <- min(floor(log(x, 1000)), length(units) - 1)
  sprintf("%.1f %s", x / 1000^power, units[power + 1])
}

dir_size <- function(path) {
  files <- list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  sum(file.info(files)$size, na.rm = TRUE)
}
