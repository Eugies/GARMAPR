#' Retrieve GARMAP sonde data
#'
#' Retrieves observations for a specified GARMAP station and parameter.
#'
#' @param auth Authentication object returned by garmap_authenticate().
#' @param station GARMAP station identifier, e.g. "MS00006".
#' @param parameter Parameter code, e.g. "SAL_PSU" or "TEMP_C".
#'
#' @return A data frame containing date and value columns.
#' @export

garmap_get_sonde_data <- function(
    auth,
    station,
    parameter
) {

  if (!inherits(auth, "garmap_auth")) {
    stop("Please provide an authentication object from garmap_authenticate().")
  }

  if (!file.exists(auth$cookie_file)) {
    stop("Authentication session not found. Please log in again.")
  }

  data_url <- paste0(
    auth$base_url,
    "/qry/qryGetSondeDetailData.php"
  )
  # Allow multiple stations and parameters
  station <- as.character(station)
  parameter <- as.character(parameter)

  # Expand "all" to the available stations
  if (length(station) == 1 && tolower(station) == "all") {
    station <- garmap_get_stations(auth)$station
  }

  # Expand "all" to the available parameters
  if (length(parameter) == 1 && tolower(parameter) == "all") {
    parameter <- garmap_get_parameters()$parameter
  }

  # Check inputs
  if (length(station) == 0 || anyNA(station) || any(station == "")) {
    stop("Please provide at least one valid station.", call. = FALSE)
  }

  if (length(parameter) == 0 || anyNA(parameter) || any(parameter == "")) {
    stop("Please provide at least one valid parameter.", call. = FALSE)
  }

  if (any(tolower(station) == "all") ||
      any(tolower(parameter) == "all")) {
    stop("'all' cannot be combined with individual station or parameter values.",
         call. = FALSE)
  }

  # Retrieve multiple station/parameter combinations
  if (length(station) > 1 || length(parameter) > 1) {

    combinations <- expand.grid(
      station = station,
      parameter = parameter,
      stringsAsFactors = FALSE
    )

    results <- lapply(seq_len(nrow(combinations)), function(i) {

      garmap_get_sonde_data(
        auth = auth,
        station = combinations$station[i],
        parameter = combinations$parameter[i]
      )

    })

    # Combine all results
    combined_data <- do.call(rbind, results)
    rownames(combined_data) <- NULL

    # Preserve the available date ranges for each combination
    available_ranges <- do.call(rbind, lapply(seq_along(results), function(i) {

      date_range <- attr(results[[i]], "available_range")

      data.frame(
        station = combinations$station[i],
        parameter = combinations$parameter[i],
        available_range = paste(date_range, collapse = " to "),
        stringsAsFactors = FALSE
      )

    }))

    attr(combined_data, "available_ranges") <- available_ranges

    return(combined_data)
  }
  # Retrieve data using the authenticated session
  response <- httr2::request(data_url) |>
    httr2::req_url_query(
      c = parameter,
      s = station
    ) |>
    httr2::req_user_agent(
      paste(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "AppleWebKit/537.36 (KHTML, like Gecko)",
        "Chrome/157.0.0.0 Safari/537.36"
      )
    ) |>
    httr2::req_headers(
      Accept = "application/json, text/javascript, */*; q=0.01",
      Referer = paste0(auth$base_url, "/home.php"),
      `X-Requested-With` = "XMLHttpRequest"
    ) |>
    httr2::req_cookie_preserve(auth$cookie_file) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_status(response) != 200) {
    stop(
      "GARMAP data request failed. HTTP status: ",
      httr2::resp_status(response)
    )
  }

  # Check response content type
  content_type <- httr2::resp_header(response, "content-type")

  if (is.null(content_type) || !grepl("application/json", content_type)) {
    stop("Expected JSON response. The session may have expired.")
  }

  # Parse JSON
  result <- jsonlite::fromJSON(
    httr2::resp_body_string(response)
  )

  if (is.null(result$Records)) {
    stop("No Records element found in the GARMAP response.")
  }

  # Convert to a clean data frame
  data <- data.frame(
    date = as.Date(result$Records$x),
    value = result$Records$y
  )

  # Add station and parameter identifiers
  data$station <- station
  data$parameter <- parameter

  # Preserve the available date range
  attr(data, "available_range") <- result$Range

  return(data)
}
