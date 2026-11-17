.popover_alignments <- c(
  "bottom", "bottom-start", "bottom-end", "top", "top-start", "top-end",
  "left", "left-start", "left-end", "right", "right-start", "right-end"
)

#' Carbon Popover
#'
#' Create a Carbon popover: a small panel of content, such as a short
#' explanation, a few settings, or a list of links, that opens next to the
#' element that triggers it. Clicking the trigger opens and closes the
#' popover; clicking elsewhere or pressing \kbd{Escape} closes it.
#'
#' With an \code{id}, \code{input$<id>} is \code{TRUE} while the popover is
#' open and \code{FALSE} otherwise, and \code{update_carbon_popover()} opens
#' or closes it from the server. The content can include Shiny inputs and
#' outputs.
#'
#' @param trigger The element that opens the popover, e.g. a
#'   \code{carbon_button()} or a \code{carbon_icon()}.
#' @param ... The popover's content.
#' @param id Optional id, for the input and \code{update_carbon_popover()}.
#' @param open Whether the popover starts open.
#' @param align Where the popover opens, relative to the trigger: e.g.
#'   \code{"bottom"} (the default), \code{"bottom-start"}, \code{"top"},
#'   \code{"left"}, or \code{"right-end"}.
#' @param autoalign If \code{TRUE}, move the popover to another side when
#'   there isn't room on the \code{align} side.
#' @param caret Whether to show the small arrow pointing at the trigger.
#' @param high_contrast If \code{TRUE}, use Carbon's dark, high-contrast
#'   style.
#' @param drop_shadow Whether to give the popover a shadow.
#' @param padded If \code{TRUE} (the default), pad the content. Carbon's
#'   popover has none of its own.
#'
#' @return An HTML tag representing a Carbon popover.
#'
#' @seealso \code{\link{update_carbon_popover}}
#'
#' @examples
#' carbon_popover(
#'   carbon_button("help", "What's this?", kind = "ghost"),
#'   htmltools::p(htmltools::strong("Available storage")),
#'   htmltools::p("The space left on your plan, updated hourly."),
#'   id = "help_popover",
#'   align = "bottom-start"
#' )
#'
#' @export
carbon_popover <- function(
  trigger,
  ...,
  id = NULL,
  open = FALSE,
  align = .popover_alignments,
  autoalign = FALSE,
  caret = TRUE,
  high_contrast = FALSE,
  drop_shadow = TRUE,
  padded = TRUE
) {
  align <- match.arg(align)

  for (arg in c("open", "autoalign", "caret", "high_contrast", "drop_shadow", "padded")) {
    if (!rlang::is_bool(get(arg))) {
      cli::cli_abort("{.arg {arg}} must be {.code TRUE} or {.code FALSE}.")
    }
  }

  # Carbon treats the first element in the default slot as the trigger
  if (!inherits(trigger, "shiny.tag")) {
    trigger <- htmltools::tags$span(class = "carbonite-popover__trigger", trigger)
  }

  .build_carbon_tag(
    "cds-popover",
    list(
      id = id,
      # srcjs/popover.js opens and closes it when the trigger is clicked
      class = "carbonite-popover",
      open = if (open) NA,
      align = align,
      autoalign = if (autoalign) NA,
      # Carbon's attribute names for highContrast (no dash)
      highcontrast = if (high_contrast) NA,
      # `caret` and `dropShadow` default to true, and a boolean attribute
      # can't turn them off; srcjs/popover.js sets the properties from these
      `data-caret` = if (!caret) "false",
      `data-drop-shadow` = if (!drop_shadow) "false",
      trigger,
      htmltools::tag(
        "cds-popover-content",
        list(
          slot = "content",
          htmltools::tags$div(
            class = if (padded) "carbonite-popover__body",
            ...
          )
        )
      )
    )
  )
}

#' Update a Carbon Popover
#'
#' Open or close a \code{carbon_popover()} from the server. Its input
#' updates to match.
#'
#' @param id The popover's id.
#' @param open \code{TRUE} to open the popover, \code{FALSE} to close it.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_popover}}
#'
#' @examples
#' \dontrun{
#' update_carbon_popover("help_popover", open = FALSE)
#' }
#'
#' @export
update_carbon_popover <- function(
  id,
  open,
  session = shiny::getDefaultReactiveDomain()
) {
  if (!rlang::is_bool(open)) {
    cli::cli_abort("{.arg open} must be {.code TRUE} or {.code FALSE}.")
  }

  session$sendInputMessage(id, list(open = open))

  invisible(NULL)
}
