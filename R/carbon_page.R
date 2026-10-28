cds_header <- function(...) {
  htmltools::tag("cds-header", list(...))
}

cds_header_name <- function(..., href = "#") {
  htmltools::tag(
    "cds-header-name",
    list(href = href, ...)
  )
}

#' @export
carbon_header <- function(
  title = "Application"
) {
  htmltools::tagList(
    cds_header(
      htmltools::tag("cds-header-menu-button", list()),
      cds_header_name(
        title,
        href = "#"
      )
    )
  )
}

#' @export
carbon_page <- function(
  ...,
  title = "Application",
  theme = "white",
  sidebar = NULL,
  default_route = NULL
) {
  page <- #htmltools::tagList(
    tags$html(
      `data-carbon-theme` = theme,
      carbon_dependency(),
      carbon_page_dependency(),
      tags$div(
        id = "carbon-app",
        class = "carbon-app",
        carbon_header(title),
        sidebar,
        tags$main(
          id = "carbon-main",
          class = "carbon-main",
          ...
        )
      )
    )
  panels <- page$children[[3]]$children[[3]]$children

  if (is.null(default_route)) {
    default_route <- panels[[1]]$attribs$id
  }
  page$children[[3]] <- htmltools::tagAppendAttributes(
    page$children[[3]],
    `data-default-route` = default_route
  )
  panels <- lapply(panels, function(panel) {
    if (panel$attribs$id == default_route) {
      panel <- htmltools::tagAppendAttributes(
        panel,
        class = "active"
      )
    }
    panel
  })
  page$children[[3]]$children[[3]]$children <- panels

  page
}

#' @export
carbon_nav_item <- function(
  route,
  label
) {
  htmltools::tag(
    "cds-side-nav-link",
    list(
      href = paste0("#", route),
      `data-route` = route,
      `data-carbon-nav` = "",
      label
    )
  )
}

#' @export
carbon_panel <- function(
  id,
  ...
) {
  tags$div(
    id = id,
    class = "carbon-panel",
    ...
  )
}

#' @export
carbon_sidebar <- function(...) {
  htmltools::tag(
    "cds-side-nav",
    list(id = "carbon-sidebar", ...)
  )
}
