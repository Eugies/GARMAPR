

# GARMAPR

<div align="center">

**An R package for accessing water-quality sonde data from the Gulf of America Regional Monitoring and Assessment Program (GARMAP).**

[![R](https://img.shields.io/badge/R-%3E%3D4.1.0-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![GitHub repository](https://img.shields.io/badge/GitHub-Eugies%2FGARMAPR-181717?logo=github)](https://github.com/Eugies/GARMAPR)
[![Open issues](https://img.shields.io/github/issues/Eugies/GARMAPR)](https://github.com/Eugies/GARMAPR/issues)
[![Last commit](https://img.shields.io/github/last-commit/Eugies/GARMAPR)](https://github.com/Eugies/GARMAPR/commits/main)

</div>

---

## Overview

**GARMAPR** provides an R interface for retrieving water-quality sonde data from the [GARMAP data portal](https://garmapdata.gsmfc.org/).

The package handles authentication with the GARMAP website, retrieves available monitoring stations, and downloads sonde observations for selected water-quality parameters. Data can be retrieved for individual stations and parameters or across all stations and parameters available through the authenticated dashboard.

The goal of GARMAPR is to make GARMAP monitoring data easier to access, organize, and incorporate into reproducible R-based analyses.

## Features

- **Authentication:** Log in to GARMAP directly from R using your account credentials.
- **Station information:** Retrieve the monitoring stations available to your account.
- **Parameter information:** Access the available sonde water-quality parameters.
- **Data retrieval:** Download sonde observations for individual stations and parameters.
- **Multiple-station downloads:** Retrieve data across multiple stations and parameters in a single function call.
- **Combined datasets:** Automatically combine retrieved observations into one data frame.

## Installation

Install the development version from GitHub using `remotes`:

```r
install.packages("remotes")

remotes::install_github("Eugies/GARMAPR")
```

Load the package:

```r
library(GARMAPR)
```

## Getting started

### 1. Authenticate with GARMAP

A GARMAP account is required to access monitoring data. To get login details, please contact [GARMAP Contact](https://garmap.gsmfc.org/contact.php/).

Authenticate using:

```r
auth <- garmap_authenticate()
```

The function will prompt for your GARMAP email address and password. Your credentials are used to establish an authenticated session with the GARMAP website.

The returned authentication object is used in subsequent data retrieval functions.

### 2. Retrieve available monitoring stations

Use `garmap_get_stations()` to retrieve the monitoring stations available through your authenticated dashboard.

```r
stations <- garmap_get_stations(auth)

head(stations)
```

The returned data frame contains:

| Column | Description |
|---|---|
| `station` | GARMAP station identifier |
| `station_name` | Monitoring station name |

### 3. Retrieve available parameters

Use `garmap_get_parameters()` to view the water-quality parameters supported by the package.

```r
parameters <- garmap_get_parameters()

parameters
```

The currently supported parameters are:

| Parameter | Description |
|---|---|
| `TEMP_C` | Temperature (°C) |
| `SAL_PSU` | Salinity (PSU) |
| `ODO` | Dissolved oxygen |

### 4. Download sonde data

Use `garmap_get_sonde_data()` to retrieve observations for a specific station and parameter.

For example, to retrieve temperature data from station `MS00006`:

```r
temperature <- garmap_get_sonde_data(
  auth = auth,
  station = "MS00006",
  parameter = "TEMP_C"
)

head(temperature)
```

The returned data frame contains:

| Column | Description |
|---|---|
| `date` | Observation date |
| `value` | Measured water-quality value |
| `station` | Station identifier |
| `parameter` | Water-quality parameter |

The available date range for the requested station and parameter is also stored as an attribute:

```r
attr(temperature, "available_range")
```

### 5. Download data from multiple stations and parameters

GARMAPR supports retrieving data from multiple stations and parameters in one function call.

To retrieve temperature data from all available stations:

```r
temperature_all <- garmap_get_sonde_data(
  auth = auth,
  station = "all",
  parameter = "TEMP_C"
)
```

To retrieve all available parameters from one station:

```r
station_data <- garmap_get_sonde_data(
  auth = auth,
  station = "MS00006",
  parameter = "all"
)
```

To retrieve all available data across all stations and parameters:

```r
all_data <- garmap_get_sonde_data(
  auth = auth,
  station = "all",
  parameter = "all"
)
```

The results are combined into a single data frame, with station and parameter identifiers retained for filtering and analysis.

```r
# Explore the combined dataset
head(all_data)

# View available stations
unique(all_data$station)

# View available parameters
unique(all_data$parameter)

# Summarize observations by station and parameter
table(all_data$station, all_data$parameter)
```

## Data considerations

The current GARMAP data retrieval endpoint returns observations with date-only timestamps. Consequently, the data retrieved through `garmap_get_sonde_data()` are represented at a **daily temporal resolution**.

Although GARMAP sondes may collect measurements at finer temporal intervals, retrieval of those higher-frequency observations has not yet been confirmed through the endpoint currently implemented in GARMAPR.

The stations returned by `garmap_get_stations()` reflect the stations available through the authenticated GARMAP dashboard.

## Functions

| Function | Description |
|---|---|
| `garmap_authenticate()` | Authenticate with the GARMAP data portal. |
| `garmap_get_stations()` | Retrieve available monitoring stations. |
| `garmap_get_parameters()` | Retrieve supported water-quality parameters. |
| `garmap_get_sonde_data()` | Retrieve sonde observations by station and parameter. |

## Contributing

Suggestions, bug reports, and contributions are welcome. Please submit an issue through the [GitHub repository](https://github.com/Eugies/GARMAPR/issues).

## Disclaimer

GARMAPR is an independently developed R package and is not an official product of GARMAP or the Gulf States Marine Fisheries Commission (GSMFC). Users should consult the [GARMAP data portal](https://garmapdata.gsmfc.org/) for original data and program information.

