#' Carbon Design System Toggle
#'
#' Create a Carbon toggle switch, for turning a setting on or off.
#'
#' This input behaves like \code{shiny::checkboxInput()}: its value is
#' \code{TRUE} when the toggle is on and \code{FALSE} when it is off.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label Optional label displayed above the toggle.
#' @param value The initial state: \code{TRUE} for on, \code{FALSE} for off.
#' @param on_label,off_label The text shown next to the switch when it is on
#'   or off. Use \code{""} to show no text.
#' @param size The toggle size. One of \code{"md"} or \code{"sm"}.
#' @param ... Additional attributes passed to the underlying Carbon toggle
#'   element, e.g. \code{disabled = NA}.
#'
#' @return An HTML tag representing a Carbon toggle.
#'
#' @seealso \code{\link{update_carbon_toggle}}
#'
#' @examples
#' carbon_toggle("notifications", "Email notifications")
#'
#' carbon_toggle(
#'   "dark_mode",
#'   "Dark mode",
#'   value = TRUE,
#'   on_label = "Enabled",
#'   off_label = "Disabled",
#'   size = "sm"
#' )
#'
#' @export
carbon_toggle <- function(
  inputId,
  label = NULL,
  value = FALSE,
  on_label = "On",
  off_label = "Off",
  size = c("md", "sm"),
  ...
) {
  size <- match.arg(size)

  if (!rlang::is_bool(value)) {
    cli::cli_abort("{.arg value} must be {.code TRUE} or {.code FALSE}.")
  }

  .build_carbon_tag(
    "cds-toggle",
    c(
      list(
        id = inputId,
        `label-text` = label,
        toggled = if (value) NA,
        `label-a` = on_label,
        `label-b` = off_label,
        # Carbon's default (medium) size is no size attribute
        size = if (size == "sm") "sm"
      ),
      list(...)
    )
  )
}

#' Update a Carbon Toggle
#'
#' Update the state or labels of an existing Carbon toggle.
#'
#' @param inputId The input slot of the toggle to update.
#' @param value Optional new state: \code{TRUE} for on, \code{FALSE} for off.
#'   If \code{NULL}, the state is unchanged.
#' @param label Optional new label. If \code{NULL}, the label is unchanged.
#' @param on_label,off_label Optional new text shown next to the switch when
#'   it is on or off. If \code{NULL}, the text is unchanged.
#' @param ... Additional properties to update on the underlying Carbon
#'   toggle element, e.g. \code{disabled = TRUE}.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_toggle}}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' update_carbon_toggle("notifications", value = FALSE)
#'
#' update_carbon_toggle("notifications", label = "Notifications", disabled = TRUE)
#' }
update_carbon_toggle <- function(
  inputId,
  value = NULL,
  label = NULL,
  on_label = NULL,
  off_label = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(...)

  if (!is.null(value)) {
    if (!rlang::is_bool(value)) {
      cli::cli_abort("{.arg value} must be {.code TRUE}, {.code FALSE}, or {.code NULL}.")
    }
    msg$toggled <- value
  }

  if (!is.null(label)) {
    msg$labelText <- label
  }

  if (!is.null(on_label)) {
    msg$labelA <- on_label
  }

  if (!is.null(off_label)) {
    msg$labelB <- off_label
  }

  session$sendInputMessage(inputId, msg)
}
