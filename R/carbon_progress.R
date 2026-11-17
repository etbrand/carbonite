#' Carbon Progress Step
#'
#' Define one step of a \code{carbon_progress_indicator()}.
#'
#' @param label The step's label.
#' @param secondary_label Optional smaller text below the label, e.g.
#'   \code{"Optional"}.
#' @param invalid If \code{TRUE}, mark the step with an error icon, e.g.
#'   when it has a problem the user must fix.
#' @param disabled If \code{TRUE}, the step is greyed out, and can't be
#'   clicked in a clickable indicator.
#'
#' @return A \code{cds-progress-step} tag, to pass to
#'   \code{carbon_progress_indicator()}.
#'
#' @seealso \code{\link{carbon_progress_indicator}}
#'
#' @examples
#' carbon_progress_step("Billing", secondary_label = "Optional")
#'
#' @export
carbon_progress_step <- function(
  label,
  secondary_label = NULL,
  invalid = FALSE,
  disabled = FALSE
) {
  if (!rlang::is_string(label)) {
    cli::cli_abort("{.arg label} must be a single string.")
  }
  if (!rlang::is_bool(invalid)) {
    cli::cli_abort("{.arg invalid} must be {.code TRUE} or {.code FALSE}.")
  }
  if (!rlang::is_bool(disabled)) {
    cli::cli_abort("{.arg disabled} must be {.code TRUE} or {.code FALSE}.")
  }

  htmltools::tag(
    "cds-progress-step",
    list(
      label = label,
      # The step icon's accessible name
      description = label,
      `secondary-label` = secondary_label,
      invalid = if (invalid) NA,
      disabled = if (disabled) NA
    )
  )
}

#' Carbon Progress Indicator
#'
#' Create a Carbon progress indicator: the steps of a multi-step task, such
#' as a form or a wizard, showing which are done, the current step, and
#' which are still to come.
#'
#' With an \code{inputId}, \code{input$<inputId>} is the current step's
#' number (from 1), and \code{update_carbon_progress_indicator()} moves to
#' another step, e.g. from "Next" and "Back" buttons. With
#' \code{clickable = TRUE}, the user can also click a step to go to it.
#'
#' @param inputId Optional input id. Needed for the input and for
#'   \code{update_carbon_progress_indicator()}.
#' @param ... The steps: strings (their labels) or
#'   \code{carbon_progress_step()}s.
#' @param current The current step's number, from 1. Earlier steps are shown
#'   as complete.
#' @param vertical If \code{TRUE}, list the steps vertically.
#' @param space_equally If \code{TRUE}, spread the steps across the full
#'   width (horizontal indicators only).
#' @param clickable If \code{TRUE}, the user can click a step (other than
#'   the current one) to go to it. Needs an \code{inputId}.
#'
#' @return An HTML tag representing a Carbon progress indicator.
#'
#' @seealso \code{\link{carbon_progress_step}},
#'   \code{\link{update_carbon_progress_indicator}},
#'   \code{\link{carbon_progress_bar}}
#'
#' @examples
#' carbon_progress_indicator(
#'   "signup",
#'   "Account",
#'   "Profile",
#'   carbon_progress_step("Billing", secondary_label = "Optional"),
#'   "Review",
#'   current = 2
#' )
#'
#' @export
carbon_progress_indicator <- function(
  inputId = NULL,
  ...,
  current = 1,
  vertical = FALSE,
  space_equally = FALSE,
  clickable = FALSE
) {
  steps <- Filter(Negate(is.null), rlang::list2(...))
  is_step <- vapply(steps, function(step) {
    rlang::is_string(step) || (inherits(step, "shiny.tag") && identical(step$name, "cds-progress-step"))
  }, logical(1))
  if (!all(is_step)) {
    cli::cli_abort("Steps must be strings or {.fn carbon_progress_step}s.")
  }
  steps <- lapply(steps, function(step) {
    if (rlang::is_string(step)) carbon_progress_step(step) else step
  })

  if (!length(steps)) {
    cli::cli_abort("A progress indicator needs at least one step.")
  }
  if (!is.numeric(current) || length(current) != 1 || is.na(current) || current != round(current) ||
    current < 1 || current > length(steps)) {
    cli::cli_abort("{.arg current} must be a step number, from 1 to {length(steps)}.")
  }
  for (arg in c("vertical", "space_equally", "clickable")) {
    if (!rlang::is_bool(get(arg))) {
      cli::cli_abort("{.arg {arg}} must be {.code TRUE} or {.code FALSE}.")
    }
  }
  if (clickable && is.null(inputId)) {
    cli::cli_abort("{.code clickable = TRUE} needs an {.arg inputId}.")
  }

  .build_carbon_tag(
    "cds-progress-indicator",
    c(
      list(
        id = inputId,
        # Carbon counts steps from 0
        `current-index` = current - 1,
        vertical = if (vertical) NA,
        `space-equally` = if (space_equally) NA,
        # srcjs/bindings/carbon-progress-indicator.js makes the steps
        # clickable (Carbon wants a JS callback for that)
        `data-clickable` = if (clickable) NA
      ),
      steps
    )
  )
}

#' Update a Carbon Progress Indicator
#'
#' Move a \code{carbon_progress_indicator()} to another step. Its input
#' updates to match.
#'
#' @param inputId The progress indicator's input id.
#' @param current The step to make current, from 1.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_progress_indicator}}
#'
#' @examples
#' \dontrun{
#' shiny::observeEvent(input$next_step, {
#'   update_carbon_progress_indicator("signup", input$signup + 1)
#' })
#' }
#'
#' @export
update_carbon_progress_indicator <- function(
  inputId,
  current,
  session = shiny::getDefaultReactiveDomain()
) {
  if (!is.numeric(current) || length(current) != 1 || is.na(current) || current < 1 || current != round(current)) {
    cli::cli_abort("{.arg current} must be a step number, from 1.")
  }

  session$sendInputMessage(inputId, list(current = current))

  invisible(NULL)
}

#' Carbon Progress Bar
#'
#' Create a Carbon progress bar, showing how far a task has got. Update it
#' from the server with \code{update_carbon_progress_bar()} as the task runs:
#' updates are sent straight away, so the bar moves even during a long
#' computation.
#'
#' Without a \code{value}, the bar is indeterminate: an animation showing
#' that something is happening, for tasks whose length isn't known.
#'
#' @param id The element id, used by \code{update_carbon_progress_bar()}.
#' @param label The label shown above the bar.
#' @param value Optional progress so far, from 0 to \code{max}. \code{NULL}
#'   for an indeterminate bar.
#' @param max The value of a complete task.
#' @param helper_text Optional text below the bar, e.g. \code{"3 of 10
#'   files"}.
#' @param status \code{"active"} while the task runs, then \code{"finished"}
#'   (a full bar and a checkmark) or \code{"error"} (an error icon).
#' @param type The layout: \code{"default"}, \code{"inline"} (the label
#'   beside the bar), or \code{"indented"}.
#' @param size The bar's thickness: \code{"big"} or \code{"small"}.
#' @param hide_label If \code{TRUE}, hide the label visually (it is still
#'   read by screen readers).
#'
#' @return An HTML tag representing a Carbon progress bar.
#'
#' @seealso \code{\link{update_carbon_progress_bar}},
#'   \code{\link{carbon_progress_indicator}}
#'
#' @examples
#' carbon_progress_bar("upload", "Uploading", value = 40, helper_text = "4 of 10 files")
#'
#' carbon_progress_bar("loading", "Loading data")
#'
#' if (interactive()) {
#'   ui <- carbon_page(
#'     carbon_button("run", "Run"),
#'     carbon_progress_bar("progress", "Analysis", value = 0)
#'   )
#'
#'   server <- function(input, output, session) {
#'     shiny::observeEvent(input$run, {
#'       for (i in 1:10) {
#'         Sys.sleep(0.3)
#'         update_carbon_progress_bar("progress", value = i * 10,
#'           helper_text = paste(i, "of 10 steps"))
#'       }
#'       update_carbon_progress_bar("progress", status = "finished",
#'         helper_text = "Done")
#'     })
#'   }
#'
#'   shiny::shinyApp(ui, server)
#' }
#'
#' @export
carbon_progress_bar <- function(
  id,
  label,
  value = NULL,
  max = 100,
  helper_text = NULL,
  status = c("active", "finished", "error"),
  type = c("default", "inline", "indented"),
  size = c("big", "small"),
  hide_label = FALSE
) {
  status <- match.arg(status)
  type <- match.arg(type)
  size <- match.arg(size)

  .check_progress_value(value, max)
  if (!rlang::is_bool(hide_label)) {
    cli::cli_abort("{.arg hide_label} must be {.code TRUE} or {.code FALSE}.")
  }

  .build_carbon_tag(
    "cds-progress-bar",
    list(
      id = id,
      label = label,
      value = value,
      max = max,
      `helper-text` = helper_text,
      status = status,
      type = type,
      size = size,
      `hide-label` = if (hide_label) NA
    )
  )
}

.check_progress_value <- function(value, max, call = rlang::caller_env()) {
  if (!is.numeric(max) || length(max) != 1 || is.na(max) || max <= 0) {
    cli::cli_abort("{.arg max} must be a positive number.", call = call)
  }
  if (!is.null(value) && !(length(value) == 1 && is.na(value)) &&
    (!is.numeric(value) || length(value) != 1 || value < 0 || value > max)) {
    cli::cli_abort("{.arg value} must be a number from 0 to {.arg max} ({max}), or {.code NULL}.", call = call)
  }
}

#' Update a Carbon Progress Bar
#'
#' Change a \code{carbon_progress_bar()} as a task runs. The update is sent
#' straight away, even in the middle of a long computation. Arguments left
#' \code{NULL} are unchanged.
#'
#' @param id The progress bar's id. In a module, the id passed to
#'   \code{carbon_progress_bar()} (it is namespaced here).
#' @param value Optional new progress, from 0 to the bar's \code{max};
#'   \code{NA} makes the bar indeterminate.
#' @param max Optional new \code{max}.
#' @param label,helper_text Optional new label and helper text.
#' @param status Optional new status: \code{"active"}, \code{"finished"}, or
#'   \code{"error"}.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_progress_bar}}
#'
#' @examples
#' \dontrun{
#' update_carbon_progress_bar("upload", value = 70, helper_text = "7 of 10 files")
#' update_carbon_progress_bar("upload", status = "error", helper_text = "Connection lost")
#' }
#'
#' @export
update_carbon_progress_bar <- function(
  id,
  value = NULL,
  max = NULL,
  label = NULL,
  helper_text = NULL,
  status = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(id = session$ns(id))

  if (!is.null(value)) {
    if (length(value) == 1 && is.na(value)) {
      # Indeterminate: JSON null
      msg["value"] <- list(NULL)
    } else {
      .check_progress_value(value, if (is.null(max)) Inf else max)
      msg$value <- value
    }
  }
  if (!is.null(max)) {
    .check_progress_value(NULL, max)
    msg$max <- max
  }
  if (!is.null(label)) msg$label <- label
  if (!is.null(helper_text)) msg$helperText <- helper_text
  if (!is.null(status)) msg$status <- match.arg(status, c("active", "finished", "error"))

  session$sendCustomMessage("carbonite-progress-bar", msg)

  invisible(NULL)
}
