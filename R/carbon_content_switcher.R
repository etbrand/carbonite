#' Carbon Content Switch
#'
#' Define one option of a \code{carbon_content_switcher()}. This does not
#' render anything on its own.
#'
#' @param value The value the switcher's input takes when this option is
#'   selected. Must be unique within the switcher.
#' @param label The option's text. For an icon option, its tooltip and
#'   accessible name.
#' @param ... Optional UI shown below the switcher while this option is
#'   selected.
#' @param icon Optional icon name (see \code{carbon_icon_names()}) or
#'   \code{carbon_icon()}, shown instead of the label. Carbon's icon-only
#'   switcher needs every option to have an icon.
#' @param disabled If \code{TRUE}, the option can't be selected.
#'
#' @return A \code{carbon_switch} object to pass to
#'   \code{carbon_content_switcher()}.
#'
#' @seealso \code{\link{carbon_content_switcher}}
#'
#' @examples
#' carbon_switch("table", "Table", htmltools::p("Table view"))
#'
#' carbon_switch("grid", "Grid view", icon = "grid")
#'
#' @export
carbon_switch <- function(value, label = value, ..., icon = NULL, disabled = FALSE) {
  if (!rlang::is_string(value) || !nzchar(value)) {
    cli::cli_abort("{.arg value} must be a single non-empty string.")
  }
  if (!rlang::is_bool(disabled)) {
    cli::cli_abort("{.arg disabled} must be {.code TRUE} or {.code FALSE}.")
  }

  structure(
    list(
      value = value,
      label = label,
      content = rlang::list2(...),
      icon = icon,
      disabled = disabled
    ),
    class = "carbon_switch"
  )
}

#' Carbon Content Switcher
#'
#' Create a Carbon content switcher: a row of options for switching between
#' alternative views of the same content, such as a chart and a table.
#' \code{input$<inputId>} is the selected option's \code{value}.
#'
#' Options can carry their own UI (the \code{...} of \code{carbon_switch()}),
#' shown below the switcher while the option is selected, as with
#' \code{carbon_tabs()}. Or leave them empty and react to
#' \code{input$<inputId>} on the server instead.
#'
#' @param inputId The input slot that will be used to access the selected
#'   value. Panel ids are derived from it.
#' @param ... Two or more \code{carbon_switch()}es.
#' @param selected The \code{value} of the option selected initially.
#'   Defaults to the first enabled option.
#' @param size The switcher height. One of \code{"md"}, \code{"sm"}, or
#'   \code{"lg"}.
#' @param low_contrast If \code{TRUE}, use Carbon's low-contrast style.
#'
#' @return The switcher tag or, when options have content, an
#'   \code{htmltools::tagList} of the switcher and its panels.
#'
#' @seealso \code{\link{carbon_switch}},
#'   \code{\link{update_carbon_content_switcher}}, \code{\link{carbon_tabs}}
#'
#' @examples
#' carbon_content_switcher(
#'   "view",
#'   carbon_switch("chart", "Chart", htmltools::p("A chart")),
#'   carbon_switch("table", "Table", htmltools::p("A table")),
#'   selected = "table"
#' )
#'
#' # Icon only, without panels: react to input$layout on the server
#' carbon_content_switcher(
#'   "layout",
#'   carbon_switch("list", "List view", icon = "list"),
#'   carbon_switch("grid", "Grid view", icon = "grid"),
#'   size = "sm"
#' )
#'
#' @export
carbon_content_switcher <- function(
  inputId,
  ...,
  selected = NULL,
  size = c("md", "sm", "lg"),
  low_contrast = FALSE
) {
  size <- match.arg(size)
  switches <- Filter(Negate(is.null), rlang::list2(...))

  if (!rlang::is_bool(low_contrast)) {
    cli::cli_abort("{.arg low_contrast} must be {.code TRUE} or {.code FALSE}.")
  }
  if (!all(vapply(switches, inherits, logical(1), "carbon_switch"))) {
    cli::cli_abort("Every option must be created with {.fn carbon_switch}.")
  }
  if (length(switches) < 2) {
    cli::cli_abort("A content switcher needs at least two {.fn carbon_switch}es.")
  }

  values <- vapply(switches, `[[`, character(1), "value")
  if (anyDuplicated(values)) {
    cli::cli_abort("Option values must be unique; duplicated: {.val {unique(values[duplicated(values)])}}.")
  }

  has_icon <- vapply(switches, function(s) !is.null(s$icon), logical(1))
  if (any(has_icon) && !all(has_icon)) {
    cli::cli_abort("Give every {.fn carbon_switch} an {.arg icon}, or none: Carbon's icon-only switcher needs all of them.")
  }

  enabled <- !vapply(switches, `[[`, logical(1), "disabled")
  if (!any(enabled)) {
    cli::cli_abort("At least one option must be enabled.")
  }
  if (is.null(selected)) {
    selected <- values[enabled][[1]]
  } else if (!rlang::is_string(selected) || !selected %in% values) {
    cli::cli_abort("{.arg selected} must be one of the options' values: {.val {values}}.")
  } else if (!enabled[match(selected, values)]) {
    cli::cli_abort("{.arg selected} can't be a disabled option.")
  }

  has_panels <- any(vapply(switches, function(s) length(s$content) > 0, logical(1)))
  panel_ids <- paste0(inputId, "-panel-", seq_along(switches))

  items <- lapply(seq_along(switches), function(i) {
    s <- switches[[i]]
    is_selected <- s$value == selected

    htmltools::tag(
      "cds-content-switcher-item",
      c(
        list(
          value = s$value,
          target = if (has_panels) panel_ids[[i]],
          selected = if (is_selected) NA,
          disabled = if (s$disabled) NA,
          icon = if (has_icon[[i]]) NA
        ),
        if (has_icon[[i]]) {
          list(
            .slot_icon(s$icon, slot = NULL, size = 16),
            htmltools::tags$span(slot = "tooltip-content", s$label)
          )
        } else {
          # In an element, so carbonite.scss can grey out disabled options:
          # Carbon only styles a disabled label slotted as a <p>.
          list(htmltools::tags$span(class = "carbonite-switch-label", s$label))
        }
      )
    )
  })

  switcher <- .build_carbon_tag(
    "cds-content-switcher",
    list(
      id = inputId,
      value = selected,
      # Carbon selects by position among the enabled options when it first
      # renders, overriding `value`
      `selected-index` = match(selected, values[enabled]) - 1,
      size = if (size != "md") size,
      `low-contrast` = if (low_contrast) NA,
      items
    )
  )

  if (!has_panels) {
    return(switcher)
  }

  # Carbon shows the selected option's panel by toggling `hidden` on its
  # target; start the others hidden so they don't flash before it loads.
  panels <- lapply(seq_along(switches), function(i) {
    htmltools::tags$div(
      id = panel_ids[[i]],
      class = "carbonite-switcher-panel",
      role = "tabpanel",
      hidden = if (switches[[i]]$value != selected) NA,
      switches[[i]]$content
    )
  })

  htmltools::tagList(switcher, panels)
}

#' Update a Carbon Content Switcher
#'
#' Select an option of a \code{carbon_content_switcher()} from the server.
#' Its input, and the panel shown, update to match.
#'
#' @param inputId The switcher's input id.
#' @param selected The \code{value} of the option to select. Unknown and
#'   disabled options are ignored.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_content_switcher}}
#'
#' @examples
#' \dontrun{
#' update_carbon_content_switcher("view", selected = "table")
#' }
#'
#' @export
update_carbon_content_switcher <- function(
  inputId,
  selected,
  session = shiny::getDefaultReactiveDomain()
) {
  if (!rlang::is_string(selected)) {
    cli::cli_abort("{.arg selected} must be a single string.")
  }

  session$sendInputMessage(inputId, list(value = selected))

  invisible(NULL)
}
