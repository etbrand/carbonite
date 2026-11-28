# The header logo: decorative (the title names the link), so hidden from
# screen readers.
.header_logo <- function(logo, call = rlang::caller_env()) {
  if (rlang::is_string(logo)) {
    .check_icon_name(logo, arg = "logo", call = call)
    logo <- carbon_icon(logo, size = 20)
  } else if (!inherits(logo, c("shiny.tag", "shiny.tag.list", "html"))) {
    cli::cli_abort(
      "{.arg logo} must be an icon name, like {.val earth--filled}, or a tag, such as {.fn carbon_icon} or {.fn htmltools::img}.",
      call = call
    )
  }

  htmltools::tags$span(class = "carbonite-header-logo", `aria-hidden` = "true", logo)
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
#' @param content Optional UI shown on the right of the header, e.g. a
#'   \code{carbon_select()} with \code{size = "sm"} and no label, or
#'   buttons. The header is 3rem (48px) tall.
#' @param logo Optional logo shown before the title: the name of a Carbon
#'   icon (see \code{carbon_icon_names()}), or a tag such as
#'   \code{carbon_icon()}, an inline SVG, or \code{htmltools::img()}. Images
#'   are scaled to the header, at most 2rem (32px) tall. On small screens
#'   (under 42rem, 672px) the header shows only the logo, with the title kept
#'   for screen readers, so a long title doesn't crowd the header.
#'
#' @return An \code{htmltools::tagList} containing a Carbon header.
#'
#' @examples
#' carbon_header("Sales Dashboard")
#'
#' carbon_header(
#'   "Sales Dashboard",
#'   content = carbon_select("year", choices = 2024:2026, size = "sm")
#' )
#'
#' carbon_header("World Data Dashboard", logo = "earth--filled")
#'
#' @export
carbon_header <- function(
  title = "Application",
  menu_button = TRUE,
  content = NULL,
  logo = NULL
) {
  htmltools::tagList(
    cds_header(
      if (menu_button) htmltools::tag("cds-header-menu-button", list()),
      # The logo and title are separate elements inside the one name link, so
      # carbonite.scss can lay them out (Carbon puts its slot in an inline
      # span, which can't be styled from outside) and drop the title text on
      # small screens.
      cds_header_name(
        class = if (!is.null(logo)) "carbonite-header-name--logo",
        if (!is.null(logo)) .header_logo(logo),
        htmltools::tags$span(class = "carbonite-header-title", title),
        href = "#"
      ),
      # Carbon's global-actions area, pushed to the right (carbonite.scss)
      if (!is.null(content)) {
        htmltools::div(class = "cds--header__global carbonite-header-content", content)
      }
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
#' @param header_content Optional UI shown on the right of the header, e.g.
#'   a control that applies to every panel. See \code{carbon_header()}.
#' @param window_title The page's title in the browser tab, bookmarks and
#'   history, as in \code{shiny::fluidPage()}. Defaults to \code{title}; give
#'   it when \code{title} isn't plain text, or to differ from the header.
#'   \code{NULL} for no title.
#' @param logo Optional logo shown in the header before \code{title}: a
#'   Carbon icon name or a tag. See \code{carbon_header()}.
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
  default_route = NULL,
  header_content = NULL,
  window_title = title,
  logo = NULL
) {
  if (!is.null(window_title) && !rlang::is_string(window_title)) {
    cli::cli_abort(c(
      "{.arg window_title} must be a single string or {.code NULL}.",
      "i" = "It defaults to {.arg title}; when that isn't plain text, give {.arg window_title} as well."
    ))
  }

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
    # Without a viewport tag, phones lay the page out at desktop width
    # (~980px) and shrink it to fit, so Carbon's breakpoints never apply.
    # Shiny moves this into the document's <head>.
    htmltools::tags$head(
      htmltools::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      # The browser tab's title, as shiny::fluidPage(title = ) sets it
      if (!is.null(window_title)) htmltools::tags$title(window_title)
    ),
    carbon_dependency(),
    carbon_page_dependency(),
    htmltools::tags$div(
      id = "carbon-app",
      class = "carbon-app",
      class = if (is.null(sidebar)) "carbon-app--no-sidebar",
      class = if (.is_rail(sidebar)) "carbon-app--rail",
      `data-default-route` = default_route,
      # The menu button only toggles the side navigation
      carbon_header(title, menu_button = !is.null(sidebar), content = header_content, logo = logo),
      sidebar,
      htmltools::tags$main(
        id = "carbon-main",
        class = "carbon-main",
        content
      )
    )
  )
}

.is_rail <- function(sidebar) {
  inherits(sidebar, "shiny.tag") &&
    identical(htmltools::tagGetAttribute(sidebar, "collapse-mode"), "rail")
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
#' @param icon Optional icon shown before the label: an icon name (see
#'   \code{carbon_icon_names()}) or a \code{carbon_icon()}. In a
#'   \code{carbon_sidebar(rail = TRUE)} the icon stays visible while the
#'   side navigation is collapsed, so give every link one.
#'
#' @return An HTML tag representing a Carbon side navigation link.
#'
#' @examples
#' carbon_nav_item("reports", "Reports")
#'
#' carbon_nav_item("reports", "Reports", icon = "report")
#'
#' @export
carbon_nav_item <- function(
  route,
  label,
  icon = NULL
) {
  .build_carbon_tag(
    "cds-side-nav-link",
    list(
      href = paste0("#", route),
      `data-route` = route,
      `data-carbon-nav` = "",
      if (!is.null(icon)) .slot_icon(icon, slot = "title-icon"),
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
#' @param rail If \code{TRUE}, collapse the side navigation to a narrow rail
#'   showing only the links' icons; it expands over the page on hover or
#'   keyboard focus. Give every \code{carbon_nav_item()} an \code{icon}.
#'
#' @return An HTML tag representing a Carbon side navigation.
#'
#' @examples
#' carbon_sidebar(
#'   carbon_nav_item("home", "Home"),
#'   carbon_nav_item("about", "About")
#' )
#'
#' carbon_sidebar(
#'   carbon_nav_item("home", "Home", icon = "home"),
#'   carbon_nav_item("settings", "Settings", icon = "settings"),
#'   rail = TRUE
#' )
#'
#' @export
carbon_sidebar <- function(..., rail = FALSE) {
  if (!rlang::is_bool(rail)) {
    cli::cli_abort("{.arg rail} must be {.code TRUE} or {.code FALSE}.")
  }

  .build_carbon_tag(
    "cds-side-nav",
    list(
      id = "carbon-sidebar",
      `collapse-mode` = if (rail) "rail",
      ...
    )
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
