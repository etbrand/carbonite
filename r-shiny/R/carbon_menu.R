#' Carbon Menu Items
#'
#' Build the items of a \code{carbon_menu_button()} or
#' \code{carbon_overflow_menu()}: \code{carbon_menu_item()} is an action,
#' \code{carbon_menu_divider()} a line between groups of items, and
#' \code{carbon_submenu()} an item that opens a nested menu.
#'
#' @param value The value the menu's input takes when the item is chosen.
#'   Must be unique within the menu.
#' @param label The item text. Defaults to \code{value}.
#' @param icon Optional icon shown before the label: an icon name (see
#'   \code{carbon_icon_names()}) or a \code{carbon_icon()}.
#' @param shortcut Optional keyboard shortcut text shown at the end of the
#'   item, e.g. \code{"Ctrl+C"}. Only a hint: it doesn't set up the shortcut.
#' @param disabled If \code{TRUE}, the item can't be chosen.
#' @param danger If \code{TRUE}, style the item as a destructive action
#'   (red on hover), e.g. "Delete".
#' @param ... For \code{carbon_submenu()}: the submenu's items.
#'
#' @return An HTML tag, to pass to a menu.
#'
#' @seealso \code{\link{carbon_menu_button}},
#'   \code{\link{carbon_overflow_menu}}
#'
#' @examples
#' carbon_menu_item("copy", "Copy", icon = "copy", shortcut = "Ctrl+C")
#'
#' carbon_menu_item("delete", "Delete", icon = "trash-can", danger = TRUE)
#'
#' carbon_submenu(
#'   "Export as",
#'   carbon_menu_item("csv", "CSV"),
#'   carbon_menu_item("xlsx", "Excel")
#' )
#'
#' @name carbon_menu_item
#' @export
carbon_menu_item <- function(
  value,
  label = value,
  icon = NULL,
  shortcut = NULL,
  disabled = FALSE,
  danger = FALSE
) {
  if (!rlang::is_string(value) || !nzchar(value)) {
    cli::cli_abort("{.arg value} must be a single non-empty string.")
  }
  if (!rlang::is_bool(disabled)) {
    cli::cli_abort("{.arg disabled} must be {.code TRUE} or {.code FALSE}.")
  }
  if (!rlang::is_bool(danger)) {
    cli::cli_abort("{.arg danger} must be {.code TRUE} or {.code FALSE}.")
  }

  .build_carbon_tag(
    "cds-menu-item",
    list(
      label = label,
      `data-value` = value,
      shortcut = shortcut,
      kind = if (danger) "danger",
      disabled = if (disabled) NA,
      if (!is.null(icon)) .slot_icon(icon, slot = "render-icon")
    )
  )
}

#' @rdname carbon_menu_item
#' @export
carbon_menu_divider <- function() {
  .build_carbon_tag("cds-menu-item-divider", list())
}

#' @rdname carbon_menu_item
#' @export
carbon_submenu <- function(label, ..., icon = NULL) {
  items <- .check_menu_items(rlang::list2(...))

  .build_carbon_tag(
    "cds-menu-item",
    list(
      label = label,
      if (!is.null(icon)) .slot_icon(icon, slot = "render-icon"),
      # cds-menu-item draws the submenu's cds-menu itself, around this slot
      htmltools::tag("cds-menu-item-group", c(list(slot = "submenu", label = label), items))
    )
  )
}

# Flatten tagLists and plain lists of items, dropping NULLs.
.flatten_items <- function(x) {
  if (is.null(x)) {
    return(list())
  }
  if (is.list(x) && !inherits(x, "shiny.tag")) {
    return(unlist(lapply(x, .flatten_items), recursive = FALSE))
  }
  list(x)
}

.check_menu_items <- function(items, call = rlang::caller_env()) {
  items <- .flatten_items(items)

  is_item <- vapply(items, function(x) {
    inherits(x, "shiny.tag") && x$name %in% c("cds-menu-item", "cds-menu-item-divider")
  }, logical(1))

  if (!all(is_item)) {
    cli::cli_abort(
      "Menu items must be {.fn carbon_menu_item}s, {.fn carbon_menu_divider}s, or {.fn carbon_submenu}s.",
      call = call
    )
  }

  items
}

# Every item value in a menu, submenus included.
.menu_values <- function(items) {
  unlist(lapply(items, function(item) {
    nested <- htmltools::tagQuery(item)$find("cds-menu-item")$selectedTags()
    c(
      htmltools::tagGetAttribute(item, "data-value"),
      unlist(lapply(nested, htmltools::tagGetAttribute, "data-value"))
    )
  }))
}

.menu_tag <- function(items, label, call = rlang::caller_env()) {
  items <- .check_menu_items(items, call = call)

  if (!length(items)) {
    cli::cli_abort("A menu needs at least one item.", call = call)
  }

  values <- .menu_values(items)
  if (anyDuplicated(values)) {
    dups <- unique(values[duplicated(values)])
    cli::cli_abort("Menu item values must be unique; duplicated: {.val {dups}}.", call = call)
  }

  htmltools::tag("cds-menu", c(list(label = label), items))
}

#' Carbon Menu Button
#'
#' Create a button that opens a menu of actions. Choosing an item sets
#' \code{input$<inputId>} to the item's \code{value}.
#'
#' The input works like an action button: it is \code{NULL} until an item is
#' chosen, and \code{shiny::observeEvent(input$<inputId>, ...)} runs every
#' time an item is chosen, even the same one again.
#'
#' @param inputId The input slot that will be used to access the chosen
#'   item.
#' @param label The button text.
#' @param ... The menu's items: \code{carbon_menu_item()}s,
#'   \code{carbon_menu_divider()}s, and \code{carbon_submenu()}s.
#' @param kind The button style. One of \code{"primary"}, \code{"tertiary"},
#'   or \code{"ghost"}.
#' @param size The button and menu size. One of \code{"lg"}, \code{"md"},
#'   \code{"sm"}, or \code{"xs"}.
#' @param menu_alignment Where the menu opens, relative to the button. One
#'   of \code{"bottom"}, \code{"bottom-start"}, \code{"bottom-end"},
#'   \code{"top"}, \code{"top-start"}, or \code{"top-end"}.
#' @param disabled If \code{TRUE}, the button can't be used.
#'
#' @return An HTML tag representing a Carbon menu button.
#'
#' @seealso \code{\link{carbon_menu_item}},
#'   \code{\link{carbon_overflow_menu}}, \code{\link{update_carbon_menu}}
#'
#' @examples
#' carbon_menu_button(
#'   "actions",
#'   "Actions",
#'   carbon_menu_item("edit", "Edit", icon = "edit"),
#'   carbon_menu_item("duplicate", "Duplicate", icon = "copy"),
#'   carbon_menu_divider(),
#'   carbon_menu_item("delete", "Delete", icon = "trash-can", danger = TRUE)
#' )
#'
#' if (interactive()) {
#'   ui <- carbon_page(
#'     carbon_menu_button(
#'       "actions", "Actions",
#'       carbon_menu_item("edit", "Edit"),
#'       carbon_menu_item("delete", "Delete", danger = TRUE)
#'     ),
#'     shiny::verbatimTextOutput("chosen")
#'   )
#'
#'   server <- function(input, output, session) {
#'     output$chosen <- shiny::renderPrint(input$actions)
#'     shiny::observeEvent(input$actions, {
#'       message("Chose ", input$actions)
#'     })
#'   }
#'
#'   shiny::shinyApp(ui, server)
#' }
#'
#' @export
carbon_menu_button <- function(
  inputId,
  label,
  ...,
  kind = c("primary", "tertiary", "ghost"),
  size = c("lg", "md", "sm", "xs"),
  menu_alignment = c("bottom", "bottom-start", "bottom-end", "top", "top-start", "top-end"),
  disabled = FALSE
) {
  kind <- match.arg(kind)
  size <- match.arg(size)
  menu_alignment <- match.arg(menu_alignment)

  if (!rlang::is_bool(disabled)) {
    cli::cli_abort("{.arg disabled} must be {.code TRUE} or {.code FALSE}.")
  }

  .build_carbon_tag(
    "cds-menu-button",
    list(
      id = inputId,
      # Marks it for the input binding (srcjs/bindings/carbon-menu.js)
      class = "carbonite-menu",
      label = label,
      kind = kind,
      size = size,
      `menu-alignment` = menu_alignment,
      disabled = if (disabled) NA,
      .menu_tag(rlang::list2(...), label = label)
    )
  )
}

#' Carbon Overflow Menu
#'
#' Create an icon button (by default \eqn{\vdots}) that opens a menu of
#' actions, for places with little room, such as a table toolbar or a tile.
#' Choosing an item sets \code{input$<inputId>} to the item's \code{value};
#' see \code{carbon_menu_button()} for how the input behaves.
#'
#' @inheritParams carbon_menu_button
#' @param label The button's accessible name, also shown as its tooltip.
#' @param icon The button's icon: an icon name (see
#'   \code{carbon_icon_names()}) or a \code{carbon_icon()}.
#' @param size The button and menu size. One of \code{"md"}, \code{"lg"},
#'   \code{"sm"}, or \code{"xs"}.
#' @param menu_alignment Where the menu opens, relative to the button. One
#'   of \code{"bottom-start"}, \code{"bottom"}, \code{"bottom-end"},
#'   \code{"top-start"}, \code{"top"}, or \code{"top-end"}.
#'
#' @return An HTML tag representing a Carbon overflow menu.
#'
#' @seealso \code{\link{carbon_menu_item}},
#'   \code{\link{carbon_menu_button}}, \code{\link{update_carbon_menu}}
#'
#' @examples
#' carbon_overflow_menu(
#'   "row_actions",
#'   carbon_menu_item("rename", "Rename"),
#'   carbon_menu_item("archive", "Archive"),
#'   carbon_menu_divider(),
#'   carbon_menu_item("delete", "Delete", danger = TRUE)
#' )
#'
#' @export
carbon_overflow_menu <- function(
  inputId,
  ...,
  label = "Options",
  icon = "overflow-menu--vertical",
  size = c("md", "lg", "sm", "xs"),
  menu_alignment = c("bottom-start", "bottom", "bottom-end", "top-start", "top", "top-end"),
  disabled = FALSE
) {
  size <- match.arg(size)
  menu_alignment <- match.arg(menu_alignment)

  if (!rlang::is_bool(disabled)) {
    cli::cli_abort("{.arg disabled} must be {.code TRUE} or {.code FALSE}.")
  }

  .build_carbon_tag(
    "cds-overflow-menu",
    list(
      id = inputId,
      class = "carbonite-menu",
      label = label,
      size = size,
      `menu-alignment` = menu_alignment,
      disabled = if (disabled) NA,
      # Carbon's newer overflow menu, which takes a cds-menu like
      # cds-menu-button does
      `enable-v12-overflowmenu` = NA,
      .slot_icon(icon, slot = "icon"),
      .menu_tag(rlang::list2(...), label = label)
    )
  )
}

#' Update a Carbon Menu
#'
#' Change the label of a \code{carbon_menu_button()} (or the tooltip of a
#' \code{carbon_overflow_menu()}), or enable or disable it.
#'
#' @param inputId The menu's input id.
#' @param label Optional new label. If \code{NULL}, the label is unchanged.
#' @param disabled Optional \code{TRUE} or \code{FALSE}. If \code{NULL}, it
#'   is unchanged.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns \code{NULL}.
#'
#' @seealso \code{\link{carbon_menu_button}},
#'   \code{\link{carbon_overflow_menu}}
#'
#' @examples
#' \dontrun{
#' update_carbon_menu("actions", disabled = TRUE)
#' update_carbon_menu("actions", label = "More actions", disabled = FALSE)
#' }
#'
#' @export
update_carbon_menu <- function(
  inputId,
  label = NULL,
  disabled = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list()

  if (!is.null(label)) {
    msg$label <- label
  }

  if (!is.null(disabled)) {
    if (!rlang::is_bool(disabled)) {
      cli::cli_abort("{.arg disabled} must be {.code TRUE}, {.code FALSE}, or {.code NULL}.")
    }
    msg$disabled <- disabled
  }

  session$sendInputMessage(inputId, msg)

  invisible(NULL)
}
