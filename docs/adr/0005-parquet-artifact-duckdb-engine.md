# 5. Data backend: Parquet is the artifact, DuckDB is the engine

- Status: accepted
- Date: 2026-09-01

## Context

GEMS-GER ships ~3,200 per-well CSV files (~5.3M rows for levels alone, more
with forcings). Repeatedly parsing CSVs is slow; the future Shiny app needs
fast filtered reads and aggregations; and the store must stay portable and not
require a running server.

## Decision

- The canonical cached form of every source is **Parquet** (ZSTD), written once
  per version under `<cache>/sources/<source>/parquet/<version>/`:
  `gwl.parquet` (`well_id`, `date`, `gwl`, `gwl_flag`) and optionally
  `meteo.parquet`.
- **DuckDB** is the query engine. `lap_gwl_tbl()` returns a lazy `dplyr` table over
  `read_parquet(...)`; filters and `lap_summarise_wells()` aggregations push down to
  DuckDB. `lap_read_gwl()` / `lap_read_gems_ger()` collect a validated `gwl_ts`;
  `lap_gwl_query(fn)` runs a lazy pipeline and closes its own connection.
- `"latest"` resolves to the newest built version *directory* on disk
  (`resolve_parquet_version()`), so a source reader never has to pre-resolve.
- Connection lifetime: `lap_gwl_tbl()` opens an in-memory connection reachable
  through `tbl$src$con` (survives `dplyr` verbs), so `lap_disconnect()` on any
  downstream lazy table closes it. Long-running apps pass their own `con`.
- DuckDB also performs the CSV -> Parquet conversion (`lap_csvs_to_parquet()` via
  `read_csv_auto` + `COPY ... TO`), so **`arrow` is not required** — it is a
  Suggests-level accelerator for `collect()` only.

## Consequences

- No server process; the cache is copyable between machines.
- `duckdb` + `dbplyr` cover ingest, storage and query.
- `arrow` build failures on a machine don't block the package.
- Parquet files are versioned by directory, matching the dataset-version model.
