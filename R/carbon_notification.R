# Shared by inline and toast notifications. Title and subtitle go in Carbon's
# slots rather than its `title`/`subtitle` attributes: a `title` attribute
# also gives the element a native browser tooltip, and slots accept tags.
.notification_tag <- function(
  name,
  title,
  subtitle,
  kind,
  close_button,
  low_contrast,
  attribs = list(),
  call = rlang::caller_env()
) {
  if (!rlang::is_bool(close_button)) {
    cli::cli_abort("{.arg close_button} must be {.code TRUE} or {.code FALSE}.", call = call)
  }
  if (!rlang::is_bool(low_contrast)) {
    cli::cli_abort("{.arg low_contrast} must be {.code TRUE} or {.code FALSE}.", call = call)
  }

  .build_carbon_tag(
    name,
    c(
      list(
        kind = kind,
        `hide-close-button` = if (!close_button) NA,
        `low-contrast` = if (low_contrast) NA
      ),
      attribs,
      list(
        htmltools::tags$span(slot = "title", title),
        if (!is.null(subtitle)) htmltools::tags$span(slot = "subtitle", subtitle)
      )
    )
  )
}

#' Carbon Inline Notification
#'
#' Create a Carbon inline notification: a message shown in the page, next to
#' the content it is about, e.g. above a form. For a message that pops up
#' over the page, use \code{show_carbon_notification()}.
#'
#' Closing the notification hides it in the browser. To show or hide it
#' from the server, render it with \code{shiny::renderUI()}.
#'
#' @param title The notification's title, shown in bold. A string or tags.
#' @param subtitle Optional text after the title. A string or tags.
#' @param kind The notification type, which sets its colour and icon. One of
#'   \code{"info"}, \code{"success"}, \code{"warning"}, or \code{"error"}.
#' @param close_button Whether to show a close button.
#' @param low_contrast If \code{TRUE}, use Carbon's lighter, low-contrast
#'   style.
#' @param ... Additional attributes for the underlying
#'   \code{cds-inline-notification} element, e.g. \code{id}.
#'
#' @return An HTML tag representing a Carbon inline notification.
#'
#' @seealso \code{\link{show_carbon_notification}}
#'
#' @examples
#' carbon_inline_notification(
#'   "Changes saved",
#'   "Your settings were updated.",
#'   kind = "success"
#' )
#'
#' carbon_inline_notification(
#'   "Read only",
#'   "You don't have permission to edit this report.",
#'   kind = "warning",
#'   close_button = FALSE,
#'   low_contrast = TRUE
#' )
#'
#' @export
carbon_inline_notification <- function(
  title,
  subtitle = NULL,
  kind = c("info", "success", "warning", "error"),
  close_button = TRUE,
  low_contrast = FALSE,
  ...
) {
  kind <- match.arg(kind)

  .notification_tag(
    "cds-inline-notification",
    title = title,
    subtitle = subtitle,
    kind = kind,
    close_button = close_button,
    low_contrast = low_contrast,
    attribs = list(...)
  )
}

#' Show or Remove a Carbon Notification
#'
#' \code{show_carbon_notification()} pops up a Carbon toast notification in
#' the top-right corner of the page, in the same way as
#' \code{shiny::showNotification()}. Notifications stack, newest at the
#' bottom, and close after \code{duration} seconds or when the user closes
#' them. \code{remove_carbon_notification()} closes one from the server.
#'
#' Notifications are shown straight away, even in the middle of a long
#' computation.
#'
#' @param title The notification's title, shown in bold. A string or tags.
#' @param subtitle Optional text below the title. A string or tags.
#' @param kind The notification type, which sets its colour and icon. One of
#'   \code{"info"}, \code{"success"}, \code{"warning"}, or \code{"error"}.
#' @param duration Seconds before the notification closes by itself.
#'   \code{NULL} keeps it until the user or the server closes it.
#' @param caption Optional small text at the bottom, e.g. a time stamp.
#' @param close_button Whether to show a close button. Without one, a
#'   notification with \code{duration = NULL} stays until
#'   \code{remove_carbon_notification()}.
#' @param low_contrast If \code{TRUE}, use Carbon's lighter, low-contrast
#'   style.
#' @param id Optional id. Showing a notification with the id of one already
#'   showing replaces it, e.g. to update a progress message. By default a
#'   new id is generated.
#' @param session The Shiny session.
#'
#' @return \code{show_carbon_notification()} invisibly returns the
#'   notification's id, for \code{remove_carbon_notification()}.
#'   \code{remove_carbon_notification()} invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_inline_notification}}
#'
#' @examples
#' if (interactive()) {
#'   ui <- carbon_page(carbon_button("save", "Save"))
#'
#'   server <- function(input, output, session) {
#'     shiny::observeEvent(input$save, {
#'       id <- show_carbon_notification(
#'         "Saving...",
#'         kind = "info",
#'         duration = NULL,
#'         close_button = FALSE
#'       )
#'       Sys.sleep(2)
#'       remove_carbon_notification(id)
#'       show_carbon_notification("Saved", "All changes were saved.", kind = "success")
#'     })
#'   }
#'
#'   shiny::shinyApp(ui, server)
#' }
#'
#' @export
show_carbon_notification <- function(
  title,
  subtitle = NULL,
  kind = c("info", "success", "warning", "error"),
  duration = 5,
  caption = NULL,
  close_button = TRUE,
  low_contrast = FALSE,
  id = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  kind <- match.arg(kind)

  if (!is.null(duration) && (!is.numeric(duration) || length(duration) != 1 || is.na(duration) || duration <= 0)) {
    cli::cli_abort("{.arg duration} must be a positive number of seconds, or {.code NULL}.")
  }

  if (is.null(id)) {
    id <- paste0("carbonite-notification-", paste(sample(c(0:9, letters[1:6]), 12, replace = TRUE), collapse = ""))
  } else {
    if (!rlang::is_string(id) || !grepl("^[A-Za-z][A-Za-z0-9_-]*$", id)) {
      cli::cli_abort("{.arg id} must be a single string of letters, digits, {.val -}, and {.val _}, starting with a letter.")
    }
    # Replace a notification already showing with this id
    remove_carbon_notification(id, session = session)
  }

  toast <- .notification_tag(
    "cds-toast-notification",
    title = title,
    subtitle = subtitle,
    kind = kind,
    close_button = close_button,
    low_contrast = low_contrast,
    attribs = list(
      id = id,
      # srcjs/notifications.js moves it into the stack and removes it once
      # closed
      class = "carbonite-toast",
      timeout = if (!is.null(duration)) round(duration * 1000)
    )
  )
  if (!is.null(caption)) {
    toast <- htmltools::tagAppendChild(toast, htmltools::tags$span(slot = "caption", caption))
  }

  shiny::insertUI(
    selector = "body",
    where = "beforeEnd",
    ui = toast,
    immediate = TRUE,
    session = session
  )

  invisible(id)
}

#' @rdname show_carbon_notification
#' @export
remove_carbon_notification <- function(id, session = shiny::getDefaultReactiveDomain()) {
  if (!rlang::is_string(id)) {
    cli::cli_abort("{.arg id} must be a single string.")
  }

  shiny::removeUI(paste0("#", id), immediate = TRUE, session = session)

  invisible(NULL)
}
