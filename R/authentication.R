#' Authenticate with the GARMAP database
#'
#' Logs in to GARMAP and stores the session cookie for subsequent requests.
#'
#' @param username GARMAP email address. Prompts if NULL.
#' @param password GARMAP password. Prompts securely if NULL.
#' @param base_url GARMAP website URL.
#'
#' @return An authentication object containing the session cookie file.
#' @export

garmap_authenticate <- function(
    username = NULL,
    password = NULL,
    base_url = "https://garmapdata.gsmfc.org"
) {

  # Prompt for email
  if (is.null(username)) {
    username <- readline("GARMAP email: ")
  }

  # Prompt securely for password
  if (is.null(password)) {
    if (!requireNamespace("rstudioapi", quietly = TRUE)) {
      stop("Install rstudioapi to securely enter your password.")
    }

    password <- rstudioapi::askForPassword("GARMAP password")
  }

  if (!nzchar(username) || !nzchar(password)) {
    stop("Email and password must not be empty.")
  }

  login_url <- paste0(base_url, "/index.php")

  # Create a persistent cookie jar
  cookie_file <- tempfile(fileext = ".txt")

  # Common browser-like request
  browser_request <- function(url) {
    httr2::request(url) |>
      httr2::req_user_agent(
        paste(
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
          "AppleWebKit/537.36 (KHTML, like Gecko)",
          "Chrome/157.0.0.0 Safari/537.36"
        )
      ) |>
      httr2::req_headers(
        Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      ) |>
      httr2::req_cookie_preserve(cookie_file)
  }

  # 1. GET login page
  login_page <- browser_request(login_url) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_status(login_page) != 200) {
    stop("Could not access the GARMAP login page.")
  }

  # 2. POST login credentials
  login_response <- browser_request(login_url) |>
    httr2::req_headers(Referer = login_url) |>
    httr2::req_method("POST") |>
    httr2::req_body_form(
      user_name = username,
      password = password,
      login = ""
    ) |>
    httr2::req_options(followlocation = FALSE) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()

  redirect <- httr2::resp_header(login_response, "location")

  if (
    httr2::resp_status(login_response) != 302 ||
    is.null(redirect) ||
    !grepl("home\\.php", redirect)
  ) {
    unlink(cookie_file)
    stop("GARMAP login was unsuccessful. Check your credentials.")
  }

  message("Successfully authenticated with GARMAP.")

  # Return reusable authentication object
  structure(
    list(
      cookie_file = cookie_file,
      base_url = base_url,
      username = username
    ),
    class = "garmap_auth"
  )
}
