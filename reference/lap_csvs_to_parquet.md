# Convert a directory of per-well CSV files into one Parquet file

DuckDB globs and unions the CSVs in a single query. Column selection and
renaming are handled by `select_sql` (a SQL `SELECT` list).

## Usage

``` r
lap_csvs_to_parquet(
  csv_glob,
  out_path,
  select_sql = "*",
  filename = TRUE,
  overwrite = FALSE
)
```

## Arguments

- csv_glob:

  Glob pattern matching the CSV files.

- out_path:

  Output Parquet file.

- select_sql:

  SQL select-list mapping source columns to the canonical schema, e.g.
  `"filename AS src, GWL AS gwl"`.

- filename:

  Whether to expose the source path as a `filename` column (needed when
  the well id is encoded in the file name).

- overwrite:

  Overwrite an existing output.

## Value

`out_path`, invisibly.
