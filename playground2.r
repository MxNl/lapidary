library(dplyr)

data(gems_ger_sample)
data(gems_ger_wells_sample)

gems_ger_sample
gems_ger_wells_sample

gems_ger_sample |> 
  distinct(well_id) |> 
  arrange(well_id)

gems_ger_wells_sample |> 
  distinct(well_id) |> 
  arrange(well_id)

gems_ger_sample |>
  lap_use_water_year() |>
  lap_add_reference_period(periods = list(Z1 = c(1991, 2020))) |>
  lap_summarise_wells(by = c(well_id, year)) |>
  lap_gw_trend(value = mean_gwl, time = year)

  
gwl <- lap_read_gems_ger()

gwl |> 
  lap_summarise_wells(by = c(well_id, year))

gwl |> 
  mutate(year = lubridate::year(date))
