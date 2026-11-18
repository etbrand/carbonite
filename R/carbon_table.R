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
#' @param action If \code{TRUE}, each cell's content is a link-styled button,
#'   e.g. to open a row's details in a modal. Clicking one (or pressing
#'   \kbd{Enter} on it) sets \code{input$<id>_cell_click}, where \code{<id>}
#'   is the table's \code{id} (inside \code{render_carbon_table()}, the
#'   output's id), to a list with \code{row} (the row's number in
#'   \code{data}), \code{key} (its \code{row_key} value, or the row number as
#'   a string) and \code{column} (the column's name). It's an event, so
#'   clicking the same cell again triggers observers again.
#' @param action_icon Optional: the name of a Carbon icon (see
#'   \code{carbon_icon()}). The cell's content then stays plain text, followed
#'   by an icon-only button that triggers the action, e.g. \code{"popup"} for
#'   one that opens a modal. Implies \code{action = TRUE};
#'   \code{input$<id>_cell_click} is the same.
#' @param action_label With \code{action_icon}: what the button does, e.g.
#'   \code{"Open profile"}. It's the button's tooltip, and with the cell's
#'   text, its accessible name ("Open profile: Chad").
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
#' # Names that open something when clicked (see input$<id>_cell_click)
#' carbon_table_column(label = "Name", action = TRUE)
#'
#' # Plain names, each followed by a button that opens a modal
#' carbon_table_column(label = "Name", action_icon = "popup", action_label = "Open details")
#'
#' @export
carbon_table_column <- function(
  label = NULL,
  sortable = NULL,
  formatter = NULL,
  action = FALSE,
  action_icon = NULL,
  action_label = "Open"
) {
  if (!is.null(formatter) && !is.function(formatter)) {
    stop("`formatter` must be a function or NULL.", call. = FALSE)
  }
  if (!rlang::is_bool(action)) {
    cli::cli_abort("{.arg action} must be {.code TRUE} or {.code FALSE}.")
  }
  if (!is.null(action_icon)) {
    .check_icon_name(action_icon, arg = "action_icon")
    if (!rlang::is_string(action_label) || !nzchar(action_label)) {
      cli::cli_abort("{.arg action_label} must be a single, non-empty string.")
    }
    action <- TRUE
  }
  structure(
    list(
      label = label,
      sortable = sortable,
      formatter = formatter,
      action = action,
      action_icon = action_icon,
      action_label = action_label
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
  func <- shiny::exprToFunction(expr, env, quoted = TRUE)

  shiny::renderUI({
    ui <- func()
    # carbon_table(lazy_details = TRUE): answer requests for row details
    .register_lazy_details(ui)
    ui
  })
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
  page_size = NULL,
  details = NULL,
  lazy_details = FALSE
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
  #
  # With `details`, each row is followed by its `cds-table-expanded-row`,
  # linked by `data-expands-row` (sorting and paging move the pair together).
  # Every row gets one, empty (`data-empty`) when it has no details: Carbon's
  # search reads each row's next sibling as its expanded row. Empty ones are
  # hidden, and srcjs/table-expand.js removes their rows' expand buttons.
  htmltools::tag(
    "cds-table-body",
    unlist(recursive = FALSE, lapply(seq_len(nrow(data)), function(i) {
      key <- row_keys[[i]]
      page_hidden <- if (!is.null(page_size) && i > page_size) NA

      row <- htmltools::tag(
        "cds-table-row",
        c(
          list(
            size = size,
            `data-row-index` = i,
            `data-row-key` = key,
            `selection-name` = if (selectable) key,
            selected = if (selectable && key %in% selected) NA,
            `data-page-hidden` = page_hidden
          ),
          lapply(names(columns), function(name) {
            sort_value <- sort_values[[name]][i]
            content <- data[[name]][i]

            # carbon_table_column(action = TRUE): a button that
            # srcjs/table-cell-action.js reports as input$<id>_cell_click.
            # Same text, so search and text sorting are unaffected.
            column <- columns[[name]]
            if (isTRUE(column$action) && !is.null(column$action_icon)) {
              # Plain text, then an icon-only button
              text <- if (is.character(content) && length(content) == 1 && !is.na(content)) content
              content <- htmltools::tags$span(
                class = "carbonite-cell-with-action",
                htmltools::tags$span(content),
                htmltools::tags$button(
                  type = "button",
                  class = "carbonite-cell-action carbonite-cell-action--icon",
                  `data-column` = name,
                  title = column$action_label,
                  `aria-label` = if (is.null(text)) column$action_label else paste0(column$action_label, ": ", text),
                  carbon_icon(column$action_icon, size = 16)
                )
              )
            } else if (isTRUE(column$action)) {
              content <- htmltools::tags$button(
                type = "button",
                class = "carbonite-cell-action",
                `data-column` = name,
                content
              )
            }

            htmltools::tag(
              "cds-table-cell",
              list(
                content,
                `data-sort-value` = if (!is.null(sort_value) && !is.na(sort_value)) {
                  sort_value
                }
              )
            )
          })
        )
      )

      if (is.null(details)) {
        return(list(row))
      }

      content <- details[[i]]
      list(
        row,
        htmltools::tag(
          "cds-table-expanded-row",
          list(
            `data-expands-row` = i,
            `data-empty` = if (is.null(content)) NA,
            # A placeholder until srcjs/table-lazy-details.js loads the content
            `data-lazy` = if (lazy_details) NA,
            `data-page-hidden` = page_hidden,
            content
          )
        )
      )
    }))
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
#' @section Expandable rows:
#' With \code{row_details}, each row with details gets a button that
#' expands it to show them in a full-width area below the row: e.g. a
#' description, a nested table, or a plot. The details stay with their row
#' when the table is sorted or paged, and the search box also matches their
#' text. Their content can include Shiny inputs and outputs.
#'
#' Columns used only in the details can be left out of \code{data} and
#' passed as a vector instead: \code{row_details = notes}.
#'
#' With \code{lazy_details = TRUE}, a \code{row_details} function isn't
#' called when the table renders, but on the server the first time each row
#' is expanded, for that row only; a loading placeholder shows meanwhile.
#' Use it when the details are slow or expensive to build, e.g. fetched from
#' a web API. It needs the table to be rendered with
#' \code{render_carbon_table()}. Every row gets an expand button, since
#' which rows have details isn't known in advance; a row whose details turn
#' out to be empty loses its button when expanded. The search box only
#' matches the details of rows that have been expanded. The function's
#' result isn't kept between renders, so cache slow lookups yourself.
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
#' @param row_details Optional extra content for each row, shown below it
#'   when the user expands the row: a function that takes a row (a one-row
#'   data frame) and returns UI, or a vector or list with one element per
#'   row. A function with a second argument also gets the row's number in
#'   \code{data}, e.g. to look up data that isn't in the table. Rows whose content is \code{NULL}, \code{NA}, or \code{""} can't be
#'   expanded. See the Expandable rows section.
#' @param expand_all If \code{TRUE}, add a button to the header that expands
#'   or collapses every row. Needs \code{row_details}.
#' @param lazy_details If \code{TRUE}, call the \code{row_details} function
#'   only when a row is first expanded, instead of for every row when the
#'   table renders. Needs \code{row_details} to be a function, and the table
#'   to be rendered with \code{render_carbon_table()}. See the Expandable rows
#'   section.
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
#' # Expandable rows, from a function of each row
#' cars <- data.frame(model = rownames(mtcars), mpg = mtcars$mpg)[1:5, ]
#' carbon_table(
#'   cars,
#'   row_details = function(row) {
#'     htmltools::p(row$model, "does", row$mpg, "miles per gallon.")
#'   },
#'   expand_all = TRUE
#' )
#'
#' # ... or from a vector, one element per row (NA: no details)
#' carbon_table(
#'   cars,
#'   row_details = c("Classic", NA, "Economical", NA, "Muscle car")
#' )
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
  row_details = NULL,
  expand_all = FALSE,
  lazy_details = FALSE,
  id = NULL,
  ...
) {
  size <- match.arg(size)
  selection <- match.arg(selection)
  selectable <- selection != "none"
  page_sizes <- .check_page_sizes(page_size, page_sizes)
  if (!rlang::is_bool(lazy_details)) {
    cli::cli_abort("{.arg lazy_details} must be {.code TRUE} or {.code FALSE}.")
  }
  if (lazy_details && !is.function(row_details)) {
    cli::cli_abort("{.arg lazy_details} needs {.arg row_details} to be a function of a row.")
  }

  # Lazy: a placeholder for every row now; render_carbon_table() calls
  # `row_details` for a row when it's expanded (see .register_lazy_details())
  lazy <- if (lazy_details) {
    list(token = .next_details_token(), fn = row_details, data = data, id = id)
  }
  details <- if (lazy_details) {
    rep(list(.details_placeholder()), nrow(data))
  } else {
    .row_details(row_details, data)
  }

  if (!rlang::is_bool(expand_all)) {
    cli::cli_abort("{.arg expand_all} must be {.code TRUE} or {.code FALSE}.")
  }
  if (expand_all && is.null(details)) {
    cli::cli_abort("{.arg expand_all} needs {.arg row_details}.")
  }

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
        expandable = if (!is.null(details)) NA,
        `batch-expansion` = if (expand_all) NA,
        # srcjs/table-lazy-details.js sends this back with each request, so
        # replies meant for an earlier render are ignored
        `data-lazy-details` = lazy$token,
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
          page_size = page_size,
          details = details,
          lazy_details = lazy_details
        )
      )
    )
  )

  if (!is.null(page_size)) {
    # srcjs/table-pagination.js finds the table and its pagination through
    # this wrapper.
    table <- htmltools::tags$div(
      class = "carbonite-paginated-table",
      table,
      .carbon_table_pagination(nrow(data), page_size, page_sizes, size)
    )
  }

  # Picked up by render_carbon_table()
  attr(table, "carbonite_lazy_details") <- lazy
  table
}

# Each row's details as a list (NULL for none), or NULL without `row_details`.
.row_details <- function(row_details, data, call = rlang::caller_env()) {
  if (is.null(row_details)) {
    return(NULL)
  }

  n <- nrow(data)

  if (is.function(row_details)) {
    details <- lapply(seq_len(n), function(i) .call_row_details(row_details, data, i))
  } else if (is.atomic(row_details) || is.list(row_details) && !inherits(row_details, "shiny.tag")) {
    if (length(row_details) != n) {
      cli::cli_abort(
        "{.arg row_details} must have one element per row of {.arg data} ({n}), not {length(row_details)}.",
        call = call
      )
    }
    details <- lapply(seq_len(n), function(i) row_details[[i]])
  } else {
    cli::cli_abort(
      "{.arg row_details} must be a function of a row, or a vector or list with one element per row.",
      call = call
    )
  }

  lapply(details, function(x) if (.is_empty_details(x)) NULL else x)
}

# Call a row_details function for row `i`: with the one-row data frame, and
# also the row number if the function takes a second argument (e.g. to look
# up data that isn't in the table's columns).
.call_row_details <- function(fn, data, i) {
  row <- data[i, , drop = FALSE]
  args <- names(formals(fn))
  if (length(args) >= 2 || "..." %in% args) fn(row, i) else fn(row)
}

# No details for a row: NULL, NA, or ""
.is_empty_details <- function(x) {
  is.null(x) ||
    (is.atomic(x) && length(x) == 1 && (is.na(x) || identical(as.character(x), "")))
}

# Lazy row details ------------------------------------------------------------
#
# carbon_table(lazy_details = TRUE) renders a placeholder in each expanded
# row and attaches its row_details function and data to the tag.
# render_carbon_table() registers them for its output; when rows are
# expanded, srcjs/table-lazy-details.js sends `input$<id>_details_request`
# (list(token, rows)), and the observer below calls the function for those
# rows and sends their HTML back in a "carbonite-table-details" message.

.carbonite_state <- new.env(parent = emptyenv())

# A new token for each lazy table, so replies meant for an earlier render
# are ignored (by the server and the browser). A counter, so building a
# table doesn't touch the random number generator.
.next_details_token <- function() {
  last <- .carbonite_state$details_token
  .carbonite_state$details_token <- if (is.null(last)) 1 else last + 1
  sprintf("lazy-%d", .carbonite_state$details_token)
}

# Shown until a lazy row's details arrive. No text, so the table's search
# doesn't match it.
.details_placeholder <- function() {
  htmltools::div(
    class = "carbonite-details-loading",
    role = "status",
    `aria-label` = "Loading details",
    htmltools::span(class = "cds--skeleton__text"),
    htmltools::span(class = "cds--skeleton__text")
  )
}

.details_error <- function() {
  htmltools::div(class = "carbonite-details-error", "Details couldn't be loaded.")
}

# Called by render_carbon_table() with what its expression returned
.register_lazy_details <- function(ui, session = shiny::getDefaultReactiveDomain()) {
  lazy <- attr(ui, "carbonite_lazy_details", exact = TRUE)
  if (is.null(lazy) || is.null(session)) {
    return(invisible())
  }

  # Like the selection input, named after the table's id or else the
  # output's (already namespaced in a module). Requests and replies use
  # full ids, so work at the root session.
  base <- if (!is.null(lazy$id)) {
    lazy$id
  } else {
    shiny::getCurrentOutputInfo(session = session)$name
  }
  root <- session$rootScope()
  registry <- root$userData$carbonite_lazy_details
  if (is.null(registry)) {
    registry <- root$userData$carbonite_lazy_details <- new.env(parent = emptyenv())
  }

  first_render <- is.null(registry[[base]])
  registry[[base]] <- lazy

  # One observer per table, for the session; it always uses the latest render
  if (first_render) {
    input_name <- paste0(base, "_details_request")
    shiny::observeEvent(
      root$input[[input_name]],
      .send_lazy_details(root, base, registry[[base]], root$input[[input_name]]),
      domain = root
    )
  }
  invisible()
}

# Build the requested rows' details and send them to the browser
.send_lazy_details <- function(session, base, lazy, request) {
  if (is.null(lazy) || !identical(request$token, lazy$token)) {
    return(invisible())
  }

  rows <- suppressWarnings(as.integer(unlist(request$rows)))
  rows <- unique(rows[!is.na(rows) & rows >= 1 & rows <= nrow(lazy$data)])

  details <- lapply(rows, function(i) {
    content <- tryCatch(
      # Isolated: reading reactives here shouldn't make the observer depend
      # on them
      shiny::isolate(.call_row_details(lazy$fn, lazy$data, i)),
      error = function(e) {
        cli::cli_warn(c(
          "{.arg row_details} failed for row {i} of table {.val {base}}.",
          "x" = conditionMessage(e)
        ))
        .details_error()
      }
    )
    if (.is_empty_details(content)) {
      return(list(row = i, empty = TRUE))
    }

    rendered <- htmltools::renderTags(content)
    list(
      row = i,
      empty = FALSE,
      html = rendered$html,
      deps = lapply(
        htmltools::resolveDependencies(rendered$dependencies),
        shiny::createWebDependency
      )
    )
  })

  session$sendCustomMessage(
    "carbonite-table-details",
    list(table = base, token = lazy$token, details = details)
  )
  invisible(details)
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
