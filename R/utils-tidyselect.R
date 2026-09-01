# Tidy-select helpers -------------------------------------------------------
#
# lapidary's analysis functions take columns with tidy evaluation: bare names
# (`value = gwl`), strings (`value = "gwl"`), character vectors and tidyselect
# helpers (`by = all_of(cols)`, `cols = starts_with("gwl")`). These helpers
# resolve such an argument to plain column-name strings, and work for both
# data frames and lazy dplyr/DuckDB tables.

# Column vocabulary of `x` (data frame or lazy tbl), plus any `extra` names
# that will exist later (e.g. a derived `year` column).
lap_col_vocab <- function(x, extra = character()) {
  cols <- tryCatch(dplyr::tbl_vars(x), error = function(e) colnames(x))
  union(as.character(cols), extra)
}

# Resolve a captured quosure to zero or more column names.
lap_eval_select <- function(x, quo, extra = character(), arg = "cols",
                            call = rlang::caller_env()) {
  proxy <- rlang::rep_named(lap_col_vocab(x, extra), list(logical()))
  loc <- tidyselect::eval_select(
    quo,
    data = proxy, allow_rename = FALSE, error_call = call
  )
  names(loc)
}

# Resolve a captured quosure to exactly one column name (or NULL if allowed).
lap_eval_select_one <- function(x, quo, arg, null_ok = FALSE, extra = character(),
                                call = rlang::caller_env()) {
  if (rlang::quo_is_null(quo) || rlang::quo_is_missing(quo)) {
    if (null_ok) {
      return(NULL)
    }
    cli::cli_abort("{.arg {arg}} must name a column.", call = call)
  }
  nm <- lap_eval_select(x, quo, extra = extra, arg = arg, call = call)
  if (length(nm) != 1L) {
    cli::cli_abort(
      "{.arg {arg}} must select exactly one column, not {length(nm)}.",
      call = call
    )
  }
  nm
}
