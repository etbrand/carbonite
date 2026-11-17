get_row_keys <- function(data, row_key) {
  if (is.null(row_key)) {
    return(paste0("row_", seq_len(nrow(data))))
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

carbon_table_body <- function(data, columns, size, sort_values) {
  for (name in names(columns)) {
    formatter <- columns[[name]]$formatter

    if (!is.null(formatter)) {
      data[[name]] <- formatter(data[[name]])
    }
  }

  # `data-row-index` lets srcjs/table-sort.js restore the original order
  # when a column's sort is cleared.
  htmltools::tag(
    "cds-table-body",
    lapply(seq_len(nrow(data)), function(i) {
      htmltools::tag(
        "cds-table-row",
        c(
          list(size = size, `data-row-index` = i),
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

#' Carbon Data Table
#'
#' Create a Carbon data table from a data frame. Use it directly in the UI,
#' or return it from \code{render_carbon_table()}.
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
#' @param selectable Not yet implemented; currently has no effect.
#' @param row_key Optional name of a column that uniquely identifies each row.
#'   Its values must be unique and not missing. Currently it is only
#'   validated.
#' @param ... Additional attributes for the underlying \code{cds-table}
#'   element.
#'
#' @return An HTML tag representing a Carbon data table.
#'
#' @seealso \code{\link{carbon_table_column}},
#'   \code{\link{render_carbon_table}}
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
#' @export
carbon_table <- function(
  data,
  columns = NULL,
  formatters = NULL,
  size = c("md", "xs", "sm", "lg", "xl"),
  sortable = FALSE,
  selectable = FALSE,
  row_key = NULL,
  ...
) {
  size <- match.arg(size)

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

  data <- data[, column_names, drop = FALSE]
  sort_values <- lapply(data, .sort_values)

  .build_carbon_tag(
    "cds-table",
    c(
      size = size,
      list(...),
      list(
        carbon_table_header(
          columns = columns,
          size = size,
          sort_values = sort_values
        ),
        carbon_table_body(
          data = data,
          columns = columns,
          size = size,
          sort_values = sort_values
        )
      )
    )
  )
}
