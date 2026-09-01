#' Download a file with a checksum check and resume support
#'
#' @param url Source URL.
#' @param dest Destination path.
#' @param md5 Optional expected MD5 checksum (hex string, with or without an
#'   `md5:` prefix).
#' @param overwrite Re-download even if `dest` exists and matches `md5`.
#' @param quiet Suppress the progress bar.
#'
#' @return `dest`, invisibly.
#' @keywords internal
lap_download_cached <- function(url, dest, md5 = NULL, overwrite = FALSE,
                            quiet = FALSE) {
  md5 <- sub("^md5:", "", md5 %||% "")
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)

  if (file.exists(dest) && !overwrite) {
    if (!nzchar(md5) || identical(unname(tools::md5sum(dest)), md5)) {
      if (!quiet) cli::cli_alert_success("Using cached {.path {basename(dest)}}.")
      return(invisible(dest))
    }
    if (!quiet) cli::cli_alert_warning("Checksum mismatch, re-downloading.")
  }

  tmp <- paste0(dest, ".part")
  if (!quiet) cli::cli_alert_info("Downloading {.url {url}}")
  utils::download.file(url, tmp, mode = "wb", quiet = quiet)

  if (nzchar(md5)) {
    got <- unname(tools::md5sum(tmp))
    if (!identical(got, md5)) {
      unlink(tmp)
      cli::cli_abort(c(
        "Checksum mismatch for {.path {basename(dest)}}.",
        x = "expected {.val {md5}}", x = "got {.val {got}}"
      ))
    }
  }
  file.rename(tmp, dest)
  invisible(dest)
}

#' Unzip an archive once
#'
#' @param zip Path to a `.zip` file.
#' @param exdir Target directory.
#' @param sentinel A relative path inside `exdir` whose existence means the
#'   archive is already extracted.
#'
#' @return `exdir`, invisibly.
#' @keywords internal
lap_unzip_once <- function(zip, exdir, sentinel = NULL) {
  if (!is.null(sentinel) && file.exists(file.path(exdir, sentinel))) {
    return(invisible(exdir))
  }
  dir.create(exdir, recursive = TRUE, showWarnings = FALSE)
  utils::unzip(zip, exdir = exdir)
  invisible(exdir)
}
