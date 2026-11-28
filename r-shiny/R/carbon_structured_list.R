#' Carbon Structured List
#'
#' Create a Carbon structured list from a data frame: a simple, read-only
#' layout for a few rows of related content, such as a comparison of plans
#' or a list of settings. Unlike \code{carbon_table()} it has no sorting,
#' search, or pagination, and its cells can hold any UI.
#'
#' @section Cell content:
#' Each column is shown as text. A list column can hold tags instead, one
#' element per row, e.g. \code{I(list(htmltools::strong("Yes"), "No"))}.
#'
#' @section Selection:
#' With \code{selection = "single"}, the user can select one row, by
#' clicking it or with the arrow keys, and it is marked with a checkmark.
#' The list is then a Shiny input: \code{input$<id>} is the selected row's
#' \code{row_key} value (a string) if \code{row_key} is set, and otherwise its
#' row number; \code{NULL} until a row is selected. Change the selection
#' from the server with \code{update_carbon_structured_list()}.
#'
#' @param data A data frame. Every column is shown, in the data's column
#'   order.
#' @param columns Optional column header labels: a named character vector
#'   or list, keyed by column name. Columns not listed use their name.
#' @param id The list's id. Required with \code{selection = "single"}: the
#'   selected row is \code{input$<id>}.
#' @param selection \code{"none"} or \code{"single"}. See the Selection
#'   section.
#' @param selected The row selected initially: a \code{row_key} value, or a
#'   row number if there is no \code{row_key}.
#' @param row_key Optional name of a column that uniquely identifies each
#'   row. Its values must be unique and not missing, and are the input's
#'   value.
#' @param condensed If \code{TRUE}, use less padding in each row.
#' @param flush If \code{TRUE}, remove the padding at the start of each row,
#'   to line the list up with the content around it. Not available with
#'   selection.
#' @param ... Additional attributes for the underlying
#'   \code{cds-structured-list} element.
#'
#' @return An HTML tag representing a Carbon structured list.
#'
#' @seealso \code{\link{update_carbon_structured_list}},
#'   \code{\link{carbon_table}}
#'
#' @examples
#' plans <- data.frame(
#'   plan = c("Lite", "Standard", "Enterprise"),
#'   storage = c("5 GB", "100 GB", "Unlimited"),
#'   support = c("Community", "Email", "24/7 phone")
#' )
#'
#' carbon_structured_list(
#'   plans,
#'   columns = c(plan = "Plan", storage = "Storage", support = "Support")
#' )
#'
#' # Pick a plan: input$plan is "Lite", "Standard", or "Enterprise"
#' carbon_structured_list(
#'   plans,
#'   id = "plan",
#'   selection = "single",
#'   row_key = "plan",
#'   selected = "Standard"
#' )
#'
#' @export
carbon_structured_list <- function(
  data,
  columns = NULL,
  id = NULL,
  selection = c("none", "single"),
  selected = NULL,
  row_key = NULL,
  condensed = FALSE,
  flush = FALSE,
  ...
) {
  selection <- match.arg(selection)
  selectable <- selection == "single"

  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }
  if (!rlang::is_bool(condensed)) {
    cli::cli_abort("{.arg condensed} must be {.code TRUE} or {.code FALSE}.")
  }
  if (!rlang::is_bool(flush)) {
    cli::cli_abort("{.arg flush} must be {.code TRUE} or {.code FALSE}.")
  }
  if (selectable && !rlang::is_string(id)) {
    cli::cli_abort("{.code selection = \"single\"} needs an {.arg id}: the selected row is {.code input$<id>}.")
  }
  if (selectable && flush) {
    cli::cli_abort("{.arg flush} can't be used with selection.")
  }

  row_keys <- get_row_keys(data, row_key)
  selected <- .check_table_selected(selected, row_keys, selection)
  labels <- .structured_list_labels(names(data), columns)

  header <- htmltools::tag(
    "cds-structured-list-head",
    list(
      htmltools::tag(
        "cds-structured-list-header-row",
        c(
          list(`selection-name` = if (selectable) id),
          lapply(unname(labels), function(label) {
            htmltools::tag("cds-structured-list-header-cell", list(label))
          })
        )
      )
    )
  )

  rows <- lapply(seq_len(nrow(data)), function(i) {
    key <- row_keys[[i]]

    htmltools::tag(
      "cds-structured-list-row",
      c(
        list(
          `selection-name` = if (selectable) id,
          `selection-value` = if (selectable) key,
          selected = if (selectable && key %in% selected) NA
        ),
        lapply(names(data), function(name) {
          htmltools::tag(
            "cds-structured-list-cell",
            list(.structured_list_cell(data[[name]], i))
          )
        })
      )
    )
  })

  .build_carbon_tag(
    "cds-structured-list",
    c(
      list(
        id = id,
        `selection-name` = if (selectable) id,
        condensed = if (condensed) NA,
        flush = if (flush) NA,
        # Marks it for the input binding
        # (srcjs/bindings/carbon-structured-list.js)
        class = if (selectable) "carbonite-structured-list-input",
        `data-row-key-type` = if (selectable) {
          if (is.null(row_key)) "index" else "key"
        }
      ),
      list(...),
      list(header, htmltools::tag("cds-structured-list-body", rows))
    )
  )
}

.structured_list_labels <- function(column_names, columns, call = rlang::caller_env()) {
  labels <- as.list(column_names)
  names(labels) <- column_names

  if (is.null(columns)) {
    return(labels)
  }

  unknown <- setdiff(names(columns), column_names)
  if (is.null(names(columns)) || any(!nzchar(names(columns))) || length(unknown)) {
    cli::cli_abort(
      c(
        "{.arg columns} must be named by columns of {.arg data}.",
        "x" = if (length(unknown)) "Unknown: {.val {unknown}}."
      ),
      call = call
    )
  }

  labels[names(columns)] <- as.list(columns)
  labels
}

# Text for atomic columns (NA shown empty); list columns hold UI as is.
.structured_list_cell <- function(x, i) {
  if (is.list(x)) {
    return(x[[i]])
  }

  value <- x[i]
  if (is.na(value)) "" else as.character(value)
}

#' Update a Carbon Structured List's Selection
#'
#' Change which row of a selectable \code{carbon_structured_list()} is
#' selected, from the server. Its input updates to match.
#'
#' @param inputId The list's \code{id}.
#' @param selected The row to select: a \code{row_key} value, or a row
#'   number if the list has no \code{row_key}. \code{character(0)} clears the
#'   selection. Unknown values clear it too.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_structured_list}}
#'
#' @examples
#' \dontrun{
#' update_carbon_structured_list("plan", selected = "Enterprise")
#'
#' # Clear the selection
#' update_carbon_structured_list("plan", selected = character(0))
#' }
#'
#' @export
update_carbon_structured_list <- function(
  inputId,
  selected,
  session = shiny::getDefaultReactiveDomain()
) {
  if (length(selected) > 1) {
    cli::cli_abort("{.arg selected} must be a single row, or {.code character(0)} to clear the selection.")
  }

  session$sendInputMessage(
    inputId,
    list(selected = if (length(selected)) as.character(selected) else NULL)
  )

  invisible(NULL)
}
