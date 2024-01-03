# MetOfficeStationData

[![Build Status](https://github.com/tpgillam/MetOfficeStationData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/tpgillam/MetOfficeStationData.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/tpgillam/MetOfficeStationData.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/tpgillam/MetOfficeStationData.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

Access the [Met Office Historic station data](https://www.metoffice.gov.uk/research/climate/maps-and-data/historic-station-data).

These are monthly summaries of weather from across the UK, with long histories.

## Usage
If you know the `short_name` of a station, you can obtain the data like so:
```julia
using MetOfficeStationData
MetOfficeStationData.get_frame("cambridge")
```
```
779×7 DataFrame
 Row │ yyyy   mm     tmax     tmin     af     rain       sun
     │ Int64  Int64  Float64  Float64  Int64  Float64?   Float64?
─────┼─────────────────────────────────────────────────────────────
   1 │  1959      1      4.4     -1.4     20  missing         78.1
   2 │  1959      2      7.5      1.2      9  missing         66.0
   3 │  1959      3     11.5      3.8      0  missing         98.0
   4 │  1959      4     14.3      5.4      0  missing        146.1
   5 │  1959      5     18.1      6.5      0  missing        224.8
   6 │  1959      6     21.6     10.1      0  missing        252.4
...
```

To obtain metadata for all stations, including the `short_name`s needed for `MetOfficeStationData.get_frame`:
```julia
MetOfficeStationData.get_station_metadata()
```
```
37×5 DataFrame
 Row │ name                        lat      lon      year_start  short_name
     │ String                      Float64  Float64  Int64       SubString…
─────┼───────────────────────────────────────────────────────────────────────────
   1 │ Aberporth                    52.139   -4.57         1941  aberporth
   2 │ Armagh                       54.352   -6.649        1853  armagh
   3 │ Ballypatrick Forest          55.181   -6.153        1961  ballypatrick
   4 │ Bradford                     53.813   -1.772        1908  bradford
   5 │ Braemar No 2                 57.011   -3.396        1959  braemar
...
```

## Limitations
The data files given by the Met Office include various annotations, e.g. noting the types of sensor used, or whether data is preliminary, or even if a station changed location.
We do not preserve any of this!
