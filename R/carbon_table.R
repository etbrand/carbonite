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

#' @export
carbon_table_output <- function(
  outputId,
  initial_columns = NULL,
  size = "md",
  show_header = FALSE,
  show_toolbar = FALSE,
  ...
) {
  labels <- if (is.null(names(initial_columns))) {
    initial_columns
  } else {
    unname(initial_columns)
  }

  htmltools::tags$div(
    class = "carbon-table-output",
    list(...),
    shiny::uiOutput(
      outputId,
      class = "carbon-table-output__table"
    ),
    htmltools::tag(
      "cds-table-skeleton",
      c(
        list(
          class = "carbon-table-output__skeleton",
          `data-show-header` = if (show_header) "true" else "false",
          `data-show-toolbar` = if (show_toolbar) "true" else "false",
          `data-headers` = jsonlite::toJSON(labels, auto_unbox = TRUE)
        )
      )
    )
  )
}

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

carbon_table_header <- function(columns, size) {
  htmltools::tag(
    "cds-table-head",
    list(
      htmltools::tag(
        "cds-table-header-row",
        c(
          list(size = size),
          unname(
            lapply(columns, \(column) {
              htmltools::tag(
                "cds-table-header-cell",
                list(
                  column$label,
                  `is-sortable` = if (column$sortable) "none" else NULL
                )
              )
            })
          )
        )
      )
    )
  )
}

carbon_table_body <- function(data, columns, size) {
  for (name in names(columns)) {
    formatter <- columns[[name]]$formatter

    if (!is.null(formatter)) {
      data[[name]] <- formatter(data[[name]])
    }
  }

  htmltools::tag(
    "cds-table-body",
    lapply(seq_len(nrow(data)), function(i) {
      htmltools::tag(
        "cds-table-row",
        c(
          list(size = size),
          lapply(names(columns), function(name) {
            htmltools::tag("cds-table-cell", data[[name]][i])
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

#' @export
carbon_table <- function(
  data,
  columns = NULL,
  formatters = NULL,
  size = c("md", "xs", "sm", "lg", "xl"),
  show_header = FALSE,
  show_toolbar = FALSE,
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

  htmltools::tag(
    "cds-table",
    c(
      list(...),
      list(
        `data-show-header` = if (show_header) "true" else "false",
        `data-show-toolbar` = if (show_toolbar) "true" else "false",
        carbon_table_header(columns = columns, size = size),
        carbon_table_body(data = data, columns = columns, size = size)
      )
    )
  )
}
