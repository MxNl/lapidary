# 1. Canonical data model: `gwl_ts` and `gwl_wells`

- Status: accepted
- Date: 2026-09-01

## Context

`lapidary` must ingest several groundwater time-series sources (GEMS-GER first,
then CORRECTIV, BGR, state authorities, and future GEMS releases) and feed them
into one set of analysis and plotting functions. `playground.R` handled this
ad hoc: every source had its own bespoke wrangling and the analysis code was
coupled to whichever column names that source happened to use.

## Decision

Every reader normalises its source into two documented shapes, and analysis /
plotting code only ever sees these:

- **`gwl_ts`** — a tidy long tibble (classed), one row per well x timestamp,
  with required columns `well_id` (chr), `date` (Date), `gwl` (dbl),
  `variable` (chr, names the quantity + units, e.g. `"gwl_m_asl"`), `source`
  (chr). Optional `gwl_flag` factor (`observed` / `imputed`). Extra columns
  (e.g. meteorological forcings) pass through untouched.
- **`gwl_wells`** — an `sf` POINT layer, one row per well, always stored in
  EPSG:25832 (matches `playground.R`), `well_id` plus free static attributes.

Constructors (`new_gwl_ts()`, `new_gwl_wells()`), coercers (`as_gwl_ts()`) and
validators (`validate_gwl_ts()`, `check_gwl_ts()`, `check_gwl_wells()`) live in
`R/data-model.R`. A new source is "supported" exactly when it has a reader that
returns these.

## Consequences

- Analysis functions take/return `gwl_ts`; they never branch on source.
- `variable` (not the column name) carries units/meaning, so mixing m a.s.l.
  and depth-to-water is explicit and catchable.
- Weekly (GEMS) vs monthly (CORRECTIV) cadence is not encoded in the type;
  functions that care take an explicit `expected_per_year` / `start_month`.
- Slight cost: readers must do the normalisation work up front.
