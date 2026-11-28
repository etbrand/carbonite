#' Carbon CSS Grid
#'
#' Create a responsive Carbon CSS grid. Place \code{carbon_column()} elements
#' inside it.
#'
#' The grid has 4 columns at the \code{sm} breakpoint, 8 at \code{md}, and 16
#' at \code{lg}, \code{xlg} and \code{max}.
#'
#' Carbon's grid has gutters between columns but no space between rows: when
#' columns wrap onto several rows (e.g. a grid of tiles), the rows touch.
#' \code{row_gap} adds space between them, typically the same as the column
#' gutter (\code{row_gap = 7}, i.e. 2rem, on wide screens).
#'
#' @param ... \code{carbon_column()} elements and any additional attributes
#'   for the grid \code{div}.
#' @param row_gap Space between rows, as a step of Carbon's spacing scale:
#'   a whole number from 1 to 13, for \code{--cds-spacing-01} (0.125rem) to
#'   \code{--cds-spacing-13} (10rem), e.g. \code{5} for 1rem or \code{7} for
#'   2rem. \code{NULL} (the default) for none, as in Carbon.
#'
#' @return A \code{div} tag with the Carbon grid class.
#'
#' @seealso \code{\link{carbon_column}}
#'
#' @examples
#' carbon_grid(
#'   carbon_column(width = 8, htmltools::p("Main content")),
#'   carbon_column(width = c(sm = 4, md = 8, lg = 8), htmltools::p("Sidebar"))
#' )
#'
#' # Tiles in rows of two, with the same 2rem gap between rows as between
#' # columns
#' carbon_grid(
#'   row_gap = 7,
#'   carbon_column(width = 8, carbon_tile("One")),
#'   carbon_column(width = 8, carbon_tile("Two")),
#'   carbon_column(width = 8, carbon_tile("Three"))
#' )
#'
#' @export
carbon_grid <- function(..., row_gap = NULL) {
  style <- if (!is.null(row_gap)) {
    sprintf("row-gap: %s;", .spacing_token(row_gap, arg = "row_gap"))
  }
  .with_carbon_dependency(htmltools::tags$div(class = "cds--css-grid", style = style, ...))
}

# The CSS for step `step` (1-13) of Carbon's spacing scale, with its value as
# a fallback, e.g. 7 -> "var(--cds-spacing-07, 2rem)"
.spacing_token <- function(step, arg = "step", call = rlang::caller_env()) {
  scale <- c(
    "0.125rem", "0.25rem", "0.5rem", "0.75rem", "1rem", "1.5rem", "2rem",
    "2.5rem", "3rem", "4rem", "5rem", "6rem", "10rem"
  )
  valid <- is.numeric(step) && length(step) == 1 && !is.na(step) &&
    step == round(step) && step >= 1 && step <= length(scale)
  if (!valid) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a step of Carbon's spacing scale: a whole number from 1 to 13.",
        "i" = "For example, {.code {arg} = 5} is 1rem and {.code {arg} = 7} is 2rem."
      ),
      call = call
    )
  }
  sprintf("var(--cds-spacing-%02d, %s)", as.integer(step), scale[[step]])
}

normalize_col_width <- function(width) {
  if (is.null(width)) {
    return(width)
  }

  max_widths <- c(
    sm = 4,
    md = 8,
    lg = 16,
    xlg = 16,
    max = 16
  )

  breakpoints <- names(max_widths)

  for (bp in intersect(names(width), breakpoints)) {
    if (width[[bp]] > max_widths[[bp]]) {
      cli::cli_abort(
        c(
          "Invalid width supplied for the {.val {bp}} breakpoint.",
          "x" = "{.arg width} specifies {.val {width[[bp]]}} grid units for {.val {bp}}.",
          "i" = "The {.val {bp}} grid has only {.val {max_widths[[bp]]}} columns.",
          "i" = "Use a value between {.val 1} and {.val {max_widths[[bp]]}}."
        ),
        call = rlang::caller_env()
      )
    }
  }

  if (is.null(names(width))) {
    if (length(width) == 1) {
      width <- c(
        sm = min(width, max_widths[["sm"]]),
        md = min(width, max_widths[["md"]]),
        lg = min(width, max_widths[["lg"]]),
        xlg = min(width, max_widths[["xlg"]]),
        max = min(width, max_widths[["max"]])
      )
    } else if (length(width) == length(breakpoints)) {
      names(width) <- breakpoints
    } else {
      cli::cli_abort(
        c(
          "{.arg width} must be one of:",
          "*" = "A single number (e.g. {.code width = 4})",
          "*" = "A named vector (e.g. {.code c(md = 8, lg = 4)})",
          "*" = paste(
            "An unnamed vector of length {length(breakpoints)}",
            "(e.g. {.code c(2, 4, 8, 8, 8)})"
          )
        ),
        call = rlang::caller_env()
      )
    }
  } else {
    invalid <- setdiff(names(width), breakpoints)

    if (length(invalid) > 0) {
      cli::cli_abort(
        c(
          "Invalid breakpoint name(s) supplied to {.arg width}.",
          "x" = "Unknown breakpoint{?s}: {.val {invalid}}",
          "i" = "Valid breakpoints are: {.val {breakpoints}}"
        ),
        call = rlang::caller_env()
      )
    }

    if (anyDuplicated(names(width))) {
      cli::cli_abort(
        c(
          "Breakpoint names in {.arg width} must be unique.",
          "x" = "Duplicate breakpoint name{?s} detected."
        ),
        call = rlang::caller_env()
      )
    }
  }

  width
}

#' Carbon Grid Column
#'
#' Create a column inside a \code{carbon_grid()}.
#'
#' @param ... UI elements and any additional attributes for the column
#'   \code{div}.
#' @param width How many grid columns to span. One of:
#'   \itemize{
#'     \item \code{NULL} (the default): no explicit span.
#'     \item A single number, used at every breakpoint and capped at each
#'       breakpoint's column count.
#'     \item A named vector for specific breakpoints, e.g.
#'       \code{c(md = 8, lg = 4)}. Names must be \code{sm}, \code{md},
#'       \code{lg}, \code{xlg} or \code{max}.
#'     \item An unnamed vector of length 5, giving spans for \code{sm},
#'       \code{md}, \code{lg}, \code{xlg} and \code{max} in order.
#'   }
#'   A span larger than a breakpoint's column count is an error.
#'
#' @return A \code{div} tag with Carbon grid column classes.
#'
#' @seealso \code{\link{carbon_grid}}
#'
#' @examples
#' carbon_column(width = 4, htmltools::p("A quarter of a large screen"))
#'
#' carbon_column(width = c(sm = 4, md = 4, lg = 8), htmltools::p("Responsive"))
#'
#' @export
carbon_column <- function(
  ...,
  width = NULL
) {
  width <- normalize_col_width(width)
  classes <- ""
  for (size in names(width)) {
    classes <-
      paste(classes, paste0("cds--", size, ":col-span-", width[[size]]))
  }
  .with_carbon_dependency(
    htmltools::tags$div(class = paste0("cds--css-grid-column", classes), ...)
  )
}
