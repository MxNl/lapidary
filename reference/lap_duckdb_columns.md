# Column names DuckDB assigns to a read expression

Useful because `read_csv_auto()` names an unnamed leading column
`column0` / `column00` / ... depending on the total column count.

## Usage

``` r
lap_duckdb_columns(read_expr, con = NULL)
```

## Arguments

- read_expr:

  A SQL table expression (e.g. a `read_csv_auto(...)` call).

- con:

  Optional connection.

## Value

A character vector of column names.
