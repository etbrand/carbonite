#' Carbon Design System Tag
#'
#' Create a Carbon tag: a small coloured label for categorising or
#' highlighting content, optionally with a dismiss button.
#'
#' @param label The tag text.
#' @param type The tag colour. One of \code{"red"}, \code{"magenta"},
#'   \code{"purple"}, \code{"blue"}, \code{"cyan"}, \code{"teal"},
#'   \code{"green"}, \code{"gray"}, \code{"cool-gray"}, or
#'   \code{"warm-gray"}.
#' @param size The tag size. One of \code{"sm"} or \code{"md"}.
#' @param filter Not yet implemented; currently has no effect.
#' @param id Optional element id.
#' @param dismissible If \code{TRUE}, render a \code{cds-dismissible-tag}
#'   with a close button instead of a plain \code{cds-tag}.
#'
#' @return An HTML tag representing a Carbon tag.
#'
#' @examples
#' carbon_tag("Beta")
#'
#' carbon_tag("Deprecated", type = "red", size = "md")
#'
#' carbon_tag("Filter: active", type = "blue", dismissible = TRUE)
#'
#' @export
carbon_tag <- function(
  label,
  type = c(
    "red",
    "magenta",
    "purple",
    "blue",
    "cyan",
    "teal",
    "green",
    "gray",
    "cool-gray",
    "warm-gray"
  ),
  size = c("sm", "md"),
  filter = FALSE,
  id = NULL,
  dismissible = FALSE
) {
  type <- match.arg(type)
  size <- match.arg(size)

  .build_carbon_tag(
    if (dismissible) "cds-dismissible-tag" else "cds-tag",
    c(
      list(
        id = id,
        type = type,
        size = size
      ),
      if (dismissible) list(text = label) else label
    )
  )
}

cds_header <- function(...) {
  .build_carbon_tag("cds-header", list(...))
}

cds_header_name <- function(..., href = "#") {
  htmltools::tag(
    "cds-header-name",
    list(href = href, ...)
  )
}

#' Carbon Design System Header
#'
#' Create the Carbon UI shell header bar with a menu button and the
#' application name. \code{carbon_page()} adds this automatically, so you
#' only need it when building a custom layout.
#'
#' @param title The application name shown in the header.
#' @param menu_button Whether to show the menu button that opens the side
#'   navigation on small screens. \code{carbon_page()} shows it only when
#'   there is a \code{sidebar}.
#'
#' @return An \code{htmltools::tagList} containing a Carbon header.
#'
#' @examples
#' carbon_header("Sales Dashboard")
#'
#' @export
carbon_header <- function(
  title = "Application",
  menu_button = TRUE
) {
  htmltools::tagList(
    cds_header(
      if (menu_button) htmltools::tag("cds-header-menu-button", list()),
      cds_header_name(
        title,
        href = "#"
      )
    )
  )
}

#' Carbon Design System Page
#'
#' Create a full-page Carbon application layout: a header, an optional side
#' navigation, and a main area that shows one \code{carbon_panel()} at a time.
#'
#' Navigation is hash-based: each \code{carbon_nav_item()} links to
#' \code{#<route>}, and the panel whose \code{id} matches the route is shown.
#' The current route is available on the server as \code{input$carbon_page}
#' (\code{NULL} when the page has no panels).
#'
#' Panels are optional. Content that isn't a \code{carbon_panel()} is always
#' shown, so \code{carbon_page()} with no content gives an empty page, and a
#' single-screen app can pass its UI directly.
#'
#' @param ... Page content: \code{carbon_panel()}s, one per route, each with
#'   a unique \code{id}, and/or any other UI, which is always shown.
#' @param title The application name shown in the header.
#' @param theme The Carbon theme. One of \code{"white"}, \code{"g10"},
#'   \code{"g90"}, or \code{"g100"}.
#' @param sidebar Optional side navigation, created with
#'   \code{carbon_sidebar()}.
#' @param default_route The \code{id} of the panel to show when the URL has no
#'   route. Defaults to the first panel, if any.
#'
#' @return An HTML page suitable as a Shiny UI.
#'
#' @seealso \code{\link{carbon_panel}}, \code{\link{carbon_sidebar}},
#'   \code{\link{carbon_nav_item}}
#'
#' @examples
#' ui <- carbon_page(
#'   title = "My App",
#'   theme = "g10",
#'   sidebar = carbon_sidebar(
#'     carbon_nav_item("home", "Home"),
#'     carbon_nav_item("settings", "Settings")
#'   ),
#'   carbon_panel("home", htmltools::h2("Home")),
#'   carbon_panel("settings", htmltools::h2("Settings"))
#' )
#'
#' if (interactive()) {
#'   server <- function(input, output, session) {
#'     shiny::observe(print(input$carbon_page))
#'   }
#'   shiny::shinyApp(ui, server)
#' }
#'
#' @export
carbon_page <- function(
  ...,
  title = "Application",
  theme = "white",
  sidebar = NULL,
  default_route = NULL
) {
  content <- rlang::list2(...)
  panel_ids <- .panel_ids(content)

  if (anyDuplicated(panel_ids)) {
    dups <- unique(panel_ids[duplicated(panel_ids)])
    cli::cli_abort("Each {.fn carbon_panel} needs a unique {.arg id}; duplicated: {.val {dups}}.")
  }

  if (is.null(default_route)) {
    default_route <- if (length(panel_ids)) panel_ids[[1]]
  } else if (!default_route %in% panel_ids) {
    cli::cli_abort(c(
      "{.arg default_route} must be the {.arg id} of a {.fn carbon_panel}.",
      "x" = "{.val {default_route}} isn't one.",
      "i" = if (length(panel_ids)) "Panels: {.val {panel_ids}}." else "There are no panels."
    ))
  }

  if (!is.null(default_route)) {
    content <- .activate_panel(content, default_route)
  }

  htmltools::tags$html(
    `data-carbon-theme` = theme,
    carbon_dependency(),
    carbon_page_dependency(),
    htmltools::tags$div(
      id = "carbon-app",
      class = "carbon-app",
      class = if (is.null(sidebar)) "carbon-app--no-sidebar",
      `data-default-route` = default_route,
      # The menu button only toggles the side navigation
      carbon_header(title, menu_button = !is.null(sidebar)),
      sidebar,
      htmltools::tags$main(
        id = "carbon-main",
        class = "carbon-main",
        content
      )
    )
  )
}

.is_panel <- function(x) {
  if (!inherits(x, "shiny.tag")) {
    return(FALSE)
  }
  classes <- htmltools::tagGetAttribute(x, "class")
  !is.null(classes) && "carbon-panel" %in% strsplit(classes, "\\s+")[[1]]
}

# Ids of the carbon_panel()s in page content, looking inside tagLists and
# plain lists (but not inside other tags: panels are top-level routes).
.panel_ids <- function(x) {
  if (.is_panel(x)) {
    return(htmltools::tagGetAttribute(x, "id"))
  }
  if (is.list(x) && !inherits(x, "shiny.tag")) {
    return(unlist(lapply(x, .panel_ids), use.names = FALSE))
  }
  NULL
}

.activate_panel <- function(x, route) {
  if (.is_panel(x)) {
    if (identical(htmltools::tagGetAttribute(x, "id"), route)) {
      x <- htmltools::tagAppendAttributes(x, class = "active")
    }
    return(x)
  }
  if (is.list(x) && !inherits(x, "shiny.tag")) {
    x[] <- lapply(x, .activate_panel, route = route)
  }
  x
}

#' Carbon Side Navigation Link
#'
#' Create a link in a \code{carbon_sidebar()} that navigates to a
#' \code{carbon_panel()} within a \code{carbon_page()}.
#'
#' @param route The \code{id} of the \code{carbon_panel()} to show.
#' @param label The link text.
#'
#' @return An HTML tag representing a Carbon side navigation link.
#'
#' @examples
#' carbon_nav_item("reports", "Reports")
#'
#' @export
carbon_nav_item <- function(
  route,
  label
) {
  .build_carbon_tag(
    "cds-side-nav-link",
    list(
      href = paste0("#", route),
      `data-route` = route,
      `data-carbon-nav` = "",
      label
    )
  )
}

#' Carbon Page Panel
#'
#' Create a content panel for \code{carbon_page()}. Only the panel matching
#' the current route is visible.
#'
#' @param id The panel's route. Link to it with
#'   \code{carbon_nav_item(route = id)}.
#' @param ... UI elements to show in the panel.
#'
#' @return A \code{div} tag.
#'
#' @examples
#' carbon_panel(
#'   "overview",
#'   htmltools::h2("Overview"),
#'   htmltools::p("Welcome!")
#' )
#'
#' @export
carbon_panel <- function(
  id,
  ...
) {
  htmltools::tags$div(
    id = id,
    class = "carbon-panel",
    ...
  )
}

#' Carbon Side Navigation
#'
#' Create the side navigation for \code{carbon_page()}.
#'
#' @param ... \code{carbon_nav_item()} links, plus any additional attributes
#'   for the underlying \code{cds-side-nav} element.
#'
#' @return An HTML tag representing a Carbon side navigation.
#'
#' @examples
#' carbon_sidebar(
#'   carbon_nav_item("home", "Home"),
#'   carbon_nav_item("about", "About")
#' )
#'
#' @export
carbon_sidebar <- function(...) {
  .build_carbon_tag(
    "cds-side-nav",
    list(id = "carbon-sidebar", ...)
  )
}

#' Carbon Tab
#'
#' Define one tab for \code{carbon_tabs()}. This does not render anything on
#' its own.
#'
#' @param value A unique value identifying the tab.
#' @param label The text shown on the tab.
#' @param ... UI elements shown when the tab is selected.
#' @param disabled If \code{TRUE}, the tab cannot be selected.
#'
#' @return A \code{carbon_tab} object to pass to \code{carbon_tabs()}.
#'
#' @examples
#' carbon_tab("summary", "Summary", htmltools::p("Summary content"))
#'
#' @export
carbon_tab <- function(value, label, ..., disabled = FALSE) {
  structure(
    list(
      value = value,
      label = label,
      content = rlang::list2(...),
      disabled = disabled
    ),
    class = "carbon_tab"
  )
}

#' Carbon Tabs
#'
#' Create a Carbon tab set, with one panel per \code{carbon_tab()}. Selecting
#' a tab shows its panel.
#'
#' There is no Shiny input binding for tabs yet, so the selected tab is not
#' available on the server.
#'
#' @param input_id The id of the \code{cds-tabs} element. Tab and panel ids
#'   are derived from it.
#' @param ... One or more \code{carbon_tab()} objects.
#' @param selected The \code{value} of the initially selected tab. Defaults
#'   to the first enabled tab.
#'
#' @return An \code{htmltools::tagList} containing the tab bar and the tab
#'   panels.
#'
#' @examples
#' carbon_tabs(
#'   "main_tabs",
#'   carbon_tab("overview", "Overview", htmltools::p("Overview content")),
#'   carbon_tab("data", "Data", htmltools::p("Data content")),
#'   carbon_tab("admin", "Admin", disabled = TRUE),
#'   selected = "data"
#' )
#'
#' @export
carbon_tabs <- function(input_id, ..., selected = NULL) {
  tabs <- rlang::list2(...)

  if (!length(tabs)) {
    stop("`carbon_tabs()` requires at least one `carbon_tab()`.", call. = FALSE)
  }

  if (!all(vapply(tabs, inherits, logical(1), "carbon_tab"))) {
    stop(
      "All elements passed through `...` must be created with `carbon_tab()`.",
      call. = FALSE
    )
  }

  values <- vapply(tabs, `[[`, character(1), "value")

  if (anyDuplicated(values)) {
    stop("Tab values must be unique.", call. = FALSE)
  }

  # Default to the first enabled tab
  if (is.null(selected)) {
    enabled <- !vapply(tabs, `[[`, logical(1), "disabled")

    if (!any(enabled)) {
      stop("At least one tab must be enabled.", call. = FALSE)
    }

    selected <- values[which(enabled)[1]]
  }

  if (!selected %in% values) {
    stop("`selected` must match a tab value.", call. = FALSE)
  }

  selected_index <- match(selected, values)

  tab_list <- lapply(seq_along(tabs), function(i) {
    tab <- tabs[[i]]

    tab_id <- paste0(input_id, "-tab-", i)
    panel_id <- paste0(input_id, "-panel-", i)

    htmltools::tag(
      "cds-tab",
      list(
        id = tab_id,
        value = tab$value,
        target = panel_id,
        disabled = if (tab$disabled) "" else NULL,
        selected = if (i == selected_index) "" else NULL,
        tab$label
      )
    )
  })

  tab_panels <- lapply(seq_along(tabs), function(i) {
    tab <- tabs[[i]]

    panel_id <- paste0(input_id, "-panel-", i)

    htmltools::tag(
      "cds-tab-panel",
      list(
        id = panel_id,
        value = tab$value,
        tab$content
      )
    )
  })

  htmltools::tagList(
    .build_carbon_tag(
      "cds-tabs",
      list(
        id = input_id,
        value = selected,
        tab_list
      )
    ),
    tab_panels
  )
}
