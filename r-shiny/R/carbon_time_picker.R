# "HH:MM" (24-hour) as hours and minutes, or NULL if it isn't a time.
.parse_time <- function(x) {
  match <- regmatches(x, regexec("^([01]?[0-9]|2[0-3]):([0-5][0-9])$", x))[[1]]
  if (!length(match)) {
    return(NULL)
  }
  list(hour = as.integer(match[[2]]), minute = as.integer(match[[3]]))
}

.check_time <- function(value, arg = "value", call = rlang::caller_env()) {
  if (is.null(value)) {
    return(NULL)
  }
  if (!rlang::is_string(value) || is.null(.parse_time(value))) {
    cli::cli_abort("{.arg {arg}} must be a 24-hour time like {.val 09:30} or {.val 14:30}.", call = call)
  }
  .parse_time(value)
}

#' Carbon Time Picker
#'
#' Create a Carbon time picker: a box for typing a time, with an AM/PM
#' selector on a 12-hour clock.
#'
#' Whatever the clock, \code{input$<inputId>} is the time as a 24-hour
#' \code{"HH:MM"} string (e.g. \code{"14:30"}), or \code{NULL} while the box
#' is empty or doesn't hold a valid time. A time that isn't valid is shown
#' as an error once the user leaves the box. Convert the value with e.g.
#' \code{as.POSIXct(paste(date, input$time))} or
#' \code{hms::parse_hm(input$time)}.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label The label shown above the time picker.
#' @param value Optional initial time, as a 24-hour \code{"HH:MM"} string,
#'   e.g. \code{"14:30"}.
#' @param clock \code{"12"} for a 12-hour clock with an AM/PM selector (the
#'   default, as in Carbon), or \code{"24"} for a 24-hour clock.
#' @param size The input size. One of \code{"md"}, \code{"sm"}, or
#'   \code{"lg"}.
#' @param placeholder Placeholder text for the empty box.
#' @param invalid_text The message shown when the box doesn't hold a valid
#'   time.
#' @param disabled If \code{TRUE}, the time can't be changed.
#'
#' @return An HTML tag representing a Carbon time picker.
#'
#' @seealso \code{\link{update_carbon_time_picker}},
#'   \code{\link{carbon_date_picker}}
#'
#' @examples
#' carbon_time_picker("start", "Start time", value = "09:30")
#'
#' carbon_time_picker("alarm", "Alarm", value = "06:45", clock = "24", size = "sm")
#'
#' @export
carbon_time_picker <- function(
  inputId,
  label = "Select a time",
  value = NULL,
  clock = c("12", "24"),
  size = c("md", "sm", "lg"),
  placeholder = "hh:mm",
  invalid_text = NULL,
  disabled = FALSE
) {
  clock <- match.arg(clock)
  size <- match.arg(size)
  time <- .check_time(value)

  if (!rlang::is_bool(disabled)) {
    cli::cli_abort("{.arg disabled} must be {.code TRUE} or {.code FALSE}.")
  }

  twelve <- clock == "12"
  if (is.null(invalid_text)) {
    invalid_text <- if (twelve) "Enter a time like 9:30, then choose AM or PM." else "Enter a 24-hour time like 14:30."
  }

  text <- NULL
  period <- "AM"
  if (!is.null(time)) {
    if (twelve) {
      period <- if (time$hour >= 12) "PM" else "AM"
      text <- sprintf("%d:%02d", (time$hour + 11) %% 12 + 1, time$minute)
    } else {
      text <- sprintf("%02d:%02d", time$hour, time$minute)
    }
  }

  .build_carbon_tag(
    "cds-time-picker",
    list(
      id = inputId,
      `label-text` = label,
      value = text,
      size = size,
      placeholder = placeholder,
      `invalid-text` = invalid_text,
      # srcjs/bindings/carbon-time-picker.js parses the text by clock
      `data-clock` = clock,
      # Carbon's default pattern is the 12-hour one
      pattern = if (!twelve) "([01]?[0-9]|2[0-3]):[0-5][0-9]",
      disabled = if (disabled) NA,
      if (twelve) {
        htmltools::tag(
          "cds-time-picker-select",
          list(
            `aria-label` = "AM or PM",
            value = period,
            size = size,
            disabled = if (disabled) NA,
            htmltools::tag("cds-select-item", list(value = "AM", "AM")),
            htmltools::tag("cds-select-item", list(value = "PM", "PM"))
          )
        )
      }
    )
  )
}

#' Update a Carbon Time Picker
#'
#' Change the time or label of a \code{carbon_time_picker()}, or enable or
#' disable it. Arguments left \code{NULL} are unchanged.
#'
#' @param inputId The time picker's input id.
#' @param value Optional new time, as a 24-hour \code{"HH:MM"} string;
#'   \code{""} clears it.
#' @param label Optional new label.
#' @param disabled Optional \code{TRUE} or \code{FALSE}.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_time_picker}}
#'
#' @examples
#' \dontrun{
#' update_carbon_time_picker("start", value = "13:00")
#' update_carbon_time_picker("start", value = "")
#' }
#'
#' @export
update_carbon_time_picker <- function(
  inputId,
  value = NULL,
  label = NULL,
  disabled = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list()

  if (!is.null(value)) {
    if (!identical(value, "")) {
      time <- .check_time(value)
      value <- sprintf("%02d:%02d", time$hour, time$minute)
    }
    msg$value <- value
  }
  if (!is.null(label)) msg$labelText <- label
  if (!is.null(disabled)) {
    if (!rlang::is_bool(disabled)) {
      cli::cli_abort("{.arg disabled} must be {.code TRUE}, {.code FALSE}, or {.code NULL}.")
    }
    msg$disabled <- disabled
  }

  session$sendInputMessage(inputId, msg)

  invisible(NULL)
}
