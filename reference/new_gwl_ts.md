# The `gwl_ts` groundwater time-series class

A `gwl_ts` is a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) with at
least the columns `well_id` (character), `date` (lubridate::Date), `gwl`
(numeric), `variable` (character) and `source` (character). An optional
`gwl_flag` factor distinguishes `"observed"` from `"imputed"` values.
Extra columns (for example meteorological forcing variables) are carried
through untouched; the analysis functions act only on the column you
point them at.

## Usage

``` r
new_gwl_ts(x, variable = "gwl_m_asl", source = NA_character_)
```

## Arguments

- x:

  A data frame / tibble with the required columns.

- variable:

  Value for the `variable` column when `x` lacks one (see Details for
  known values).

- source:

  Default value for the `source` column when `x` lacks one.

## Value

A `gwl_ts` object (a classed tibble).

## Details

`variable` names *what* `gwl` is, including its datum and units, so
series with different conventions are never mixed silently. Known
values:

- `"gwl_m_asl"`:

  groundwater level, metres above sea level (GEMS-GER)

- `"gwl_m_bgl"`:

  depth to water, metres below ground level

- `"gwl_m"`:

  level in metres, datum per source (CORRECTIV)

## Examples

``` r
df <- data.frame(
  well_id = "MW_1",
  date = as.Date("1991-01-07") + 7 * (0:3),
  gwl = c(12.1, 12.0, 11.8, 11.9)
)
new_gwl_ts(df, variable = "gwl_m_asl", source = "example")
```
