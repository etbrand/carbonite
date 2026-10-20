#' Carbon Design System Button
#'
#' Create a Carbon Design System button using the Carbon Web Components
#' implementation.
#'
#' This input behaves similarly to Shiny's \code{actionButton()} and generates
#' an event each time the button is clicked.
#'
#' @param inputId The input slot that will be used to access the button click
#'   event.
#' @param label The button label.
#' @param kind The Carbon button style. One of \code{"primary"},
#'   \code{"secondary"}, \code{"tertiary"}, \code{"ghost"},
#'   \code{"danger"}, \code{"danger-tertiary"}, or
#'   \code{"danger-ghost"}.
#' @param size The Carbon button size. One of \code{"xs"}, \code{"sm"},
#'   \code{"md"}, \code{"lg"}, \code{"xl"}, or \code{"2xl"}.
#'
#' @return An HTML tag representing a Carbon button.
#'
#' @examples
#' carbon_button(
#'   inputId = "run",
#'   label = "Run Analysis"
#' )
#'
#' carbon_button(
#'   inputId = "save",
#'   label = "Save",
#'   kind = "secondary"
#' )
#'
#' carbon_button(
#'   inputId = "delete",
#'   label = "Delete",
#'   kind = "danger"
#' )
#'
#' carbon_button(
#'   inputId = "launch",
#'   label = "Launch",
#'   size = "lg"
#' )
#'
#' @export
carbon_button <- function(
  inputId,
  label,
  kind = c(
    "primary",
    "secondary",
    "tertiary",
    "ghost",
    "danger",
    "danger-tertiary",
    "danger-ghost"
  ),
  size = c("md", "xs", "sm", "lg", "xl", "2xl")
) {
  kind <- match.arg(kind)
  size <- match.arg(size)
  htmltools::tag(
    "cds-button",
    list(id = inputId, kind = kind, size = size, label)
  )
}

#' Carbon Design System Select Input
#'
#' Create a Carbon Design System select input using the Carbon Web Components
#' implementation.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label Optional label displayed above the select input.
#' @param choices A named or unnamed vector of choices. Names are displayed to
#'   the user, while values are returned to the server.
#' @param selected The initially selected value. Must match one of the supplied
#'   choice values.
#' @param placeholder Optional placeholder text displayed when no value is
#'   selected.
#' @param size Optional Carbon size. Possible values are `"xs"`, `"sm"`, `"md"`, and
#'   `"lg"`.
#'
#' @return An HTML tag representing a Carbon select input.
#'
#' @examples
#' carbon_select(
#'   inputId = "species",
#'   label = "Species",
#'   choices = c(
#'     Dog = "dog",
#'     Cat = "cat",
#'     Bird = "bird"
#'   ),
#'   selected = "cat"
#' )
#'
#' carbon_select(
#'   inputId = "size",
#'   label = "Size",
#'   choices = c("Small", "Medium", "Large"),
#'   size = "sm"
#' )
#'
#' @export
carbon_select <- function(
  inputId,
  label = NULL,
  choices,
  selected = NULL,
  size = c("md", "xs", "sm", "lg"),
  placeholder = NULL
) {
  size <- match.arg(size)
  label_tag <- if (!is.null(label)) {
    htmltools::tag(
      "span",
      list(slot = "label-text", label)
    )
  }

  items <- Map(
    function(text, value) {
      attrs <- list(value = value)

      if (!is.null(selected) && identical(value, selected)) {
        attrs$selected <- TRUE
      }

      htmltools::tag(
        "cds-select-item",
        c(attrs, list(text))
      )
    },
    names(choices),
    unname(choices)
  )
  htmltools::tag(
    "cds-select",
    list(
      id = inputId,
      label = label,
      size = size,
      placeholder = placeholder,
      c(list(label_tag), items)
    )
  )
}
