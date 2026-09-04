# Central string registry ------------------------------------------------
#
# Data only: keyed by string id, each entry has one field per supported
# language (see lap_langs()). The lookup logic is in R/i18n.R (lap_tr(),
# lap_howto()). Extend this list as builders and captions are added.
#
# `howto_<builder>` entries are the "how to read this chart" explainers the
# plot builders append to `plot.caption` by default (annotate = "caption").
# They may carry <span style='color:...'> markup, injected by lap_howto()
# and rendered by ggtext in theme_lapidary().

lap_labels <- list(
  # --- app / attribution -------------------------------------------------
  app_title = list(
    en = "Groundwater in Germany",
    de = "Grundwasser in Deutschland"
  ),
  made_in_r = list(
    en = "Made in R",
    de = "Erstellt in R"
  ),
  by_author = list(
    en = "By {author}",
    de = "Von {author}"
  ),
  data_source = list(
    en = "Data: {source}",
    de = "Daten: {source}"
  ),

  # --- calendar --------------------------------------------------------
  months_abbr = list(
    en = c("J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"),
    de = c("J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D")
  ),
  months_short = list(
    en = c(
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ),
    de = c(
      "Jan", "Feb", "M\u00e4r", "Apr", "Mai", "Jun",
      "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"
    )
  ),
  month_names = list(
    en = c(
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ),
    de = c(
      "Januar", "Februar", "M\u00e4rz", "April", "Mai", "Juni",
      "Juli", "August", "September", "Oktober", "November", "Dezember"
    )
  ),

  # --- generic axis / legend labels -----------------------------------
  groundwater_level = list(
    en = "Groundwater level",
    de = "Grundwasserstand"
  ),
  normalised_level = list(
    en = "Normalised groundwater level",
    de = "Normierter Grundwasserstand"
  ),
  year = list(en = "Year", de = "Jahr"),
  trend_per_decade = list(
    en = "Trend (m per decade)",
    de = "Trend (m pro Dekade)"
  ),
  wells_per_hexagon = list(
    en = "Wells per hexagon",
    de = "Messstellen pro Wabe"
  ),
  no_data = list(en = "no data", de = "keine Daten"),

  # --- how to read (per builder) ------------------------------------
  howto_hex_map = list(
    en = paste(
      "Each hexagon is the average of the monitoring wells that fall inside",
      "it; darker cells hold more wells. Empty cells (no wells) are shown in",
      "grey."
    ),
    de = paste(
      "Jede Wabe ist der Mittelwert der enthaltenen Messstellen; dunklere",
      "Zellen enthalten mehr Messstellen. Leere Zellen (keine Messstellen)",
      "sind grau dargestellt."
    )
  ),
  howto_point_map = list(
    en = "One mark per monitoring well, coloured by its value.",
    de = "Eine Markierung je Messstelle, eingef\u00e4rbt nach ihrem Wert."
  )
)
