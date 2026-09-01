# 8. `lap_` prefix on the core API, tidy-evaluation for column arguments

- Status: accepted
- Date: 2026-09-01

## Context

lapidary is one of several planned packages (lapidary, a website package, a
poster package). When lapidary functions are read from those downstream
packages it should be obvious which calls are lapidary's. The API also has many
small functions in a few conceptual families, which benefits from a common
discovery prefix (`lap_<TAB>`). Separately, the analysis functions all take
data-frame columns as arguments; string arguments read poorly next to the
tidyverse verbs users already know.

## Decision

**Prefix.** The core API is `lap_`-prefixed: analysis verbs
(`lap_summarise_wells`, `lap_gw_trend`, `lap_normalise_gwl`,
`lap_add_reference_period`, `lap_use_water_year`, `lap_aggregate_to_hex`, ...),
ingest (`lap_read_gems_ger`, `lap_gems_ger_download`, `lap_read_correctiv`,
...), cache/engine (`lap_cache_dir`, `lap_gwl_tbl`, `lap_read_gwl`, ...) and
package nouns (`lap_tokens`, `lap_fonts`, `lap_preset`, `lap_tr`, `lap_lang`).

Deliberately **not** prefixed:
- ggplot2 extension points, which follow the ecosystem's suffix convention:
  `theme_lapidary()`, `scale_fill_lapidary_c/d()`,
  `scale_colour_lapidary_c/d()`, `ggsave_lapidary()`, and future
  `geom_*_lapidary()`.
- Class constructors/validators, tied to the class names: `new_gwl_ts()`,
  `validate_gwl_ts()`, `check_gwl_ts()`, `as_gwl_ts()`, `new_gwl_wells()`,
  `check_gwl_wells()`; classes `gwl_ts`, `gwl_wells`.
- Packaged datasets: `gems_ger_sample`, `gems_ger_wells_sample`,
  `germany_hex_sample`.

This mirrors `sf` (`st_*` for the API, `sf`/`sfc` for classes).

**Tidy evaluation.** Every argument that names data-frame column(s) is
tidy-select, resolved through two helpers in `R/utils-tidyselect.R`:

- `lap_eval_select(x, quo, extra, arg)` -> zero or more column names
- `lap_eval_select_one(x, quo, arg, null_ok)` -> exactly one (or `NULL`)

They accept **bare names** (`value = gwl`), **strings** (`value = "gwl"`),
**character vectors** and **tidyselect helpers** (`by = all_of(cfg$cols)`,
`cols = starts_with("gwl")`), and work on lazy DuckDB tables by taking the
column vocabulary from `dplyr::tbl_vars()`. Defaults are bare names
(`by = c(well_id, year)`), registered in `utils::globalVariables()`.

## Consequences

- String-driven callers (the Shiny app, `_targets.R` config) keep working
  unchanged - tidyselect treats strings as names.
- Programmatic callers use `all_of()` / `!!` as usual.
- One rename pass touched every file; downstream packages must use the `lap_`
  names.
- New column arguments must go through the tidyselect helpers, not `x[[arg]]`.
