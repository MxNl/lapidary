# 3. Style scheme: design tokens, light default + dark variant

- Status: accepted
- Date: 2026-09-01

## Context

`playground.R` scatters ~25 loose constants (colours, font families, sizes,
shadow sigma, spacing) across the top of the script and repeats a large
`theme(...)` block in every plot function. The graphics must work both as a
light A1 poster (the prototype's final output) and, later, on a website — and
the same plot object should scale from screen to A0 without hand-tuning every
size.

## Decision

- A single `lap_tokens(variant)` function returns a nested list of tokens
  for `"light"` (default) or `"dark"`. All downstream code reads tokens through
  it; no hard-coded colours/sizes elsewhere.
- Type sizes in the tokens are **multipliers of a `base_size`**, and
  `theme_lapidary(variant, base_size, map)` applies them via `ggplot2::rel()`.
  `ggsave_lapidary(preset=)` picks `base_size` + width/height/dpi per output
  target and fixes `showtext`'s DPI to match.
- Fonts (Oleo Script titles, Dosis body) are registered by `lap_fonts()`
  and every theme call resolves to a real fallback (`serif`/`sans`) when they
  are not available, so headless/CI rendering never errors.
- `scale_*_lapidary_*(role=)` wrap scico palettes behind role names
  (`months`, `magnitude`, `density`, `anomaly`).

## Consequences

- Restyle = edit one function.
- Light and dark stay in lock-step because they are two branches of one token
  builder.
- Plot builders (milestone 2) must accept `variant` + `base_size`/`preset` and
  must not call `theme()` with literal values.
