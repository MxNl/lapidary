# What a low vs a high value of an indicator means, in plain words --------
#
# Data only, bilingual (see lap_langs()). Keyed by `ind_*` column name; each
# entry has one field per language holding c(low = , high = ). The plot
# builders turn this into a directional axis label
# ("<low>  <-  Indicator  ->  <high>"); `indicator_interpretation()` is the
# lookup. Not every column is seeded - a missing one just yields no directional
# cue. Extend this list as posters need more.

lap_interpretations <- list(
  ind_amplitude = list(
    en = c(low = "small overall swing", high = "large overall swing"),
    de = c(low = "kleine Gesamtschwankung", high = "gro\u00dfe Gesamtschwankung")
  ),
  ind_seasonal_amplitude = list(
    en = c(low = "weak seasonal swing", high = "strong seasonal swing"),
    de = c(low = "schwacher Jahresgang", high = "starker Jahresgang")
  ),
  ind_seasonality_strength = list(
    en = c(low = "weak seasonality", high = "strong seasonality"),
    de = c(low = "schwache Saisonalit\u00e4t", high = "starke Saisonalit\u00e4t")
  ),
  ind_flashiness = list(
    en = c(low = "slow, damped response", high = "flashy, rapid response"),
    de = c(low = "tr\u00e4ge Reaktion", high = "schnelle Reaktion")
  ),
  ind_acf1 = list(
    en = c(low = "little persistence", high = "strong persistence"),
    de = c(low = "geringe Persistenz", high = "hohe Persistenz")
  ),
  ind_memory_weeks = list(
    en = c(low = "short memory", high = "long memory"),
    de = c(low = "kurzes Ged\u00e4chtnis", high = "langes Ged\u00e4chtnis")
  ),
  ind_min_month_sd = list(
    en = c(low = "regular seasonal timing", high = "erratic seasonal timing"),
    de = c(low = "regelm\u00e4\u00dfiges Timing", high = "unregelm\u00e4\u00dfiges Timing")
  ),
  ind_trend_slope = list(
    en = c(low = "falling levels", high = "rising levels"),
    de = c(low = "fallende St\u00e4nde", high = "steigende St\u00e4nde")
  ),
  ind_residual_trend_slope = list(
    en = c(low = "declining (climate-removed)", high = "rising (climate-removed)"),
    de = c(low = "fallend (klimabereinigt)", high = "steigend (klimabereinigt)")
  ),
  ind_trend_accel = list(
    en = c(low = "accelerating decline", high = "accelerating rise"),
    de = c(low = "beschleunigter R\u00fcckgang", high = "beschleunigter Anstieg")
  ),
  ind_climate_cc = list(
    en = c(low = "less climate-driven", high = "more climate-driven"),
    de = c(low = "wenig klimagesteuert", high = "stark klimagesteuert")
  ),
  ind_recession_weeks = list(
    en = c(low = "fast recession", high = "slow recession"),
    de = c(low = "schnelle Rezession", high = "langsame Rezession")
  ),
  ind_drought_frequency = list(
    en = c(low = "rare droughts", high = "frequent droughts"),
    de = c(low = "seltene D\u00fcrren", high = "h\u00e4ufige D\u00fcrren")
  ),
  ind_drought_duration_weeks = list(
    en = c(low = "short droughts", high = "long droughts"),
    de = c(low = "kurze D\u00fcrren", high = "lange D\u00fcrren")
  ),
  ind_drought_severity = list(
    en = c(low = "mild droughts", high = "severe droughts"),
    de = c(low = "milde D\u00fcrren", high = "schwere D\u00fcrren")
  )
)

# c(low = , high = ) gloss for an `ind_*` column in `lang` (falling back to
# "en"), or NULL when the column is not in `lap_interpretations`.
indicator_interpretation <- function(col, lang = NULL) {
  entry <- lap_interpretations[[col]]
  if (is.null(entry)) {
    return(NULL)
  }
  entry[[lap_lang(lang)]] %||% entry[["en"]]
}
