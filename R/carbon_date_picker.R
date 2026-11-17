# Dates as Carbon wants them: ISO 8601 strings (YYYY-MM-DD).
.iso_date <- function(x, arg, call = rlang::caller_env()) {
  if (is.null(x)) {
    return(NULL)
  }

  date <- tryCatch(as.Date(x), error = function(e) NA)
  if (length(x) != 1 || is.na(date)) {
    cli::cli_abort("{.arg {arg}} must be a single date, e.g. {.val 2026-01-31} or {.code Sys.Date()}.", call = call)
  }

  format(date, "%Y-%m-%d")
}

.check_date_limits <- function(min, max, call = rlang::caller_env()) {
  if (!is.null(min) && !is.null(max) && min > max) {
    cli::cli_abort("{.arg min} must not be after {.arg max}.", call = call)
  }
}

.date_picker_tag <- function(
  inputId,
  value,
  min,
  max,
  date_format,
  disabled,
  inputs,
  attribs,
  call = rlang::caller_env()
) {
  if (!rlang::is_string(date_format)) {
    cli::cli_abort("{.arg date_format} must be a single string.", call = call)
  }
  if (!rlang::is_bool(disabled)) {
    cli::cli_abort("{.arg disabled} must be {.code TRUE} or {.code FALSE}.", call = call)
  }

  .build_carbon_tag(
    "cds-date-picker",
    c(
      list(
        id = inputId,
        value = value,
        `min-date` = min,
        `max-date` = max,
        `date-format` = date_format,
        disabled = if (disabled) NA
      ),
      attribs,
      inputs
    )
  )
}

.date_input_tag <- function(kind, label, placeholder, size) {
  htmltools::tag(
    "cds-date-picker-input",
    list(
      kind = kind,
      `label-text` = label,
      placeholder = placeholder,
      size = size
    )
  )
}

#' Carbon Date Picker
#'
#' Create a Carbon date picker: a text box with a calendar for picking a
#' date. Like \code{shiny::dateInput()}, \code{input$<inputId>} is a
#' \code{Date}, of length zero while no date is chosen.
#'
#' The user can pick a date in the calendar or type one in the box, in
#' \code{date_format}.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label The date picker's label.
#' @param value Optional initial date: a \code{Date} or a
#'   \code{"YYYY-MM-DD"} string.
#' @param min,max Optional earliest and latest dates that can be picked.
#' @param date_format How dates are shown and typed, in Flatpickr's format
#'   tokens: e.g. \code{"m/d/Y"} (the default, Carbon's), \code{"d/m/Y"}, or
#'   \code{"Y-m-d"}. The input's value is a \code{Date} whatever the format.
#' @param placeholder Placeholder text for an empty box. Match it to
#'   \code{date_format}.
#' @param size The box height. One of \code{"md"}, \code{"sm"}, or
#'   \code{"lg"}.
#' @param disabled If \code{TRUE}, the date can't be changed.
#' @param ... Additional attributes for the underlying
#'   \code{cds-date-picker} element.
#'
#' @return An HTML tag representing a Carbon date picker.
#'
#' @seealso \code{\link{carbon_date_range_picker}},
#'   \code{\link{update_carbon_date_picker}}
#'
#' @examples
#' carbon_date_picker("due", "Due date", value = "2026-12-01")
#'
#' carbon_date_picker(
#'   "start", "Start date",
#'   min = Sys.Date(), date_format = "d/m/Y", placeholder = "dd/mm/yyyy"
#' )
#'
#' @export
carbon_date_picker <- function(
  inputId,
  label,
  value = NULL,
  min = NULL,
  max = NULL,
  date_format = "m/d/Y",
  placeholder = "mm/dd/yyyy",
  size = c("md", "sm", "lg"),
  disabled = FALSE,
  ...
) {
  size <- match.arg(size)
  min <- .iso_date(min, "min")
  max <- .iso_date(max, "max")
  .check_date_limits(min, max)

  .date_picker_tag(
    inputId,
    value = .iso_date(value, "value"),
    min = min,
    max = max,
    date_format = date_format,
    disabled = disabled,
    inputs = list(.date_input_tag("single", label, placeholder, size)),
    attribs = list(...)
  )
}

#' Carbon Date Range Picker
#'
#' Create a Carbon date picker for a range of dates: start and end boxes
#' sharing one calendar. Like \code{shiny::dateRangeInput()},
#' \code{input$<inputId>} is a \code{Date} vector of the start and end, with
#' \code{NA} for an end that isn't chosen.
#'
#' Picking a range takes two clicks in the calendar; the input updates once
#' both ends are picked.
#'
#' @inheritParams carbon_date_picker
#' @param label_start,label_end Labels for the start and end boxes.
#' @param start,end Optional initial dates: \code{Date}s or
#'   \code{"YYYY-MM-DD"} strings.
#' @param ... Additional attributes for the underlying
#'   \code{cds-date-picker} element.
#'
#' @return An HTML tag representing a Carbon date range picker.
#'
#' @seealso \code{\link{carbon_date_picker}},
#'   \code{\link{update_carbon_date_picker}}
#'
#' @examples
#' carbon_date_range_picker(
#'   "period",
#'   start = "2026-01-01", end = "2026-03-31"
#' )
#'
#' @export
carbon_date_range_picker <- function(
  inputId,
  label_start = "Start date",
  label_end = "End date",
  start = NULL,
  end = NULL,
  min = NULL,
  max = NULL,
  date_format = "m/d/Y",
  placeholder = "mm/dd/yyyy",
  size = c("md", "sm", "lg"),
  disabled = FALSE,
  ...
) {
  size <- match.arg(size)
  start <- .iso_date(start, "start")
  end <- .iso_date(end, "end")
  min <- .iso_date(min, "min")
  max <- .iso_date(max, "max")
  .check_date_limits(min, max)

  if (is.null(start) && !is.null(end)) {
    cli::cli_abort("An {.arg end} needs a {.arg start}.")
  }
  if (!is.null(start) && !is.null(end) && start > end) {
    cli::cli_abort("{.arg start} must not be after {.arg end}.")
  }

  .date_picker_tag(
    inputId,
    # Carbon's range value: "start/end"
    value = if (!is.null(start)) paste(c(start, end), collapse = "/"),
    min = min,
    max = max,
    date_format = date_format,
    disabled = disabled,
    inputs = list(
      .date_input_tag("from", label_start, placeholder, size),
      .date_input_tag("to", label_end, placeholder, size)
    ),
    attribs = list(...)
  )
}

#' Update a Carbon Date Picker
#'
#' Change the date(s) or limits of a \code{carbon_date_picker()} or
#' \code{carbon_date_range_picker()}. Arguments left \code{NULL} are
#' unchanged.
#'
#' @param inputId The date picker's input id.
#' @param value Optional new date (for a range picker, the start and end).
#'   \code{NA} or \code{character(0)} clears it.
#' @param min,max Optional new earliest and latest dates.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_date_picker}},
#'   \code{\link{carbon_date_range_picker}}
#'
#' @examples
#' \dontrun{
#' update_carbon_date_picker("due", value = Sys.Date() + 7)
#' update_carbon_date_picker("period", value = c("2026-04-01", "2026-06-30"))
#' update_carbon_date_picker("due", value = NA)
#' }
#'
#' @export
update_carbon_date_picker <- function(
  inputId,
  value = NULL,
  min = NULL,
  max = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list()

  if (!is.null(value)) {
    if (!length(value) || all(is.na(value))) {
      msg$value <- ""
    } else if (length(value) > 2) {
      cli::cli_abort("{.arg value} must be one date, or two for a range.")
    } else {
      dates <- vapply(seq_along(value), function(i) .iso_date(value[[i]], "value"), character(1))
      if (length(dates) == 2 && dates[[1]] > dates[[2]]) {
        cli::cli_abort("A range {.arg value} must be in order: start, then end.")
      }
      msg$value <- paste(dates, collapse = "/")
    }
  }
  if (!is.null(min)) msg$minDate <- .iso_date(min, "min")
  if (!is.null(max)) msg$maxDate <- .iso_date(max, "max")

  session$sendInputMessage(inputId, msg)

  invisible(NULL)
}
