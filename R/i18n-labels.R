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
  ),
  howto_distribution = list(
    en = paste(
      "Each well contributes one value; the bars / curve show how those values",
      "are spread, coloured on the same scale as the maps."
    ),
    de = paste(
      "Jede Messstelle liefert einen Wert; die Balken / die Kurve zeigen deren",
      "Verteilung, eingef\u00e4rbt in derselben Skala wie die Karten."
    )
  ),
  howto_indicator_scatter = list(
    en = "One point per well. A rising cloud means the two metrics go together.",
    de = paste(
      "Ein Punkt je Messstelle. Eine steigende Punktwolke hei\u00dft, die beiden",
      "Kenngr\u00f6\u00dfen h\u00e4ngen zusammen."
    )
  ),
  howto_delta_map_change = list(
    en = paste(
      "Each hexagon is the average change between the two periods. Gold cells",
      "increased, blue cells decreased; near-white changed little. Grey cells",
      "have no wells."
    ),
    de = paste(
      "Jede Wabe ist die mittlere Ver\u00e4nderung zwischen den beiden Zeitr\u00e4umen.",
      "Goldene Zellen sind gestiegen, blaue gesunken; nahezu wei\u00df hei\u00dft kaum",
      "Ver\u00e4nderung. Graue Zellen haben keine Messstellen."
    )
  ),
  howto_delta_map_paired = list(
    en = paste(
      "The same indicator in each period, on one shared colour scale. Compare",
      "a hexagon between the two maps to read its shift."
    ),
    de = paste(
      "Dieselbe Kenngr\u00f6\u00dfe je Zeitraum, auf einer gemeinsamen Farbskala.",
      "Vergleiche eine Wabe zwischen den beiden Karten, um ihre Verschiebung",
      "zu erkennen."
    )
  ),
  howto_delta_map_arrow = list(
    en = paste(
      "Each hexagon carries an arrow: its length and direction show how far",
      "and which way the indicator moved between the two periods."
    ),
    de = paste(
      "Jede Wabe tr\u00e4gt einen Pfeil: L\u00e4nge und Richtung zeigen, wie weit und",
      "in welche Richtung sich die Kenngr\u00f6\u00dfe zwischen den Zeitr\u00e4umen bewegt hat."
    )
  ),
  howto_period_ridges = list(
    en = paste(
      "Each ridge is the distribution of one period's well values; reading",
      "bottom to top follows time. A sideways shift means the whole population",
      "moved."
    ),
    de = paste(
      "Jeder Kamm ist die Verteilung der Messstellenwerte eines Zeitraums; von",
      "unten nach oben verl\u00e4uft die Zeit. Eine seitliche Verschiebung hei\u00dft,",
      "die gesamte Verteilung hat sich verschoben."
    )
  ),
  howto_change_scatter = list(
    en = paste(
      "One point per well: its starting value against its change. A tilted",
      "cloud means wells that started high changed differently from wells that",
      "started low."
    ),
    de = paste(
      "Ein Punkt je Messstelle: Ausgangswert gegen Ver\u00e4nderung. Eine geneigte",
      "Punktwolke hei\u00dft, hoch startende Messstellen haben sich anders",
      "ver\u00e4ndert als niedrig startende."
    )
  )
)
