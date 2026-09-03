# Read CORRECTIV groundwater levels as a `gwl_ts`

Read CORRECTIV groundwater levels as a `gwl_ts`

## Usage

``` r
lap_read_correctiv(wells = NULL, date_range = NULL)
```

## Arguments

- wells:

  Optional character vector of `well_id`s to keep.

- date_range:

  Optional length-2 `Date` (or coercible) vector.

## Value

A `gwl_ts` (`source` = `"correctiv"`, `variable` = `"gwl_m"`).
