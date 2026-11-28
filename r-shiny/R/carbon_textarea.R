#' Carbon Design System Text Area
#'
#' Create a Carbon text area, for text longer than one line, such as a
#' comment or description. Like \code{shiny::textAreaInput()},
#' \code{input$<inputId>} is the text typed, as a string (line breaks as
#' \code{"\\n"}).
#'
#' With \code{max_count}, a counter shows how much of the limit is used, and
#' typing stops at the limit.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label Optional label displayed above the text area.
#' @param value Optional initial text.
#' @param rows The height of the text area, in lines of text. The user can
#'   resize it.
#' @param placeholder Optional placeholder text displayed when the text area
#'   is empty.
#' @param helper_text Optional helper text displayed below the text area.
#' @param max_count Optional limit on the length of the text, shown by a
#'   counter.
#' @param count_by What \code{max_count} counts: \code{"character"} or
#'   \code{"word"}.
#' @param ... Additional attributes passed to the underlying
#'   \code{cds-textarea} element, e.g. \code{disabled = NA}.
#'
#' @return An HTML tag representing a Carbon text area.
#'
#' @seealso \code{\link{update_carbon_textarea}},
#'   \code{\link{carbon_text_input}}
#'
#' @examples
#' carbon_textarea("comments", "Comments", placeholder = "Anything to add?")
#'
#' carbon_textarea(
#'   "summary",
#'   "Summary",
#'   rows = 6,
#'   helper_text = "Describe the change in a few sentences.",
#'   max_count = 100,
#'   count_by = "word"
#' )
#'
#' @export
carbon_textarea <- function(
  inputId,
  label = NULL,
  value = NULL,
  rows = 4,
  placeholder = NULL,
  helper_text = NULL,
  max_count = NULL,
  count_by = c("character", "word"),
  ...
) {
  count_by <- match.arg(count_by)

  if (!is.null(value) && !rlang::is_string(value)) {
    cli::cli_abort("{.arg value} must be a single string or {.code NULL}.")
  }
  if (!is.numeric(rows) || length(rows) != 1 || is.na(rows) || rows < 1 || rows != round(rows)) {
    cli::cli_abort("{.arg rows} must be a whole number of at least 1.")
  }
  if (!is.null(max_count) && (!is.numeric(max_count) || length(max_count) != 1 || is.na(max_count) || max_count < 1 || max_count != round(max_count))) {
    cli::cli_abort("{.arg max_count} must be a whole number of at least 1, or {.code NULL}.")
  }

  .build_carbon_tag(
    "cds-textarea",
    c(
      list(
        id = inputId,
        label = label,
        rows = rows,
        placeholder = placeholder,
        `helper-text` = helper_text,
        `enable-counter` = if (!is.null(max_count)) NA,
        `max-count` = max_count,
        `counter-mode` = if (!is.null(max_count)) count_by,
        value = value
      ),
      list(...)
    )
  )
}

#' Update a Carbon Text Area
#'
#' Change the text, placeholder, or helper text of a
#' \code{carbon_textarea()}. Arguments left \code{NULL} are unchanged.
#'
#' @inheritParams update_carbon_text_input
#' @param inputId The input slot of the text area to update.
#' @param value An optional new text; \code{""} clears it.
#' @param ... Additional properties to update on the underlying Carbon text
#'   area element, e.g. \code{disabled = TRUE} or \code{rows = 8}.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_textarea}}
#'
#' @examples
#' \dontrun{
#' update_carbon_textarea("comments", value = "")
#' }
#'
#' @export
update_carbon_textarea <- function(
  inputId,
  value = NULL,
  placeholder = NULL,
  helper_text = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  # The same element properties and binding as a text input
  update_carbon_text_input(
    inputId,
    value = value,
    placeholder = placeholder,
    helper_text = helper_text,
    ...,
    session = session
  )
  invisible(NULL)
}
