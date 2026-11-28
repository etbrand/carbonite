#' Carbon Accordion Item
#'
#' Create one collapsible section for \code{carbon_accordion()}.
#'
#' @param title The heading shown on the item's toggle button. A string or
#'   any inline UI element.
#' @param ... Content shown when the item is open. Named arguments become
#'   attributes of the item, e.g. \code{class}.
#' @param open Whether the item starts open.
#' @param disabled If \code{TRUE}, the item cannot be opened or closed.
#' @param id Optional element id.
#'
#' @return A \code{cds-accordion-item} tag to pass to
#'   \code{carbon_accordion()}.
#'
#' @examples
#' carbon_accordion_item("Section 1", htmltools::p("Content"), open = TRUE)
#'
#' @export
carbon_accordion_item <- function(
  title,
  ...,
  open = FALSE,
  disabled = FALSE,
  id = NULL
) {
  if (!rlang::is_bool(open)) {
    cli::cli_abort("{.arg open} must be {.code TRUE} or {.code FALSE}.")
  }
  if (!rlang::is_bool(disabled)) {
    cli::cli_abort("{.arg disabled} must be {.code TRUE} or {.code FALSE}.")
  }

  # The title goes in Carbon's `title` slot rather than the `title`
  # attribute: on an element, `title` is also the browser's hover tooltip,
  # which would then appear over the whole item.
  .build_carbon_tag(
    "cds-accordion-item",
    c(
      list(
        id = id,
        open = if (open) NA,
        disabled = if (disabled) NA,
        htmltools::tags$span(slot = "title", title)
      ),
      list(...)
    )
  )
}

#' Carbon Accordion
#'
#' Create a Carbon accordion: a vertical stack of headings that each expand
#' to reveal a section of content. Items open and close independently.
#'
#' Shiny outputs inside a closed item are treated as hidden, so by default
#' they render when the item is first opened.
#'
#' @param ... One or more \code{carbon_accordion_item()}s. Named arguments
#'   become attributes of the accordion, e.g. \code{class}.
#' @param size The height of each item's heading. One of \code{"sm"},
#'   \code{"md"}, or \code{"lg"}.
#' @param align Which side of the heading the chevron is on: \code{"end"}
#'   (right) or \code{"start"} (left).
#' @param flush If \code{TRUE}, remove the horizontal padding so headings
#'   and content line up with surrounding content. Has no effect with
#'   \code{align = "start"}.
#' @param id Optional element id.
#'
#' @return A \code{cds-accordion} tag.
#'
#' @seealso \code{\link{carbon_accordion_item}}
#'
#' @examples
#' carbon_accordion(
#'   carbon_accordion_item("Overview", htmltools::p("Overview text"), open = TRUE),
#'   carbon_accordion_item("Details", htmltools::p("More detail")),
#'   carbon_accordion_item("Archived", htmltools::p("Old"), disabled = TRUE),
#'   size = "sm"
#' )
#'
#' @export
carbon_accordion <- function(
  ...,
  size = c("md", "sm", "lg"),
  align = c("end", "start"),
  flush = FALSE,
  id = NULL
) {
  size <- match.arg(size)
  align <- match.arg(align)

  if (!rlang::is_bool(flush)) {
    cli::cli_abort("{.arg flush} must be {.code TRUE} or {.code FALSE}.")
  }

  dots <- .split_dots(...)
  is_item <- vapply(
    dots$children,
    function(x) inherits(x, "shiny.tag") && identical(x$name, "cds-accordion-item"),
    logical(1)
  )

  if (!length(dots$children)) {
    cli::cli_abort("{.fn carbon_accordion} needs at least one {.fn carbon_accordion_item}.")
  }
  if (!all(is_item)) {
    cli::cli_abort(
      "Every unnamed argument to {.fn carbon_accordion} must be a {.fn carbon_accordion_item}."
    )
  }

  # Carbon passes size, alignment and flush on to the items itself.
  .build_carbon_tag(
    "cds-accordion",
    c(
      list(
        id = id,
        size = size,
        alignment = align,
        isflush = if (flush) NA
      ),
      dots$attribs,
      dots$children
    )
  )
}
