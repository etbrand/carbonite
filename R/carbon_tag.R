.tag_types <- c(
  "gray",
  "cool-gray",
  "warm-gray",
  "red",
  "magenta",
  "purple",
  "blue",
  "cyan",
  "teal",
  "green",
  "high-contrast",
  "outline"
)


# Shared attributes of all tag variants. Carbon only shows the icon at md
# and lg sizes.
.tag_attribs <- function(size, disabled, icon, call = rlang::caller_env()) {
  if (!rlang::is_bool(disabled)) {
    cli::cli_abort(
      "{.arg disabled} must be {.code TRUE} or {.code FALSE}.",
      call = call
    )
  }
  if (!is.null(icon) && size == "sm") {
    cli::cli_warn(
      "Carbon doesn't show icons on {.val sm} tags; use {.code size = \"md\"} or {.val lg}.",
      call = call
    )
  }

  list(
    size = size,
    disabled = if (disabled) NA,
    if (!is.null(icon)) .slot_icon(icon, slot = "icon", call = call)
  )
}

# Interactive variants take their text as the `text` attribute, not as content.
.check_tag_text <- function(label, call = rlang::caller_env()) {
  if (!rlang::is_string(label)) {
    cli::cli_abort("{.arg label} must be a single string.", call = call)
  }
  label
}

#' Carbon Tag
#'
#' Create a read-only Carbon tag: a small label for categorizing or
#' highlighting content, such as a status. For tags the user can interact
#' with, see \code{carbon_dismissible_tag()}, \code{carbon_selectable_tag()},
#' and \code{carbon_operational_tag()}.
#'
#' @param label The tag text.
#' @param type The tag color. One of \code{"gray"}, \code{"cool-gray"},
#'   \code{"warm-gray"}, \code{"red"}, \code{"magenta"}, \code{"purple"},
#'   \code{"blue"}, \code{"cyan"}, \code{"teal"}, \code{"green"},
#'   \code{"high-contrast"}, or \code{"outline"}.
#' @param size The tag height: \code{"md"} (24px), \code{"sm"} (18px), or
#'   \code{"lg"} (32px).
#' @param icon Optional icon shown before the label: an icon name (see
#'   \code{carbon_icon_names()}) or a \code{carbon_icon()}. Carbon doesn't show
#'   icons on \code{"sm"} tags.
#' @param disabled If \code{TRUE}, show the tag greyed out.
#' @param id Optional element id.
#' @param dismissible Deprecated: use \code{carbon_dismissible_tag()}, which
#'   also tells the server when the tag is dismissed.
#' @param ... Additional attributes for the underlying \code{cds-tag}
#'   element.
#'
#' @return An HTML tag representing a Carbon tag.
#'
#' @seealso \code{\link{carbon_dismissible_tag}},
#'   \code{\link{carbon_selectable_tag}}, \code{\link{carbon_operational_tag}}
#'
#' @examples
#' carbon_tag("Beta")
#'
#' carbon_tag("Deprecated", type = "red", size = "sm")
#'
#' carbon_tag("Stable", type = "green", icon = "checkmark--filled")
#'
#' @export
carbon_tag <- function(
  label,
  type = c(
    "gray",
    "cool-gray",
    "warm-gray",
    "red",
    "magenta",
    "purple",
    "blue",
    "cyan",
    "teal",
    "green",
    "high-contrast",
    "outline"
  ),
  size = c("md", "sm", "lg"),
  icon = NULL,
  disabled = FALSE,
  id = NULL,
  dismissible = FALSE,
  ...
) {
  type <- match.arg(type)
  size <- match.arg(size)

  if (isTRUE(dismissible)) {
    return(carbon_dismissible_tag(
      inputId = id,
      label = label,
      type = type,
      size = size,
      icon = icon,
      disabled = disabled,
      ...
    ))
  }

  .build_carbon_tag(
    "cds-tag",
    c(
      list(id = id, type = type),
      .tag_attribs(size, disabled, icon),
      list(...),
      list(label)
    )
  )
}

#' Carbon Dismissible Tag
#'
#' Create a Carbon tag with a close button, e.g. for an active filter the
#' user can remove. Clicking the button hides the tag, and sets
#' \code{input$<inputId>} to \code{TRUE}.
#'
#' The input is \code{NULL} until the tag is dismissed, so
#' \code{shiny::observeEvent(input$<inputId>, ...)} runs once, when it is.
#'
#' @param inputId The input slot that will be used to learn the tag was
#'   dismissed.
#' @inheritParams carbon_tag
#' @param label The tag text. A single string.
#' @param ... Additional attributes for the underlying
#'   \code{cds-dismissible-tag} element.
#'
#' @return An HTML tag representing a Carbon dismissible tag.
#'
#' @seealso \code{\link{carbon_tag}}, \code{\link{update_carbon_tag}}
#'
#' @examples
#' carbon_dismissible_tag("filter_status", "Status: open", type = "blue")
#'
#' @export
carbon_dismissible_tag <- function(
  inputId,
  label,
  type = c(
    "gray",
    "cool-gray",
    "warm-gray",
    "red",
    "magenta",
    "purple",
    "blue",
    "cyan",
    "teal",
    "green",
    "high-contrast",
    "outline"
  ),
  size = c("md", "sm", "lg"),
  icon = NULL,
  disabled = FALSE,
  ...
) {
  type <- match.arg(type)
  size <- match.arg(size)

  .build_carbon_tag(
    "cds-dismissible-tag",
    c(
      list(id = inputId, type = type, text = .check_tag_text(label)),
      .tag_attribs(size, disabled, icon),
      list(...)
    )
  )
}

#' Carbon Selectable Tag
#'
#' Create a Carbon tag the user can turn on and off, e.g. to choose topics or
#' filters. \code{input$<inputId>} is \code{TRUE} while it is selected and
#' \code{FALSE} otherwise, like \code{shiny::checkboxInput()}.
#'
#' Carbon gives selectable tags a single style, so there is no \code{type}.
#'
#' @param inputId The input slot that will be used to access the value.
#' @inheritParams carbon_tag
#' @param label The tag text. A single string.
#' @param selected Whether the tag starts selected.
#' @param ... Additional attributes for the underlying
#'   \code{cds-selectable-tag} element.
#'
#' @return An HTML tag representing a Carbon selectable tag.
#'
#' @seealso \code{\link{carbon_tag}}, \code{\link{update_carbon_tag}}
#'
#' @examples
#' htmltools::tagList(
#'   carbon_selectable_tag("topic_r", "R", selected = TRUE),
#'   carbon_selectable_tag("topic_python", "Python"),
#'   carbon_selectable_tag("topic_sql", "SQL")
#' )
#'
#' @export
carbon_selectable_tag <- function(
  inputId,
  label,
  selected = FALSE,
  size = c("md", "sm", "lg"),
  icon = NULL,
  disabled = FALSE,
  ...
) {
  size <- match.arg(size)

  if (!rlang::is_bool(selected)) {
    cli::cli_abort("{.arg selected} must be {.code TRUE} or {.code FALSE}.")
  }

  .build_carbon_tag(
    "cds-selectable-tag",
    c(
      list(
        id = inputId,
        text = .check_tag_text(label),
        selected = if (selected) NA
      ),
      .tag_attribs(size, disabled, icon),
      list(...)
    )
  )
}

#' Carbon Operational Tag
#'
#' Create a clickable Carbon tag that triggers an action, e.g. showing more
#' detail about the category it names. It works like an action button:
#' \code{input$<inputId>} counts the clicks, and
#' \code{shiny::observeEvent(input$<inputId>, ...)} runs on each one.
#'
#' @param inputId The input slot that will be used to access the clicks.
#' @inheritParams carbon_tag
#' @param label The tag text. A single string.
#' @param ... Additional attributes for the underlying
#'   \code{cds-operational-tag} element.
#'
#' @return An HTML tag representing a Carbon operational tag.
#'
#' @seealso \code{\link{carbon_tag}}, \code{\link{update_carbon_tag}}
#'
#' @examples
#' carbon_operational_tag("more_tags", "+3", type = "gray")
#'
#' @export
carbon_operational_tag <- function(
  inputId,
  label,
  type = c(
    "gray",
    "cool-gray",
    "warm-gray",
    "red",
    "magenta",
    "purple",
    "blue",
    "cyan",
    "teal",
    "green",
    "high-contrast",
    "outline"
  ),
  size = c("md", "sm", "lg"),
  icon = NULL,
  disabled = FALSE,
  ...
) {
  type <- match.arg(type)
  size <- match.arg(size)

  .build_carbon_tag(
    "cds-operational-tag",
    c(
      list(id = inputId, type = type, text = .check_tag_text(label)),
      .tag_attribs(size, disabled, icon),
      list(...)
    )
  )
}

#' Update a Carbon Tag
#'
#' Change a \code{carbon_dismissible_tag()}, \code{carbon_selectable_tag()},
#' or \code{carbon_operational_tag()} from the server.
#'
#' @param inputId The tag's input id.
#' @param label Optional new text.
#' @param type Optional new color (not for selectable tags). See
#'   \code{carbon_tag()} for the types.
#' @param selected Optional \code{TRUE} or \code{FALSE}, to select or
#'   deselect a selectable tag. Its input updates to match.
#' @param disabled Optional \code{TRUE} or \code{FALSE}.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_dismissible_tag}},
#'   \code{\link{carbon_selectable_tag}}, \code{\link{carbon_operational_tag}}
#'
#' @examples
#' \dontrun{
#' update_carbon_tag("topic_r", selected = FALSE)
#' update_carbon_tag("more_tags", label = "+5")
#' }
#'
#' @export
update_carbon_tag <- function(
  inputId,
  label = NULL,
  type = NULL,
  selected = NULL,
  disabled = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list()

  if (!is.null(label)) {
    msg$text <- .check_tag_text(label)
  }
  if (!is.null(type)) {
    msg$type <- match.arg(type, .tag_types)
  }
  if (!is.null(selected)) {
    if (!rlang::is_bool(selected)) {
      cli::cli_abort(
        "{.arg selected} must be {.code TRUE}, {.code FALSE}, or {.code NULL}."
      )
    }
    msg$selected <- selected
  }
  if (!is.null(disabled)) {
    if (!rlang::is_bool(disabled)) {
      cli::cli_abort(
        "{.arg disabled} must be {.code TRUE}, {.code FALSE}, or {.code NULL}."
      )
    }
    msg$disabled <- disabled
  }

  session$sendInputMessage(inputId, msg)

  invisible(NULL)
}
