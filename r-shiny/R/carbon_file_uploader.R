#' Carbon File Uploader
#'
#' Create a Carbon file uploader: a button, or a drag-and-drop area, for
#' choosing files to upload to the server. It works like
#' \code{shiny::fileInput()}: once the files have uploaded,
#' \code{input$<inputId>} is a data frame with one row per file and the
#' columns \code{name}, \code{size}, \code{type}, and \code{datapath} (where
#' the file was saved on the server).
#'
#' The chosen files are listed below the button, showing their upload
#' progress, then a checkmark once uploaded, or the error if the upload
#' failed. Choosing files again replaces them. Shiny limits uploads to 5 MB
#' unless you raise \code{options(shiny.maxRequestSize = )}.
#'
#' @param inputId The input slot that will be used to access the files.
#' @param label Optional title shown above the uploader.
#' @param description Optional text below the title, e.g. which files are
#'   accepted.
#' @param button_label The text of the button, or of the drag-and-drop area.
#'   Defaults to \code{"Add file"}, \code{"Add files"} with
#'   \code{multiple = TRUE}, or Carbon's drag-and-drop prompt with
#'   \code{drop_zone = TRUE}.
#' @param multiple Whether the user can choose more than one file at a time.
#' @param accept Optional file types to accept, as file extensions (e.g.
#'   \code{c(".csv", ".xlsx")}) and/or MIME types (e.g. \code{"image/*"}).
#'   Other files can't be chosen, and are ignored when dropped.
#' @param drop_zone If \code{TRUE}, show a drag-and-drop area (which can
#'   also be clicked to choose files) instead of a button.
#' @param button_kind The button style. One of \code{"primary"},
#'   \code{"secondary"}, \code{"tertiary"}, or \code{"ghost"}.
#' @param size The button and file list size. One of \code{"md"},
#'   \code{"sm"}, or \code{"lg"}.
#' @param disabled If \code{TRUE}, files can't be chosen.
#'
#' @return An HTML tag representing a Carbon file uploader.
#'
#' @examples
#' carbon_file_uploader(
#'   "data",
#'   label = "Upload data",
#'   description = "CSV files only, up to 5 MB.",
#'   accept = ".csv"
#' )
#'
#' carbon_file_uploader(
#'   "images",
#'   label = "Images",
#'   multiple = TRUE,
#'   accept = "image/*",
#'   drop_zone = TRUE
#' )
#'
#' if (interactive()) {
#'   ui <- carbon_page(
#'     carbon_file_uploader("data", "Upload a CSV", accept = ".csv"),
#'     shiny::tableOutput("preview")
#'   )
#'
#'   server <- function(input, output, session) {
#'     output$preview <- shiny::renderTable({
#'       shiny::req(input$data)
#'       utils::head(utils::read.csv(input$data$datapath))
#'     })
#'   }
#'
#'   shiny::shinyApp(ui, server)
#' }
#'
#' @export
carbon_file_uploader <- function(
  inputId,
  label = NULL,
  description = NULL,
  button_label = NULL,
  multiple = FALSE,
  accept = NULL,
  drop_zone = FALSE,
  button_kind = c("primary", "secondary", "tertiary", "ghost"),
  size = c("md", "sm", "lg"),
  disabled = FALSE
) {
  button_kind <- match.arg(button_kind)
  size <- match.arg(size)

  for (arg in c("multiple", "drop_zone", "disabled")) {
    if (!rlang::is_bool(get(arg))) {
      cli::cli_abort("{.arg {arg}} must be {.code TRUE} or {.code FALSE}.")
    }
  }
  if (!is.null(accept) && (!is.character(accept) || !length(accept) || anyNA(accept))) {
    cli::cli_abort("{.arg accept} must be file extensions and/or MIME types, e.g. {.val .csv}.")
  }

  accept <- if (!is.null(accept)) paste(accept, collapse = ",")

  if (is.null(button_label)) {
    button_label <- if (drop_zone) {
      "Drag and drop files here or click to upload"
    } else if (multiple) {
      "Add files"
    } else {
      "Add file"
    }
  }

  chooser <- if (drop_zone) {
    htmltools::tag(
      "cds-file-uploader-drop-container",
      list(
        accept = accept,
        multiple = if (multiple) NA,
        disabled = if (disabled) NA,
        button_label
      )
    )
  } else {
    htmltools::tag(
      "cds-file-uploader-button",
      list(
        accept = accept,
        multiple = if (multiple) NA,
        disabled = if (disabled) NA,
        `button-kind` = button_kind,
        size = size,
        button_label
      )
    )
  }

  # Uploads go through Shiny's own file input: srcjs/file-uploader.js hands
  # the files chosen in Carbon's UI to the hidden <input type="file">, which
  # Shiny binds and uploads exactly as for fileInput(). Shiny reports
  # progress and errors in the hidden `<id>_progress` bar, which the script
  # mirrors in Carbon's file list.
  .with_carbon_dependency(htmltools::tags$div(
    class = "carbonite-file-uploader",
    `data-size` = size,
    `data-multiple` = if (multiple) NA,
    htmltools::tag(
      "cds-file-uploader",
      list(
        `label-title` = label,
        `label-description` = description,
        disabled = if (disabled) NA,
        chooser
      )
    ),
    htmltools::tags$input(
      type = "file",
      id = inputId,
      name = inputId,
      class = "carbonite-file-uploader__input",
      multiple = if (multiple) NA,
      accept = accept,
      hidden = NA,
      tabindex = "-1",
      `aria-hidden` = "true"
    ),
    htmltools::tags$div(
      id = paste0(inputId, "_progress"),
      class = "shiny-file-input-progress carbonite-file-uploader__progress",
      hidden = NA,
      htmltools::tags$div(class = "progress-bar")
    )
  ))
}
