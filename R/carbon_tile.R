# Split `...` into unnamed children and named attributes.
.split_dots <- function(...) {
  dots <- list(...)
  dot_names <- names(dots)

  if (is.null(dot_names)) {
    return(list(children = dots, attribs = list()))
  }

  named <- nzchar(dot_names)
  list(children = unname(dots[!named]), attribs = dots[named])
}

#' Carbon Tile
#'
#' Create a Carbon tile: a container that groups related content on a
#' layer-coloured background. With \code{href}, the whole tile becomes a link
#' (Carbon's clickable tile).
#'
#' @param ... Tile content. Named arguments become attributes of the tile,
#'   e.g. \code{class}, \code{style}, or, with \code{href},
#'   \code{target = "_blank"}.
#' @param href Optional URL. If supplied, the tile is rendered as a
#'   \code{cds-clickable-tile} that navigates to it.
#' @param id Optional element id.
#'
#' @return An HTML tag representing a Carbon tile.
#'
#' @seealso \code{\link{carbon_expandable_tile}}
#'
#' @examples
#' carbon_tile(
#'   htmltools::h4("Revenue"),
#'   htmltools::p("$1.2M this quarter")
#' )
#'
#' carbon_tile(
#'   "Read the documentation",
#'   href = "https://www.carbondesignsystem.com/",
#'   target = "_blank"
#' )
#'
#' @export
carbon_tile <- function(..., href = NULL, id = NULL) {
  if (!is.null(href) && (!is.character(href) || length(href) != 1)) {
    cli::cli_abort("{.arg href} must be a single string or {.code NULL}.")
  }

  .build_carbon_tag(
    if (is.null(href)) "cds-tile" else "cds-clickable-tile",
    c(list(id = id, href = href), list(...))
  )
}

#' Carbon Expandable Tile
#'
#' Create a Carbon expandable tile: a tile that always shows a summary and
#' reveals more content when the user expands it.
#'
#' @param summary Content that is always visible (Carbon's "above the fold"
#'   content). A string or any UI element.
#' @param ... Content revealed when the tile is expanded. Named arguments
#'   become attributes of the tile, e.g. \code{class} or \code{style}.
#' @param expanded Whether the tile starts expanded.
#' @param interactive Set to \code{TRUE} when the tile contains inputs, links,
#'   or buttons. Only the chevron button then expands and collapses the tile,
#'   so clicking those elements doesn't toggle it.
#' @param id Optional element id.
#'
#' @return An HTML tag representing a Carbon expandable tile.
#'
#' @seealso \code{\link{carbon_tile}}
#'
#' @examples
#' carbon_expandable_tile(
#'   htmltools::h4("Model summary"),
#'   htmltools::p("Trained on 12,000 rows; validation accuracy 0.94.")
#' )
#'
#' @export
carbon_expandable_tile <- function(
  summary,
  ...,
  expanded = FALSE,
  interactive = FALSE,
  id = NULL
) {
  if (!rlang::is_bool(expanded)) {
    cli::cli_abort("{.arg expanded} must be {.code TRUE} or {.code FALSE}.")
  }
  if (!rlang::is_bool(interactive)) {
    cli::cli_abort("{.arg interactive} must be {.code TRUE} or {.code FALSE}.")
  }

  dots <- .split_dots(...)

  .build_carbon_tag(
    "cds-expandable-tile",
    c(
      list(
        id = id,
        expanded = if (expanded) NA,
        `with-interactive` = if (interactive) NA
      ),
      dots$attribs,
      list(
        htmltools::tag(
          "cds-tile-above-the-fold-content",
          list(slot = "above-the-fold-content", summary)
        ),
        htmltools::tag("cds-tile-below-the-fold-content", dots$children)
      )
    )
  )
}
