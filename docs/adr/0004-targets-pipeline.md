# 4. Reproducible pipeline with {targets} (maintainer-side only)

- Status: accepted
- Date: 2026-09-01

## Context

Derived artifacts (Parquet trees, per-well summaries, hex aggregations, the
packaged sample data) need regenerating whenever GEMS-GER publishes a new
version, a reference period changes, or another source is added. Doing this by
hand is error-prone and the provenance is lost.

## Decision

A `{targets}` pipeline in `_targets.R` at the repo root chains the package's own
functions into a cached DAG:
`gems_download -> gems_parquet -> wells_sf / sample_wells -> gwl_sample_raw ->
sample_data -> sample_data_files`.
The sampling and dataset build are the internal helpers in `R/sample-data.R`,
which `data-raw/make_sample_data.R` calls too, so both routes produce identical
`data/*.rda`. It is parameterised by a `config` list (version, reference
period, sample size + seed, hex cellsize).

The pipeline is **maintainer infrastructure**. It is `.Rbuildignore`d, is not
part of the package API, and nothing in `lapidary` or in downstream (Shiny /
poster) packages calls it. Runtime functions such as `lap_read_gems_ger()` and
`lap_summarise_wells()` work standalone.

## Consequences

- `targets::tar_make()` refreshes everything, skipping unchanged steps.
- `targets` / `tarchetypes` are Suggests only.
- Contributors need to know `targets` to regenerate sample data, but not to use
  the package.
- Alternative considered: plain numbered `data-raw/` scripts — rejected because
  the multi-source, multi-version matrix benefits from automatic
  skip-if-unchanged and an explicit dependency graph.
