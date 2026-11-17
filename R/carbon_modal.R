#' Carbon Design System Modal
#'
#' Create a Carbon modal dialog, to show from the server with
#' \code{show_carbon_modal()}, in the same way as
#' \code{shiny::modalDialog()} and \code{shiny::showModal()}.
#'
#' The modal always has a close button (\code{x}) in its header, and
#' \kbd{Escape} closes it. Inputs inside the modal work like any other
#' Shiny input. A modal the user closes is removed from the page; as with
#' \code{shiny::removeModal()}, its inputs keep their last value on the
#' server, so set them from the current state each time you show the modal.
#'
#' A typical "transactional" modal has a \code{carbon_modal_close_button()}
#' to cancel and a primary \code{carbon_button()} whose click the server
#' handles, finishing with \code{remove_carbon_modal()}.
#'
#' @param ... UI elements for the modal body.
#' @param title Optional heading.
#' @param label Optional label shown above the heading, e.g. the name of the
#'   item or task the modal belongs to.
#' @param footer Buttons for the footer: \code{carbon_button()}s and
#'   \code{carbon_modal_close_button()}s, at most three. Carbon puts the
#'   primary action last. \code{NULL} for a modal with no footer.
#' @param size The modal width. One of \code{"md"}, \code{"xs"},
#'   \code{"sm"}, or \code{"lg"}.
#' @param easy_close If \code{TRUE}, clicking outside the modal closes it.
#'   Set to \code{FALSE} for modals where an accidental click would lose
#'   the user's input.
#'
#' @return A \code{cds-modal} tag, to pass to \code{show_carbon_modal()}.
#'
#' @seealso \code{\link{show_carbon_modal}},
#'   \code{\link{carbon_modal_close_button}}
#'
#' @examples
#' carbon_modal(
#'   htmltools::p("This will permanently delete the report."),
#'   title = "Delete report?",
#'   label = "Quarterly sales",
#'   footer = htmltools::tagList(
#'     carbon_modal_close_button(),
#'     carbon_button("confirm_delete", "Delete", kind = "danger")
#'   ),
#'   size = "sm"
#' )
#'
#' if (interactive()) {
#'   ui <- carbon_page(carbon_button("delete", "Delete report", kind = "danger"))
#'
#'   server <- function(input, output, session) {
#'     shiny::observeEvent(input$delete, {
#'       show_carbon_modal(carbon_modal(
#'         "This will permanently delete the report.",
#'         title = "Delete report?",
#'         footer = htmltools::tagList(
#'           carbon_modal_close_button(),
#'           carbon_button("confirm_delete", "Delete", kind = "danger")
#'         )
#'       ))
#'     })
#'
#'     shiny::observeEvent(input$confirm_delete, {
#'       remove_carbon_modal()
#'     })
#'   }
#'
#'   shiny::shinyApp(ui, server)
#' }
#'
#' @export
carbon_modal <- function(
  ...,
  title = NULL,
  label = NULL,
  footer = carbon_modal_close_button(),
  size = c("md", "xs", "sm", "lg"),
  easy_close = TRUE
) {
  size <- match.arg(size)

  if (!rlang::is_bool(easy_close)) {
    cli::cli_abort("{.arg easy_close} must be {.code TRUE} or {.code FALSE}.")
  }

  .build_carbon_tag(
    "cds-modal",
    list(
      # show_carbon_modal() inserts the modal into the page already open
      open = NA,
      size = size,
      `prevent-close-on-click-outside` = if (!easy_close) NA,
      `aria-label` = if (is.null(title)) "Dialog",
      htmltools::tag(
        "cds-modal-header",
        list(
          htmltools::tag("cds-modal-close-button", list()),
          if (!is.null(label)) htmltools::tag("cds-modal-label", list(label)),
          if (!is.null(title)) htmltools::tag("cds-modal-heading", list(title))
        )
      ),
      htmltools::tag("cds-modal-body", rlang::list2(...)),
      if (!is.null(footer)) htmltools::tag("cds-modal-footer", list(footer))
    )
  )
}

#' Carbon Modal Close Button
#'
#' Create a footer button for \code{carbon_modal()} that closes the modal in
#' the browser, without a round trip to the server.
#'
#' @param label The button label.
#' @param kind The Carbon button style. Usually \code{"secondary"} (the
#'   default), for a "Cancel" next to a primary action, or \code{"primary"}
#'   for the only button of an informational modal.
#'
#' @return An HTML tag representing a Carbon button.
#'
#' @seealso \code{\link{carbon_modal}}
#'
#' @examples
#' carbon_modal_close_button()
#'
#' carbon_modal_close_button("Got it", kind = "primary")
#'
#' @export
carbon_modal_close_button <- function(
  label = "Cancel",
  kind = c("secondary", "primary", "tertiary", "ghost", "danger")
) {
  kind <- match.arg(kind)

  .build_carbon_tag(
    "cds-button",
    list(
      kind = kind,
      # Carbon closes the enclosing cds-modal when an element with this
      # attribute is clicked
      `data-modal-close` = NA,
      label
    )
  )
}

#' Show or Remove a Carbon Modal
#'
#' \code{show_carbon_modal()} shows a \code{carbon_modal()}, replacing any
#' Carbon modal already showing. \code{remove_carbon_modal()} closes it, for
#' example once the server has handled the modal's primary button.
#'
#' @param ui A modal created with \code{carbon_modal()}.
#' @param session The Shiny session.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_modal}}
#'
#' @examples
#' \dontrun{
#' show_carbon_modal(carbon_modal("Saved.", title = "Done"))
#'
#' remove_carbon_modal()
#' }
#'
#' @export
show_carbon_modal <- function(ui, session = shiny::getDefaultReactiveDomain()) {
  if (!inherits(ui, "shiny.tag") || !identical(ui$name, "cds-modal")) {
    cli::cli_abort("{.arg ui} must be a {.fn carbon_modal}.")
  }

  remove_carbon_modal(session = session)
  shiny::insertUI(
    selector = "body",
    where = "beforeEnd",
    ui = htmltools::div(class = "carbon-modal-wrapper", ui),
    session = session
  )

  invisible(NULL)
}

#' @rdname show_carbon_modal
#' @export
remove_carbon_modal <- function(session = shiny::getDefaultReactiveDomain()) {
  shiny::removeUI(".carbon-modal-wrapper", multiple = TRUE, session = session)

  invisible(NULL)
}
