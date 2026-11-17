#' Carbon Design System Password Input
#'
#' Create a Carbon password input: a text box whose characters are masked,
#' with a button to show or hide them. Like \code{shiny::passwordInput()},
#' \code{input$<inputId>} is the text typed, as a string.
#'
#' The value reaches the server the same way as any other input, so use
#' HTTPS for apps that ask for real passwords.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label Optional label displayed above the input.
#' @param value Optional initial value.
#' @param size The input size. One of \code{"md"}, \code{"xs"}, \code{"sm"},
#'   or \code{"lg"}.
#' @param placeholder Optional placeholder text displayed when the input is
#'   empty.
#' @param helper_text Optional helper text displayed below the input.
#' @param show_password_label,hide_password_label The show/hide button's
#'   tooltip and accessible name, e.g. for translation.
#' @param autocomplete What browsers may autofill: \code{"current-password"}
#'   (the default) for signing in, \code{"new-password"} for choosing a
#'   password, or \code{"off"}.
#' @param ... Additional attributes passed to the underlying
#'   \code{cds-password-input} element, e.g. \code{disabled = NA}.
#'
#' @return An HTML tag representing a Carbon password input.
#'
#' @seealso \code{\link{update_carbon_password_input}},
#'   \code{\link{carbon_text_input}}
#'
#' @examples
#' carbon_password_input("password", "Password")
#'
#' carbon_password_input(
#'   "new_password",
#'   "New password",
#'   helper_text = "At least 12 characters.",
#'   autocomplete = "new-password"
#' )
#'
#' @export
carbon_password_input <- function(
  inputId,
  label = NULL,
  value = NULL,
  size = c("md", "xs", "sm", "lg"),
  placeholder = NULL,
  helper_text = NULL,
  show_password_label = "Show password",
  hide_password_label = "Hide password",
  autocomplete = "current-password",
  ...
) {
  size <- match.arg(size)

  if (!is.null(value) && !rlang::is_string(value)) {
    cli::cli_abort("{.arg value} must be a single string or {.code NULL}.")
  }
  if (!rlang::is_string(autocomplete)) {
    cli::cli_abort("{.arg autocomplete} must be a single string, e.g. {.val new-password}.")
  }

  .build_carbon_tag(
    "cds-password-input",
    c(
      list(
        id = inputId,
        label = label,
        value = value,
        size = size,
        placeholder = placeholder,
        `helper-text` = helper_text,
        `show-password-label` = show_password_label,
        `hide-password-label` = hide_password_label,
        autocomplete = autocomplete
      ),
      list(...)
    )
  )
}

#' Update a Carbon Password Input
#'
#' Change the value, placeholder, or helper text of a
#' \code{carbon_password_input()}, e.g. clear it after use. Arguments left
#' \code{NULL} are unchanged.
#'
#' @inheritParams update_carbon_text_input
#' @param inputId The input slot of the password input to update.
#' @param value An optional new value; \code{""} clears the input.
#' @param ... Additional properties to update on the underlying Carbon
#'   password input element, e.g. \code{disabled = TRUE}.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_password_input}}
#'
#' @examples
#' \dontrun{
#' update_carbon_password_input("password", value = "")
#' }
#'
#' @export
update_carbon_password_input <- function(
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
