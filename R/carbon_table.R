# Keys identify rows for selection: the `row_key` column's values, or row
# numbers (in data order) when there is no `row_key`.
get_row_keys <- function(data, row_key) {
  if (is.null(row_key)) {
    return(as.character(seq_len(nrow(data))))
  }

  if (!row_key %in% names(data)) {
    stop("`row_key` must name a column in `data`.")
  }

  keys <- data[[row_key]]

  if (anyNA(keys)) {
    stop("`row_key` cannot contain missing values.")
  }

  if (anyDuplicated(keys)) {
    stop("`row_key` must contain unique values.")
  }

  as.character(keys)
}

normalize_columns <- function(data, columns, sortable) {
  data_columns <- names(data)

  if (is.null(columns)) {
    columns <- list()
  }

  missing_columns <- setdiff(data_columns, names(columns))
  columns[missing_columns] <- lapply(missing_columns, identity)
  columns <- columns[data_columns]

  lapply(columns, function(x) {
    if (!inherits(x, "carbon_table_column")) {
      x <- carbon_table_column(label = x)
    }

    if (is.null(x$sortable)) {
      x$sortable <- sortable
    }

    x
  })
}

#' Carbon Table Column Definition
#'
#' Customise how a column is displayed in \code{carbon_table()}.
#'
#' @param label The column header text. Defaults to the column name.
#' @param sortable Whether the column shows a sort control. \code{NULL} uses
#'   the table's \code{sortable} setting.
#' @param formatter Optional function applied to the column's values before
#'   display, e.g. \code{function(x) scales::dollar(x)}.
#'
#' @return A \code{carbon_table_column} object for the \code{columns}
#'   argument of \code{carbon_table()}.
#'
#' @examples
#' carbon_table_column(
#'   label = "Price",
#'   sortable = TRUE,
#'   formatter = function(x) sprintf("$%.2f", x)
#' )
#'
#' @export
carbon_table_column <- function(
  label = NULL,
  sortable = NULL,
  formatter = NULL
) {
  if (!is.null(formatter) && !is.function(formatter)) {
    stop("`formatter` must be a function or NULL.", call. = FALSE)
  }
  structure(
    list(
      label = label,
      sortable = sortable,
      formatter = formatter
    ),
    class = "carbon_table_column"
  )
}

#' Carbon Table Output
#'
#' Create a placeholder for a table rendered with \code{render_carbon_table()}.
#' While the table is recalculating, a skeleton copy of the table is shown in
#' its place. Before the first render the skeleton is built from
#' \code{initial_columns}, \code{initial_rows}, and \code{size}; after that it
#' mirrors the last rendered table (its columns, row count, and size).
#'
#' @param outputId The output slot that will be used to render the table.
#' @param initial_columns Optional column header labels for the skeleton
#'   shown before the first render. Names are ignored. \code{NULL} shows five
#'   unlabelled columns.
#' @param initial_rows Number of rows in the skeleton shown before the first
#'   render.
#' @param size The row height of the skeleton shown before the first render.
#'   One of \code{"xs"}, \code{"sm"}, \code{"md"}, \code{"lg"}, or
#'   \code{"xl"}. Match the \code{size} of the rendered \code{carbon_table()}
#'   so the layout doesn't jump when the table first appears.
#' @param ... Additional UI elements or attributes for the containing
#'   \code{div}.
#'
#' @return A \code{div} tag containing the output and its loading skeleton.
#'
#' @seealso \code{\link{render_carbon_table}}, \code{\link{carbon_table}}
#'
#' @examples
#' carbon_table_output(
#'   "cars",
#'   initial_columns = c("MPG", "Cylinders"),
#'   size = "sm"
#' )
#'
#' @export
carbon_table_output <- function(
  outputId,
  initial_columns = NULL,
  initial_rows = 5,
  size = c("md", "xs", "sm", "lg", "xl"),
  ...
) {
  size <- match.arg(size)

  if (
    !is.numeric(initial_rows) ||
      length(initial_rows) != 1 ||
      is.na(initial_rows) ||
      initial_rows < 0
  ) {
    cli::cli_abort("{.arg initial_rows} must be a single non-negative number.")
  }

  labels <- if (is.null(initial_columns)) {
    rep("", 5)
  } else {
    as.character(unname(initial_columns))
  }

  # Starts in the loading state; srcjs/carbon-table.js toggles
  # `carbon-table-output--loading` as the output recalculates and renders.
  htmltools::tags$div(
    class = "carbon-table-output carbon-table-output--loading",
    list(...),
    shiny::uiOutput(
      outputId,
      class = "carbon-table-output__table"
    ),
    .carbon_table_skeleton(labels, n_rows = initial_rows, size = size)
  )
}

# A regular `cds-table` whose cells hold Carbon skeleton text. Unlike
# `cds-table-skeleton`, which draws its rows inside its shadow root and has no
# `size`, this takes its row heights from `cds-table`, like the real table.
.carbon_table_skeleton <- function(labels, n_rows, size) {
  skeleton_text <- function() {
    htmltools::tags$span(class = "cds--skeleton__text")
  }

  header_cells <- lapply(labels, function(label) {
    htmltools::tag(
      "cds-table-header-cell",
      list(if (nzchar(label)) label else skeleton_text())
    )
  })

  body_rows <- lapply(seq_len(n_rows), function(i) {
    htmltools::tag(
      "cds-table-row",
      c(
        list(size = size),
        lapply(labels, function(label) {
          htmltools::tag("cds-table-cell", list(skeleton_text()))
        })
      )
    )
  })

  .build_carbon_tag(
    "cds-table",
    list(
      class = "carbon-table-output__skeleton",
      size = size,
      `aria-hidden` = "true",
      htmltools::tag(
        "cds-table-head",
        list(
          htmltools::tag(
            "cds-table-header-row",
            c(list(size = size), header_cells)
          )
        )
      ),
      htmltools::tag("cds-table-body", body_rows)
    )
  )
}

#' Render a Carbon Table
#'
#' Server-side counterpart to \code{carbon_table_output()}. The expression
#' should return a \code{carbon_table()}.
#'
#' @param expr An expression that returns a \code{carbon_table()}.
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Whether \code{expr} is already quoted.
#'
#' @return A Shiny render function, to assign to an element of
#'   \code{output}.
#'
#' @seealso \code{\link{carbon_table_output}}, \code{\link{carbon_table}}
#'
#' @examples
#' if (interactive()) {
#'   ui <- carbon_page(
#'     carbon_panel("home", carbon_table_output("cars"))
#'   )
#'
#'   server <- function(input, output, session) {
#'     output$cars <- render_carbon_table({
#'       carbon_table(head(mtcars[, c("mpg", "cyl", "hp")]), sortable = TRUE)
#'     })
#'   }
#'
#'   shiny::shinyApp(ui, server)
#' }
#'
#' @export
render_carbon_table <- function(
  expr,
  env = parent.frame(),
  quoted = FALSE
) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  shiny::renderUI(expr, env = env, quoted = TRUE)
}

# Values that sort numerically in the browser, taken from the raw (unformatted)
# column: numbers, dates/times, logicals, and factors (by level order).
# Returns NULL for columns that sort by their displayed text; NA stays NA.
.sort_values <- function(x) {
  if (is.factor(x)) {
    x <- as.integer(x)
  } else if (is.logical(x) || inherits(x, c("Date", "POSIXt", "difftime"))) {
    x <- as.numeric(x)
  }

  if (!is.numeric(x)) {
    return(NULL)
  }

  # %.17g round-trips doubles exactly
  ifelse(is.na(x), NA_character_, sprintf("%.17g", as.numeric(x)))
}

carbon_table_header <- function(columns, size, sort_values) {
  htmltools::tag(
    "cds-table-head",
    list(
      htmltools::tag(
        "cds-table-header-row",
        c(
          list(size = size),
          unname(
            lapply(names(columns), \(name) {
              column <- columns[[name]]
              htmltools::tag(
                "cds-table-header-cell",
                list(
                  column$label,
                  `is-sortable` = if (column$sortable) "none" else NULL,
                  `data-sort-type` = if (!is.null(sort_values[[name]])) {
                    "numeric"
                  }
                )
              )
            })
          )
        )
      )
    )
  )
}

carbon_table_body <- function(
  data,
  columns,
  size,
  sort_values,
  row_keys = as.character(seq_len(nrow(data))),
  selectable = FALSE,
  selected = character(0),
  page_size = NULL
) {
  for (name in names(columns)) {
    formatter <- columns[[name]]$formatter

    if (!is.null(formatter)) {
      data[[name]] <- formatter(data[[name]])
    }
  }

  # `data-row-index` lets srcjs/table-sort.js restore the original order
  # when a column's sort is cleared; `data-row-key` is what the selection
  # binding (srcjs/bindings/carbon-table-selection.js) reports. A
  # `selection-name` makes Carbon draw the row's checkbox/radio.
  # `data-page-hidden` hides rows after the first page; srcjs/table-pagination.js
  # moves it as the user pages.
  htmltools::tag(
    "cds-table-body",
    lapply(seq_len(nrow(data)), function(i) {
      key <- row_keys[[i]]

      htmltools::tag(
        "cds-table-row",
        c(
          list(
            size = size,
            `data-row-index` = i,
            `data-row-key` = key,
            `selection-name` = if (selectable) key,
            selected = if (selectable && key %in% selected) NA,
            `data-page-hidden` = if (!is.null(page_size) && i > page_size) NA
          ),
          lapply(names(columns), function(name) {
            sort_value <- sort_values[[name]][i]

            htmltools::tag(
              "cds-table-cell",
              list(
                data[[name]][i],
                `data-sort-value` = if (!is.null(sort_value) && !is.na(sort_value)) {
                  sort_value
                }
              )
            )
          })
        )
      )
    })
  )

  # htmltools::tag(
  #   "cds-table-body",
  #   lapply(seq_len(nrow(data)), \(i) {
  #     htmltools::tag(
  #       "cds-table-row",
  #       c(
  #         list(size = size),
  #         unname(lapply(data[i, , drop = FALSE], \(value) {
  #           htmltools::tag("cds-table-cell", as.character(value))
  #         }))
  #       )
  #     )
  #   })
  # )
}


#' Carbon Table Toolbar
#'
#' Define the toolbar shown above a \code{carbon_table()}: an optional search
#' box that filters the table's rows as the user types, any other controls
#' (e.g. buttons), and batch actions that appear when rows are selected.
#'
#' @param ... Controls shown on the right of the toolbar, e.g.
#'   \code{carbon_button()}s.
#' @param search Whether to show a search box. It filters rows in the
#'   browser, matching any cell's text; the server is not involved.
#' @param search_placeholder Placeholder text for the search box.
#' @param batch_actions Optional list of controls (typically
#'   \code{carbon_button()}s) shown in place of the toolbar while one or more
#'   rows are selected, alongside a count and a Cancel button. Requires
#'   \code{selection = "multiple"} in \code{carbon_table()}. Read the
#'   selected rows from the table's \code{_selected} input in the buttons'
#'   observers.
#'
#' @return A \code{carbon_table_toolbar} object for the \code{toolbar}
#'   argument of \code{carbon_table()}.
#'
#' @seealso \code{\link{carbon_table}}
#'
#' @examples
#' carbon_table_toolbar(
#'   carbon_button("add", "Add row"),
#'   batch_actions = list(carbon_button("delete", "Delete"))
#' )
#'
#' @export
carbon_table_toolbar <- function(
  ...,
  search = TRUE,
  search_placeholder = "Filter table",
  batch_actions = NULL
) {
  if (!rlang::is_bool(search)) {
    cli::cli_abort("{.arg search} must be {.code TRUE} or {.code FALSE}.")
  }

  structure(
    list(
      content = rlang::list2(...),
      search = search,
      search_placeholder = search_placeholder,
      batch_actions = batch_actions
    ),
    class = "carbon_table_toolbar"
  )
}

.carbon_table_toolbar_tag <- function(toolbar, size) {
  # Carbon's toolbar only has xs, sm and lg sizes.
  toolbar_size <- if (size %in% c("xs", "sm")) size else "lg"

  htmltools::tag(
    "cds-table-toolbar",
    list(
      slot = "toolbar",
      size = toolbar_size,
      if (length(toolbar$batch_actions)) {
        htmltools::tag("cds-table-batch-actions", unname(toolbar$batch_actions))
      },
      htmltools::tag(
        "cds-table-toolbar-content",
        c(
          list(size = toolbar_size),
          list(
            if (toolbar$search) {
              htmltools::tag(
                "cds-table-toolbar-search",
                list(
                  persistent = NA,
                  placeholder = toolbar$search_placeholder,
                  size = toolbar_size
                )
              )
            }
          ),
          toolbar$content
        )
      )
    )
  )
}

#' Carbon Data Table
#'
#' Create a Carbon data table from a data frame. Use it directly in the UI,
#' or return it from \code{render_carbon_table()}.
#'
#' @section Row selection:
#' With \code{selection = "multiple"} or \code{"single"}, each row gets a
#' checkbox or radio button and the selected rows are available as
#' \code{input$<id>_selected}, where \code{<id>} is the table's \code{id}.
#' Inside \code{render_carbon_table()} the id defaults to the output's id, so
#' \code{output$cars <- render_carbon_table(...)} gives
#' \code{input$cars_selected}.
#'
#' The value is the selected rows' \code{row_key} values (a character
#' vector) if \code{row_key} is set, and otherwise their row numbers in
#' \code{data} (unaffected by sorting or filtering in the browser).
#' \code{NULL} means nothing is selected. Change the selection from the server
#' with \code{update_carbon_table_selection()}.
#'
#' Re-rendering the table resets the selection to \code{selected}; pass
#' \code{selected = shiny::isolate(input$<id>_selected)} to keep it.
#'
#' @section Pagination:
#' With \code{page_size} set, the table shows that many rows at a time, with
#' Carbon's pagination bar below it for moving between pages and changing
#' the number of rows per page. Paging happens in the browser, like sorting
#' and search: every row is sent to the browser, so it suits tables of up to
#' a few thousand rows. Searching goes back to the first page and pages
#' through the matching rows; sorting keeps the current page.
#'
#' Selections are kept across pages, and \code{input$<id>_selected} includes
#' rows on every page. The header checkbox selects or clears the rows on the
#' current page.
#'
#' The current number of rows per page is available as
#' \code{input$<id>_page_size}, where \code{<id>} is the table's \code{id}
#' (inside \code{render_carbon_table()}, the output's id). It is reported
#' when the table renders and whenever the user picks another size.
#' Re-rendering the table resets it to \code{page_size}; pass
#' \code{page_size = shiny::isolate(input$<id>_page_size)} (with a default
#' for the first render) to keep the user's choice.
#'
#' A paginated table is returned wrapped in a \code{div} with its pagination
#' bar; \code{...} and \code{id} still apply to the \code{cds-table}.
#'
#' @param data A data frame. Every column is shown, in the data's column
#'   order.
#' @param columns Optional named list customising columns, keyed by column
#'   name. Each element is either a header label or a
#'   \code{carbon_table_column()}. Columns not listed use their name as the
#'   label.
#' @param formatters Not yet implemented; currently has no effect. Use the
#'   \code{formatter} argument of \code{carbon_table_column()} instead.
#' @param size The row height. One of \code{"xs"}, \code{"sm"}, \code{"md"},
#'   \code{"lg"}, or \code{"xl"}.
#' @param sortable Whether columns show sort controls by default. Override
#'   per column with \code{carbon_table_column(sortable = )}. Numeric, date,
#'   date-time, and logical columns sort by their underlying values, and
#'   factors by level order, regardless of any \code{formatter}. Other
#'   columns sort by their displayed text. Missing values sort last.
#' @param selection Row selection: \code{"none"}, \code{"multiple"}
#'   (checkboxes, plus a select-all checkbox in the header), or
#'   \code{"single"} (radio buttons). See the Row selection section.
#' @param selected Rows selected initially: \code{row_key} values, or row
#'   numbers if there is no \code{row_key}.
#' @param row_key Optional name of a column that uniquely identifies each
#'   row. Its values must be unique and not missing, and are what the
#'   selection input reports.
#' @param title,description Optional title and description shown above the
#'   table.
#' @param toolbar Optional \code{carbon_table_toolbar()}.
#' @param page_size Optional number of rows per page. \code{NULL} (the
#'   default) shows every row, without pagination. See the Pagination
#'   section.
#' @param page_sizes The choices of rows per page offered by the pagination
#'   bar. \code{page_size} is added if it isn't one of them.
#' @param id Optional id for the table. Determines the selection input's
#'   name. Inside \code{render_carbon_table()} it defaults to the output id;
#'   in a module, wrap it in \code{ns()}.
#' @param ... Additional attributes for the underlying \code{cds-table}
#'   element.
#'
#' @return An HTML tag representing a Carbon data table.
#'
#' @seealso \code{\link{carbon_table_column}},
#'   \code{\link{carbon_table_toolbar}}, \code{\link{render_carbon_table}},
#'   \code{\link{update_carbon_table_selection}}
#'
#' @examples
#' carbon_table(head(mtcars[, c("mpg", "cyl", "hp")]))
#'
#' carbon_table(
#'   data.frame(name = c("Ada", "Grace"), score = c(0.91, 0.87)),
#'   columns = list(
#'     name = "Name",
#'     score = carbon_table_column(
#'       label = "Score",
#'       formatter = function(x) sprintf("%.0f%%", x * 100)
#'     )
#'   ),
#'   size = "sm",
#'   sortable = TRUE
#' )
#'
#' # Title, toolbar with search and batch actions, and row selection
#' carbon_table(
#'   head(mtcars[, c("mpg", "cyl", "hp")]),
#'   title = "Cars",
#'   description = "From mtcars",
#'   toolbar = carbon_table_toolbar(
#'     batch_actions = list(carbon_button("delete", "Delete"))
#'   ),
#'   selection = "multiple",
#'   id = "cars"
#' )
#'
#' # 10 rows per page
#' carbon_table(mtcars, sortable = TRUE, page_size = 10)
#'
#' @export
carbon_table <- function(
  data,
  columns = NULL,
  formatters = NULL,
  size = c("md", "xs", "sm", "lg", "xl"),
  sortable = FALSE,
  selection = c("none", "multiple", "single"),
  selected = NULL,
  row_key = NULL,
  title = NULL,
  description = NULL,
  toolbar = NULL,
  page_size = NULL,
  page_sizes = c(10, 25, 50, 100),
  id = NULL,
  ...
) {
  size <- match.arg(size)
  selection <- match.arg(selection)
  selectable <- selection != "none"
  page_sizes <- .check_page_sizes(page_size, page_sizes)

  row_keys <- get_row_keys(data, row_key)
  columns <- normalize_columns(data, columns, sortable)

  column_names <- names(columns)
  missing_columns <- setdiff(column_names, names(data))

  if (length(missing_columns) > 0) {
    stop(
      "Unknown column(s): ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  selected <- .check_table_selected(selected, row_keys, selection)

  if (!is.null(toolbar) && !inherits(toolbar, "carbon_table_toolbar")) {
    cli::cli_abort("{.arg toolbar} must be created with {.fn carbon_table_toolbar}.")
  }
  if (
    !is.null(toolbar) && length(toolbar$batch_actions) && selection != "multiple"
  ) {
    cli::cli_abort(
      "Batch actions need {.code selection = \"multiple\"} in {.fn carbon_table}."
    )
  }

  data <- data[, column_names, drop = FALSE]
  sort_values <- lapply(data, .sort_values)

  table <- .build_carbon_tag(
    "cds-table",
    c(
      list(
        id = id,
        size = size,
        `is-selectable` = if (selectable) NA,
        radio = if (selection == "single") NA,
        class = if (selectable) "carbonite-selectable-table",
        `data-row-key-type` = if (selectable) {
          if (is.null(row_key)) "index" else "key"
        }
      ),
      list(...),
      list(
        if (!is.null(title)) {
          htmltools::tag("cds-table-header-title", list(slot = "title", title))
        },
        if (!is.null(description)) {
          htmltools::tag(
            "cds-table-header-description",
            list(slot = "description", description)
          )
        },
        if (!is.null(toolbar)) .carbon_table_toolbar_tag(toolbar, size),
        carbon_table_header(
          columns = columns,
          size = size,
          sort_values = sort_values
        ),
        carbon_table_body(
          data = data,
          columns = columns,
          size = size,
          sort_values = sort_values,
          row_keys = row_keys,
          selectable = selectable,
          selected = selected,
          page_size = page_size
        )
      )
    )
  )

  if (is.null(page_size)) {
    return(table)
  }

  # srcjs/table-pagination.js finds the table and its pagination through
  # this wrapper.
  htmltools::tags$div(
    class = "carbonite-paginated-table",
    table,
    .carbon_table_pagination(nrow(data), page_size, page_sizes, size)
  )
}

.check_page_sizes <- function(page_size, page_sizes, call = rlang::caller_env()) {
  is_count <- function(x) is.numeric(x) && all(!is.na(x) & x >= 1 & x == round(x))

  if (!is.null(page_size) && (length(page_size) != 1 || !is_count(page_size))) {
    cli::cli_abort("{.arg page_size} must be a single whole number of at least 1, or {.code NULL}.", call = call)
  }
  if (!length(page_sizes) || !is_count(page_sizes)) {
    cli::cli_abort("{.arg page_sizes} must be whole numbers of at least 1.", call = call)
  }

  sort(unique(c(page_sizes, page_size)))
}

.carbon_table_pagination <- function(total, page_size, page_sizes, size) {
  # Carbon's pagination has sm, md and lg sizes.
  pagination_size <- switch(size, xs = , sm = "sm", md = "md", "lg")

  htmltools::tag(
    "cds-pagination",
    c(
      list(
        page = 1,
        `page-size` = page_size,
        `total-items` = total,
        size = pagination_size
      ),
      lapply(page_sizes, function(n) {
        htmltools::tag("cds-select-item", list(value = n, n))
      })
    )
  )
}

.check_table_selected <- function(selected, row_keys, selection) {
  if (is.null(selected) || !length(selected)) {
    return(character(0))
  }
  if (selection == "none") {
    cli::cli_abort("{.arg selected} needs {.arg selection} to be {.val multiple} or {.val single}.")
  }

  selected <- as.character(selected)
  unknown <- setdiff(selected, row_keys)

  if (length(unknown)) {
    cli::cli_abort(c(
      "{.arg selected} must match rows of {.arg data}.",
      "x" = "Unknown: {.val {unknown}}.",
      "i" = "Use {.arg row_key} values, or row numbers if there is no {.arg row_key}."
    ))
  }
  if (selection == "single" && length(selected) > 1) {
    cli::cli_abort("With {.code selection = \"single\"}, {.arg selected} must be a single row.")
  }

  selected
}

#' Update a Carbon Table's Selected Rows
#'
#' Change which rows of a \code{carbon_table()} are selected, from the
#' server. The table's \code{_selected} input updates to match.
#'
#' @param id The table's id: the \code{id} passed to \code{carbon_table()},
#'   or the output id when it is rendered with \code{render_carbon_table()}.
#'   Not the \code{_selected} input name.
#' @param selected The rows to select: \code{row_key} values, or row numbers
#'   if the table has no \code{row_key}. \code{NULL} or an empty vector
#'   clears the selection. Unknown keys are ignored.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_table}}
#'
#' @examples
#' \dontrun{
#' # Select the first two rows of output$cars
#' update_carbon_table_selection("cars", selected = 1:2)
#'
#' # Clear the selection
#' update_carbon_table_selection("cars", selected = NULL)
#' }
#'
#' @export
update_carbon_table_selection <- function(
  id,
  selected = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  session$sendInputMessage(
    paste0(id, "_selected"),
    list(selected = as.character(selected))
  )
  invisible(NULL)
}
