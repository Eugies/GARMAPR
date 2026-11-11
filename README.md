GARMAPR

An R package for accessing water quality data from the Gulf of America Regional Monitoring and Assessment Program (GARMAP).

Overview

GARMAPR provides an interface for accessing water quality observations from the GARMAP monitoring database. The package allows users to authenticate with GARMAP, identify available monitoring stations, retrieve available water quality parameters, and download observations from individual or multiple stations.


Installation

Install GARMAPR directly from GitHub using remotes:

install.packages("remotes")

remotes::install_github("Eugies/GARMAPR")

Load the package:

library(GARMAPR)

Authenticate using:

auth <- garmap_authenticate()

The function prompts for your GARMAP email address and password and returns an authentication object containing the session information required for subsequent requests. If you do not have a login, p[lease request one from https://garmap.gsmfc.org/contact.php

Available functions

Function

Description

garmap_authenticate()

Authenticates with the GARMAP database.

garmap_get_stations()

Retrieves available monitoring stations.

garmap_get_parameters()

Lists available sonde parameters.

garmap_get_sonde_data()

Retrieves water quality observations for specified stations and parameters.

Retrieving monitoring stations

Retrieve the monitoring stations available through your authenticated dashboard:

stations <- garmap_get_stations(auth)

head(stations)

The returned data frame contains station identifiers and station names.

Retrieving available parameters

List the supported sonde parameters:

parameters <- garmap_get_parameters()

print(parameters)

Retrieving sonde data

Retrieve observations for an individual station and parameter:

salinity <- garmap_get_sonde_data(
  auth = auth,
  station = "MS00006",
  parameter = "SAL_PSU"
)

The returned data frame contains:

Column

Description

date

Date of observation.

value

Measured water quality value.

station

GARMAP monitoring station identifier.

parameter

Water quality parameter code.

The function retrieves all observations returned by the GARMAP endpoint for the selected station and parameter.

Retrieving multiple stations and parameters

GARMAPR supports retrieving data from multiple stations and parameters in a single function call.

For example, retrieve salinity observations from two monitoring stations:

salinity <- garmap_get_sonde_data(
  auth = auth,
  station = c("MS00006", "MS00060"),
  parameter = "SAL_PSU"
)

Retrieve multiple parameters from a single station:

water_quality <- garmap_get_sonde_data(
  auth = auth,
  station = "MS00006",
  parameter = c("TEMP_C", "SAL_PSU", "ODO")
)

To retrieve all stations and supported parameters available through the package:

all_data <- garmap_get_sonde_data(
  auth = auth,
  station = "all",
  parameter = "all"
)

The returned data are combined into one data frame, with station and parameter identifiers retained for each observation.

Temporal resolution

The current sonde data retrieval function accesses the GARMAP detail-data endpoint, which returns date-based observations. The returned timestamps are currently formatted as calendar dates (YYYY-MM-DD).

Although historical GARMAP documentation describes sonde measurements collected at 30-minute intervals, retrieval of those individual high-frequency observations has not yet been established through the current endpoint.

Dependencies

GARMAPR uses the following R packages:

httr2 — HTTP requests and authenticated sessions.

jsonlite — JSON response processing.

rstudioapi — Secure password prompting in RStudio.

Development status

GARMAPR is currently under development. Additional functionality and data retrieval capabilities may be added as the GARMAP database interface is further investigated.

License

MIT License.
