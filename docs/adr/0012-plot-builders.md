# 12. Plot builders: `lap_plot_*`, one contract, how-to-read annotations

- Status: accepted
- Date: 2026-09-04

## Context

Milestone 2. The catalogue has ~17 indicator keys / ~40 `ind_*` columns and a
shared style scheme (`theme_lapidary()`, the `scale_*_lapidary_*` family,
tokens, `ggsave_lapidary()`, i18n). `playground2.r` shows users re-hand-writing
`geom_sf() + scale_fill_lapidary_c() + theme_lapidary()` for every map. The goal
is A1 posters, but this milestone builds only the **reusable chart builders**
that posters (and a later website) compose — ADR-0007 puts them in `lapidary`.
Poster-level composition (`lap_canvas()` / `lap_poster()`, an A1 grid, print
pipeline) and the finished posters are deferred.

## Decision

### Naming — `lap_plot_*()`

A builder is a plain function call returning a plot object, not a ggplot2
extension point, so it takes the `lap_` prefix (ADR-0008), not the `_lapidary`
suffix. `lap_plot_<TAB>` groups the family. Support functions get their own
`lap_` verbs (`lap_annotate_howto()`, `lap_howto()`, later `lap_canvas()` /
`lap_poster()` / `lap_legend_*()`).

### Taxonomy — three families + one cross-cut

1. **Status quo** — one value per well over the whole record:
   `lap_plot_hex_map()`, `lap_plot_point_map()`, `lap_plot_distribution()`,
   `lap_plot_indicator_scatter()`, `lap_plot_month_ring()`.
2. **Change over periods** — `lap_indicator_change()` / `lap_indicator_delta()`:
   `lap_plot_delta_map()`, `lap_plot_period_ridges()`, `lap_plot_change_scatter()`.
3. **Temporal evolution** — the underlying series / a rolling indicator, no map:
   `lap_plot_ridgeline()`, `lap_plot_stream()`, `lap_plot_calendar()`,
   `lap_plot_reference_band()`.
Cross-cut: `margin = c("none","histogram","density","raincloud")` on the map
builders attaches a marginal distribution of the mapped values (tight
`patchwork`, shared scale).

### The contract

```
lap_plot_xxx(data, ..., variant = lap_variant(), lang = NULL,
             annotate = getOption("lapidary.annotate", "caption"),
             role, direction, robust, range,
             base_size = NULL, preset = NULL,
             title = NULL, subtitle = NULL, caption = NULL)
```

- `data` is **one** documented canonical shape; wrong shape → `cli::cli_abort()`
  that names the shape **and the primitive that produces it**.
- Column args are tidy-select (`lap_eval_select_one()`); `...` forwards to the
  builder's `scale_*_lapidary_*`. Exception: where the arg names a *derived*
  column family rather than a literal column (the `value` of `lap_plot_delta_map()`
  / `lap_plot_change_scatter()` is a base indicator name whose `_<from>` /
  `_<to>` / `_change` columns are resolved via `resolve_delta_columns()`), it is
  taken as a bare symbol / string with `rlang::ensym()`.
- Returns a **bare `ggplot`**; composite / `margin` builders return `patchwork`
  (documented in `@return`).
- No global state, RNG, file IO, `ggsave()` or `options()` calls. Deterministic:
  two calls → `identical()` layer data + count.
- Ends with exactly `theme_lapidary(variant, base_size, panel=)`, **one**
  `*_lapidary` colour/fill scale, all display text via `lap_tr()` / `lap_howto()`.
- `preset` (a `lap_preset_names()` value) supplies `base_size` for standalone
  poster-size use; a later `lap_poster()` re-themes patches to the canvas size.

### How-to-read annotations — default on

The `annotate` argument defaults to `"caption"`: the builder appends a
localised `howto_<builder>` registry string to `plot.caption` (markdown-aware,
wraps to the plot width via `ggtext::element_textbox_simple`). `"callout"` puts
it in an on-panel corner box; `NA` / `FALSE` suppresses; any other string is
used verbatim. `options(lapidary.annotate = NA)` sets the default globally.
`lap_howto()` fills `{recharge}` / `{discharge}` / `{below}` / `{above}` colour
placeholders from the tokens so the prose colour-matches the plot.
`lap_annotate_howto()` is the standalone post-hoc helper.

### Supporting changes

- **`lap_variant()`** — light/dark resolver mirroring `lap_lang()`
  (`options(lapidary.variant=)` / `LAPIDARY_VARIANT`, default `"light"`);
  `theme_lapidary(variant = lap_variant())`.
- **`theme_lapidary(map=)` → `panel = c("map","xy","ridge","polar")`** (`map`
  kept as a deprecated alias): each family blanks a different subset of panel
  furniture.
- **`lap_na_guide()` / `lap_coloursteps_guide()` gain a `variant` argument** —
  they previously read `lap_tokens()` (always light) for the swatch / frame /
  tick colours.
- **`ggplot2 (>= 3.5.0)`, `ggtext`, `scales`, `scico` move to Imports**;
  `patchwork` follows when the `margin` cross-cut lands. `ggfx` / `ggridges` /
  `geomtextpath` / `ggdist` / `geofacet` stay Suggests behind per-builder
  `rlang::check_installed()` guards.
- **`R/i18n.R` split**: logic stays; `lap_labels` data moves to
  `R/i18n-labels.R`, gaining `howto_*` and `months_short` keys.

### Chart-motivated derived quantities (ADR-0002 provenance)

`circular_month_density()` (for `lap_plot_month_ring(stat = "density")`) and
`lap_reference_envelope()` (for `lap_plot_reference_band()`) are added only
because a chart needs them, next to the existing primitives, with a note.

## Consequences

- Every builder is testable at three levels: cheap assertions (run everywhere),
  a shared `test-plot-contract.R` loop, and per-builder `vdiffr` snapshots
  (forced fallback fonts, `skip_on_cran()`).
- `lapidary` is now a hard ggplot2 dependency — acceptable; it *is* a
  visualisation package after M2.
- Posters remain out of scope; a scratch `poster-sketches` article may stitch
  builders with raw `patchwork` as WIP, not a deliverable.
