# lapidary options

`lapidary` reads a handful of options, each overridable by an
environment variable. Options win over environment variables.

## Details

- `lapidary.cache_dir` / `LAPIDARY_CACHE_DIR`:

  Directory for downloaded and derived datasets. Defaults to
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html).

- `lapidary.lang` / `LAPIDARY_LANG`:

  Default language for user-facing labels, one of `"en"` or `"de"`.
  Defaults to `"en"`.
