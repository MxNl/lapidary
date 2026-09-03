# Example hexagon aggregation over Germany

Mean and standard deviation of groundwater level per 25 km hexagon,
aggregated from
[gems_ger_wells_sample](https://mxnl.github.io/lapidary/reference/gems_ger_wells_sample.md).
For demonstrating the map builders; the sparse well sample means most
hexagons are empty.

## Usage

``` r
germany_hex_sample
```

## Format

An `sf` polygon layer with `hex_id`, `n_wells`, `mean_gwl`, `sd_gwl`.

## Source

Derived from
[gems_ger_sample](https://mxnl.github.io/lapidary/reference/gems_ger_sample.md)
via
[`lap_aggregate_to_hex()`](https://mxnl.github.io/lapidary/reference/lap_aggregate_to_hex.md).
