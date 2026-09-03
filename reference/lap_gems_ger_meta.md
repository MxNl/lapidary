# GEMS-GER dataset metadata

GEMS-GER dataset metadata

## Usage

``` r
lap_gems_ger_meta(version = "latest")
```

## Arguments

- version:

  Version key (`"1.0"`) or `"latest"`.

## Value

A list with `version`, `record`, `doi`, `concept_doi`, `licence`,
`citation`, `url`, `crs` and `variable`.

## Examples

``` r
lap_gems_ger_meta()
#> $version
#> [1] "1.0"
#> 
#> $record
#> [1] "16736908"
#> 
#> $doi
#> [1] "10.5281/zenodo.16736908"
#> 
#> $concept_doi
#> [1] "10.5281/zenodo.15530171"
#> 
#> $licence
#> [1] "CC-BY-NC-ND-4.0"
#> 
#> $citation
#> [1] "Wunsch, A., Liesch, T. & Broda, S. (2026). GEMS-GER: A Machine Learning Benchmark Dataset of Long-Term Groundwater Levels in Germany with Meteorological Forcings and Site-Specific Environmental Features. Earth System Science Data. doi:10.5281/zenodo.15530171"
#> 
#> $url
#> [1] "https://zenodo.org/records/16736908"
#> 
#> $crs
#> [1] 3035
#> 
#> $variable
#> [1] "gwl_m_asl"
#> 
```
