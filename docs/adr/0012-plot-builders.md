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

### How-to-read annotations — off by default

The `annotate` argument defaults to `NA` (suppressed): pass `"caption"` to
have the builder append a localised `howto_<builder>` registry string to
`plot.caption` (markdown-aware, wraps to the plot width via
`ggtext::element_textbox_simple`). `"callout"` puts it in an on-panel corner
box instead; any other string is used verbatim. `options(lapidary.annotate =
"caption")` opts in globally. `lap_howto()` fills `{recharge}` /
`{discharge}` / `{below}` / `{above}` colour placeholders from the tokens so
the prose colour-matches the plot. `lap_annotate_howto()` is the standalone
post-hoc helper.

(Defaulted *on* through most of milestone 2's development - see the PR
sequence below for the builders that were designed and reviewed against that
default. Switched to off once poster work with the shipped builders showed
the auto-generated text read better added in post-production (e.g. Inkscape)
than baked into every render by default; opting in per call or globally is
unchanged.)

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

### Ridgeline builders and the interpretation registry

`lap_plot_period_ridges()` is the first builder backed by `ggridges`
(`geom_density_ridges_gradient()`, along-value-axis gradient fill, background
-colour cut-out outline); `lap_plot_ridgeline()` (temporal evolution) follows
the same pattern. A `lap_interpretations` lookup (`R/indicator-interpretation.R`,
bilingual, keyed by `ind_*` column) glosses what a low vs a high value means;
builders render it as a directional value-axis label and it is shared
infrastructure for later builders. Framed panels (`panel = "xy" / "ridge" /
"polar"`) carry a non-zero `plot.margin` — only the edge-to-edge map panel
wants zero.

### Composition-over-time: classify -> summarise -> plot

`lap_plot_stream()` consumes a documented shape (`x`, `category`, `n`) rather
than raw rows, the same separation-of-concerns as `lap_aggregate_to_hex()`
feeding `lap_plot_hex_map()`: a specific per-well classifier
(`lap_add_quantile_class()`, the German "Grundwasserstandsklassen" percentile
bands, `R/quantile-class.R`) produces row-level categorical data; a generic
summariser (`lap_summarise_composition()`, `R/composition.R` - any category +
date column, not gwl-class-specific) turns it into a share-per-time-bucket
table; the builder only draws. `ggstream` (the obvious CRAN package for this)
was archived 2025-11-07, so the "proportional" stream is hand-rolled with
`ggplot2::geom_area(position = position_fill(reverse = TRUE))` - a 100%-stacked
area *is* what `type = "proportional"` drew - rather than take on an
unmaintained dependency. No `DESCRIPTION` change.

### Record-events calendar: the same classify -> summarise -> plot split

`lap_plot_calendar()` realises the taxonomy's generic "calendar heatmap (year
x week/month), for a well or an aggregate" via a specific use case: counting
new all-time low/high records. `lap_add_record_flags()` (`R/records.R`) is
the per-well classifier (a running extreme, row-preserving, deliberately
*not* corrected for network-growth or short-history confounds - that's the
caller's job, by feeding a stable well panel). A well's first year is not
evaluated for records at all - there is no real prior year to compare
against, so flagging it either way (`TRUE` or `FALSE`) would misrepresent it
(a genuine record, or indistinguishable from a genuine non-record year). Its
flags are `NA` for every row of that year instead, and `lap_summarise_calendar()`
(added to `R/composition.R`, a second generic time-bucket summariser
alongside `lap_summarise_composition()`) tracks per-column-per-bucket
validity (`sum(!is.na(v))` alongside `sum(v, na.rm = TRUE)`) and drops a
`(year, unit, name)` row entirely when its column had zero non-`NA`
contributions in that bucket, rather than zero-filling it - so a well's
first year produces no tile in [lap_plot_calendar()] at all, not a
blank/neutral one that would misleadingly read as "no record activity"
rather than "no baseline yet." Columns from the same call can drop
independently per bucket. `lap_plot_calendar()` draws the result as one or
more (`facet =`) tile grids on one shared scale. A future single-well
raw-series calendar feeds the same builder from its own small aggregation -
no changes to `lap_plot_calendar()` needed.

`lap_plot_calendar()`'s `midpoint` argument is the one builder-contract
exception that swaps its fill scale for something other than
`scale_*_lapidary_c()`/`_d()`: a bespoke `ggplot2::continuous_scale()` built
from 255 stops of the *full* `role` scico palette (not just its two end
colours), with only the exact centre stop swapped for the variant's own
background colour, not the palette's native centre. This is deliberate, not
an oversight - the package's binned-by-default scale has no notion of a
`midpoint` when it picks its breaks, so an exact-midpoint value can land on a
bin edge and inherit an adjacent bin's (non-neutral) colour; a bespoke
always-smooth gradient sidesteps that entirely and guarantees the midpoint
reads as genuinely neutral, while still showing scico's own non-linear
colour path rather than a flat 2-colour blend. It pairs with the
`lap_colourbar_guide()` (`R/scales.R`), a tall/narrow `guide_colourbar()`
analogue to `lap_coloursteps_guide()`, for the same legend styling on a
smooth (non-binned) scale, and reuses `lapidary_scale_c()`'s existing
`robust`/`scales::oob_squish` machinery (`resolve_robust_probs()`,
`lap_robust_limits()`, and the shared `lap_mid_rescaler()` helper extracted
from `lapidary_scale_c()` for this purpose) for the same "squish extreme
values onto one end colour" behaviour other scale-backed builders have -
computed eagerly from the builder's own already-in-hand data frame rather
than `lapidary_scale_c()`'s deferred ggproto `train()` machinery, which only
exists there because that function is called standalone without a
pre-known dataset.

`lap_plot_calendar()` is also the first builder to place its default how-to
explanation in `plot.subtitle` rather than `plot.caption` - a deliberate,
builder-local deviation, not a change to the shared `annotate` contract in
`R/annotate.R`/`R/plot-utils.R` (`apply_howto()` is untouched and still used,
unchanged, for every other builder, and for this one too when
`annotate = "callout"`). The reasoning: this builder's explanatory text is
longer and more dynamic than other builders' (it names the actual rendered
colours and weaves in caller-supplied `low_label`/`high_label` text), and
reads better directly above the panel it describes - especially now that the
month/week axis labels also sit at the top. The text is built once,
regardless of destination (`subtitle`, `callout`, or a caller's custom
`annotate = "..."` string), then routed to the right placement - a fix
during this same round for a bug where routing-then-building would have
silently dropped the dynamic content from the `callout` path.

## Consequences

- Every builder is testable at three levels: cheap assertions (run everywhere),
  a shared `test-plot-contract.R` loop, and per-builder `vdiffr` snapshots
  (forced fallback fonts, `skip_on_cran()`).
- `lapidary` is now a hard ggplot2 dependency — acceptable; it *is* a
  visualisation package after M2.
- Posters remain out of scope; a scratch `poster-sketches` article may stitch
  builders with raw `patchwork` as WIP, not a deliverable.
