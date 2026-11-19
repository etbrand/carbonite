.check_number <- function(x, arg, call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x)) {
    cli::cli_abort("{.arg {arg}} must be a single number.", call = call)
  }
  x
}

#' Carbon Slider
#'
#' Create a Carbon slider for choosing a number, or a range of numbers,
#' between \code{min} and \code{max}. Like \code{shiny::sliderInput()}, a
#' \code{value} of length two makes a range slider with two handles.
#'
#' \code{input$<inputId>} is a number, or a vector of two numbers for a range
#' slider. While a handle is dragged, the value reaches the server at most
#' every 250 milliseconds.
#'
#' Next to the slider is a number box for typing the value; hide it with
#' \code{hide_text_input = TRUE}. The slider fits narrow columns: its track
#' shrinks, and its number boxes are hidden while there isn't room for them.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label The slider's label.
#' @param min,max The smallest and largest values.
#' @param value The initial value: one number, or two (the start and end of
#'   a range).
#' @param step The interval between values.
#' @param hide_text_input If \code{TRUE}, hide the number box.
#' @param min_label,max_label Optional text after the minimum and maximum
#'   shown at the ends of the slider, e.g. a unit.
#' @param disabled If \code{TRUE}, the slider can't be changed.
#' @param ... Additional attributes for the underlying \code{cds-slider}
#'   element.
#'
#' @return An HTML tag representing a Carbon slider.
#'
#' @seealso \code{\link{update_carbon_slider}}
#'
#' @examples
#' carbon_slider("bins", "Number of bins", min = 1, max = 50, value = 30)
#'
#' carbon_slider(
#'   "price", "Price range",
#'   min = 0, max = 1000, value = c(200, 800), step = 10,
#'   min_label = "$", max_label = "$"
#' )
#'
#' @export
carbon_slider <- function(
  inputId,
  label,
  min,
  max,
  value,
  step = 1,
  hide_text_input = FALSE,
  min_label = NULL,
  max_label = NULL,
  disabled = FALSE,
  ...
) {
  min <- .check_number(min, "min")
  max <- .check_number(max, "max")
  step <- .check_number(step, "step")

  if (min >= max) {
    cli::cli_abort("{.arg min} must be less than {.arg max}.")
  }
  if (step <= 0) {
    cli::cli_abort("{.arg step} must be positive.")
  }
  if (!is.numeric(value) || !length(value) %in% 1:2 || anyNA(value)) {
    cli::cli_abort("{.arg value} must be one number, or two for a range.")
  }
  if (any(value < min | value > max)) {
    cli::cli_abort("{.arg value} must be between {.arg min} ({min}) and {.arg max} ({max}).")
  }
  if (length(value) == 2 && value[[1]] > value[[2]]) {
    cli::cli_abort("A range {.arg value} must be in order: start, then end.")
  }
  if (!rlang::is_bool(hide_text_input)) {
    cli::cli_abort("{.arg hide_text_input} must be {.code TRUE} or {.code FALSE}.")
  }
  if (!rlang::is_bool(disabled)) {
    cli::cli_abort("{.arg disabled} must be {.code TRUE} or {.code FALSE}.")
  }

  range <- length(value) == 2
  number_box <- function(...) {
    htmltools::tag("cds-slider-input", list(type = "number", ...))
  }

  .build_carbon_tag(
    "cds-slider",
    c(
      list(
        id = inputId,
        `label-text` = label,
        min = min,
        max = max,
        step = step,
        value = value[[1]],
        `value-upper` = if (range) value[[2]],
        `min-label` = min_label,
        `max-label` = max_label,
        `hide-text-input` = if (hide_text_input) NA,
        disabled = if (disabled) NA
      ),
      list(...),
      if (range) {
        # Carbon's two-handle slider takes the start's number box in the
        # `lower-input` slot, and recognises the end's by the id "upper".
        list(
          number_box(slot = "lower-input", `aria-label` = paste(label, "start")),
          number_box(id = "upper", `aria-label` = paste(label, "end"))
        )
      } else {
        list(number_box(`aria-label` = label))
      }
    )
  )
}

#' Update a Carbon Slider
#'
#' Change the value, limits, step, or label of a \code{carbon_slider()}, or
#' enable or disable it. Arguments left \code{NULL} are unchanged.
#'
#' @param inputId The slider's input id.
#' @param value Optional new value: one number, or two for a range slider.
#' @param min,max,step Optional new limits and step.
#' @param label Optional new label.
#' @param disabled Optional \code{TRUE} or \code{FALSE}.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_slider}}
#'
#' @examples
#' \dontrun{
#' update_carbon_slider("bins", value = 10)
#' update_carbon_slider("price", value = c(0, 500), max = 2000)
#' }
#'
#' @export
update_carbon_slider <- function(
  inputId,
  value = NULL,
  min = NULL,
  max = NULL,
  step = NULL,
  label = NULL,
  disabled = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list()

  if (!is.null(value)) {
    if (!is.numeric(value) || !length(value) %in% 1:2 || anyNA(value)) {
      cli::cli_abort("{.arg value} must be one number, or two for a range.")
    }
    # A list keeps a range as a JSON array even if both ends are equal
    msg$value <- if (length(value) == 2) as.list(value) else value
  }
  if (!is.null(min)) msg$min <- .check_number(min, "min")
  if (!is.null(max)) msg$max <- .check_number(max, "max")
  if (!is.null(step)) msg$step <- .check_number(step, "step")
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
