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

  htmltools::tag(
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
    htmltools::tag(
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
