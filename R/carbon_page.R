cds_header <- function(...) {
  htmltools::tag("cds-header", list(...))
}

cds_header_name <- function(..., href = "#") {
  htmltools::tag(
    "cds-header-name",
    list(href = href, ...)
  )
}

carbon_header <- function(
  title = "Application"
) {
  htmltools::tagList(
    cds_header(
      cds_header_name(
        title,
        href = "#"
      )
    )
  )
}

carbon_page <- function(
  ...,
  title = "Application",
  default_route = "overview"
) {
  page <- htmltools::tagList(
    carbon_dependency(),
    carbon_page_dependency(),
    tags$div(
      id = "carbon-app",
      class = "carbon-app",
      `data-default-route` = default_route,
      carbon_header(title),
      tags$main(
        id = "carbon-main",
        class = "carbon-main",
        ...
      )
    )
  )
  page
}

carbon_nav_item <- function(
  route,
  label
) {
  tags$button(
    label,
    `data-carbon-nav` = "",
    `data-route` = route,
    class = "carbon-nav-item"
  )
}

carbon_nav <- function(...) {
  tags$nav(
    class = "carbon-nav",
    ...
  )
}

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
