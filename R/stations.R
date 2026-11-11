#' Retrieve stations displayed on the GARMAP sonde dashboard
#'
#' Reads the authenticated GARMAP dashboard and extracts the station IDs and
#' station names from its station-detail links.
#'
#' @param auth An authenticated GARMAP session returned by
#'   [garmap_authenticate()].
#'
#' @return A data frame with `station` and `station_name` columns.
#' @export
#'
#' @examples
#' \dontrun{
#' auth <- garmap_authenticate()
#' stations <- garmap_get_stations(auth)
#' }
garmap_get_stations <- function(auth) {

  # Check authentication object
  if (!inherits(auth, "garmap_auth")) {
    stop("Please provide an authenticated session from garmap_authenticate().",
         call. = FALSE)
  }

  if (is.null(auth$cookie_file) || !file.exists(auth$cookie_file)) {
    stop("The authentication cookie file is missing. Please authenticate again.",
         call. = FALSE)
  }

  # Request the authenticated dashboard
  dashboard_url <- paste0(sub("/$", "", auth$base_url), "/home.php")

  response <- httr2::request(dashboard_url) |>
    httr2::req_user_agent(
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/157.0.0.0 Safari/537.36"
    ) |>
    httr2::req_headers(
      Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      Referer = paste0(sub("/$", "", auth$base_url), "/")
    ) |>
    httr2::req_cookie_preserve(auth$cookie_file) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_status(response) != 200) {
    stop(
      "Could not retrieve the GARMAP dashboard (HTTP ",
      httr2::resp_status(response),
      "). Please authenticate again and retry.",
      call. = FALSE
    )
  }

  dashboard_html <- httr2::resp_body_string(response)

  # Extract station-detail links from the dashboard HTML
  anchor_pattern <- "(?is)<a\\b[^>]*href=[\"'][^\"']*details\\.php\\?s=([^\"']+)[\"'][^>]*>(.*?)</a>"
  anchors <- regmatches(
    dashboard_html,
    gregexpr(anchor_pattern, dashboard_html, perl = TRUE)
  )[[1]]

  if (length(anchors) == 0 || identical(anchors, character(0))) {
    stop(
      "No station links were found on the GARMAP dashboard. The session may have expired, or the dashboard HTML may have changed.",
      call. = FALSE
    )
  }

  station_info <- lapply(anchors, function(anchor) {
    parts <- regmatches(
      anchor,
      regexec(anchor_pattern, anchor, perl = TRUE)
    )[[1]]

    station_id <- sub("&amp;.*$", "", parts[2])
    station_name <- gsub("<[^>]+>", "", parts[3])
    station_name <- gsub("&nbsp;", " ", station_name, fixed = TRUE)
    station_name <- gsub("&amp;", "&", station_name, fixed = TRUE)
    station_name <- gsub("&quot;", "\"", station_name, fixed = TRUE)
    station_name <- gsub("&#39;", "'", station_name, fixed = TRUE)
    station_name <- gsub("&lt;", "<", station_name, fixed = TRUE)
    station_name <- gsub("&gt;", ">", station_name, fixed = TRUE)
    station_name <- trimws(station_name)

    # The dashboard appends deployment counts in parentheses to some names.
    station_name <- sub("\\s*\\([0-9,]+\\)\\s*$", "", station_name)

    data.frame(
      station = station_id,
      station_name = station_name,
      stringsAsFactors = FALSE
    )
  })

  stations <- do.call(rbind, station_info)
  stations <- stations[!duplicated(stations$station), , drop = FALSE]
  rownames(stations) <- NULL

  stations
}


#' Retrieve the GARMAP sonde parameter codes
#'
#' Returns the parameter codes used by the GARMAP sonde dashboard and by
#' [garmap_get_sonde_data()]. The codes are based on the dashboard requests:
#' temperature, salinity, and dissolved oxygen.
#'
#' @return A data frame with `parameter` and `parameter_name` columns.
#' @export
#'
#' @examples
#' parameters <- garmap_get_parameters()
garmap_get_parameters <- function() {

  data.frame(
    parameter = c("TEMP_C", "SAL_PSU", "ODO"),
    parameter_name = c("Temperature", "Salinity", "Dissolved Oxygen"),
    stringsAsFactors = FALSE
  )
}
