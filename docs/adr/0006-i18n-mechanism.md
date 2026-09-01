# 6. Bilingual output via a central string registry

- Status: accepted
- Date: 2026-09-01

## Context

The graphics are for a German dataset but the intended audiences (a website, a
scientific poster) may want English or German labels, titles and captions. This
must not mean two copies of every plot builder.

## Decision

- `R/i18n.R` holds `lap_labels`: a nested list keyed by string id, each
  entry with one field per supported language (`en`, `de`).
- `tr(id, lang, ...)` looks up a string, falls back to `en` on a missing
  translation, and fills `{placeholder}` tokens from `...`.
- The default language is resolved by `lap_lang()` from the
  `lapidary.lang` option / `LAPIDARY_LANG` env var (default `"en"`).
- Every user-facing helper and (milestone 2) every plot builder takes a
  `lang` argument defaulting to `lap_lang()`.

## Consequences

- Adding a language = adding a field to each registry entry + extending
  `lap_langs()`.
- Builders must never hard-code display text; it goes through `lap_tr()`.
- Data-derived text (well names, place names) is out of scope — only interface
  strings and standard captions are translated.
