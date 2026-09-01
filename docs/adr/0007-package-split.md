# 7. Package split: lapidary vs downstream website / poster packages

- Status: accepted
- Date: 2026-09-01

## Context

The end goal spans data wrangling, analysis, a shared visual style, an
interactive website, and printed posters. Bundling all of that into one package
would couple a Shiny runtime and poster-build tooling to the analysis core.

## Decision

- **`lapidary`** owns: the data model, caching/ingest, analysis primitives, the
  shared ggplot style scheme, and (milestone 2) reusable plot builders +
  `patchwork` composition helpers. It returns plain ggplot / patchwork objects
  and data frames.
- **A separate website package** (later) owns the Shiny app and consumes
  `lapidary` builders.
- **A separate poster package** (later) owns poster layouts / print pipelines
  and consumes `lapidary` builders.

## Consequences

- `lapidary` has no Shiny dependency.
- Plot builders must be usable outside any app: no global state, explicit
  `variant` / `lang` / `preset` arguments, deterministic output.
- Milestones: (M1) data + analysis foundation; (M2) builders + composition;
  (M3) finished posters + gallery; then the downstream packages.
