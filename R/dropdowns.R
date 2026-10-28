.create_items <- function(inputId, tag_name, choices, selected) {
  Map(
    function(text, value) {
      option_id <- sub_id(inputId, value)
      attrs <- list(id = option_id, value = value)

      if (!is.null(selected) && identical(value, selected)) {
        attrs$selected <- TRUE
      }

      htmltools::tag(
        paste0(tag_name, "-item"),
        c(attrs, list(text))
      )
    },
    names(choices),
    unname(choices)
  )
}

# .carbon_dropdown_input <- function(
#   tag_name,
#   inputId,
#   label = NULL,
#   choices,
#   selected = NULL,
#   size = c("md", "xs", "sm", "lg"),
#   placeholder = NULL,
#   helper_text = NULL,
#   ...
# ) {
#   size <- match.arg(size)

#   items <- Map(
#     function(text, value) {
#       option_id <- sub_id(inputId, value)
#       attrs <- list(id = option_id, value = value)

#       if (!is.null(selected) && identical(value, selected)) {
#         attrs$selected <- TRUE
#       }

#       htmltools::tag(
#         paste0(tag_name, "-item"),
#         c(attrs, list(text))
#       )
#     },
#     names(choices),
#     unname(choices)
#   )

#   attrs <- modifyList(
#     list(
#       id = inputId,
#       `title-text` = label,
#       label = placeholder,
#       size = size,
#       `helper-text` = helper_text,
#       items
#     ),
#     list(...)
#   )

#   htmltools::tag(
#     tag_name,
#     c(attrs, items)
#   )
# }

#' @export
carbon_dropdown <- function(
  inputId,
  label = NULL,
  choices,
  selected = NULL,
  size = c("md", "xs", "sm", "lg"),
  placeholder = NULL,
  helper_text = NULL,
  ...
) {
  # .carbon_dropdown_input(
  #   tag_name = "cds-dropdown",
  #   inputId = inputId,
  #   label = label,
  #   choices = choices,
  #   selected = selected,
  #   size = size,
  #   placeholder = placeholder,
  #   helper_text = helper_text,
  #   ...
  # )
  size <- match.arg(size)
  items <- .create_items(inputId, "cds-dropdown", choices, selected)

  attrs <- modifyList(
    list(
      id = inputId,
      `title-text` = label,
      label = placeholder,
      size = size,
      `helper-text` = helper_text,
      items
    ),
    list(...)
  )

  htmltools::tag("cds-dropdown", c(attrs, items))
}

#' @export
carbon_combobox <- function(
  inputId,
  label = NULL,
  choices,
  selected = NULL,
  size = c("md", "xs", "sm", "lg"),
  placeholder = NULL,
  helper_text = NULL,
  ...
) {
  # .carbon_dropdown_input(
  #   tag_name = "cds-combo-box",
  #   inputId = inputId,
  #   label = label,
  #   choices = choices,
  #   selected = selected,
  #   size = size,
  #   placeholder = placeholder,
  #   helper_text = helper_text,
  #   ...
  # )
  size <- match.arg(size)
  items <- .create_items(inputId, "cds-combo-box", choices, selected)

  attrs <- modifyList(
    list(
      id = inputId,
      `title-text` = label,
      label = placeholder,
      size = size,
      `helper-text` = helper_text,
      items
    ),
    list(...)
  )

  htmltools::tag("cds-combo-box", c(attrs, items))
}

#' @export
carbon_multiselect <- function(
  inputId,
  label = NULL,
  choices,
  selected = NULL,
  size = c("md", "xs", "sm", "lg"),
  placeholder = NULL,
  helper_text = NULL,
  sort_choices = FALSE,
  ...
) {
  # .carbon_dropdown_input(
  #   tag_name = "cds-multi-select",
  #   inputId = inputId,
  #   label = label,
  #   choices = choices,
  #   selected = selected,
  #   size = size,
  #   placeholder = placeholder,
  #   helper_text = helper_text,
  #   ...
  # )

  if (any(grepl(",", choices, fixed = TRUE))) {
    stop("`choices` values cannot contain commas.", call. = FALSE)
  }

  size <- match.arg(size)
  items <- .create_items(inputId, "cds-multi-select", choices, selected)

  attrs <- modifyList(
    list(
      id = inputId,
      `title-text` = label,
      label = placeholder,
      size = size,
      `helper-text` = helper_text,
      `data-sort` = tolower(as.character(sort_choices)),
      items
    ),
    list(...)
  )

  htmltools::tag("cds-multi-select", c(attrs, items))
}

#' @export
update_carbon_dropdown <- function(
  inputId,
  label = NULL,
  selected = NULL,
  choices = NULL,
  placeholder = NULL,
  helper_text = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(...)

  if (!is.null(label)) {
    msg$titleText <- label
  }

  if (!is.null(selected)) {
    if (length(selected) > 1) {
      stop("`selected` must be a single value.")
    }
    msg$value <- selected
  }

  if (!is.null(choices)) {
    msg$choices <- normalize_choices(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  if (!is.null(placeholder)) {
    msg$label <- placeholder
  }

  session$sendInputMessage(session$ns(inputId), msg)
}

#' @export
update_carbon_combobox <- function(
  inputId,
  label = NULL,
  selected = NULL,
  choices = NULL,
  placeholder = NULL,
  helper_text = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(...)

  if (!is.null(label)) {
    msg$titleText <- label
  }

  if (!is.null(selected)) {
    if (length(selected) > 1) {
      stop("`selected` must be a single value.")
    }
    msg$value <- selected
  }

  if (!is.null(choices)) {
    msg$choices <- normalize_choices(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  if (!is.null(placeholder)) {
    msg$label <- placeholder
  }

  session$sendInputMessage(session$ns(inputId), msg)
}

#' @export
update_carbon_multiselect <- function(
  inputId,
  label = NULL,
  selected = NULL,
  choices = NULL,
  placeholder = NULL,
  helper_text = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  if (any(grepl(",", choices, fixed = TRUE))) {
    stop("`choices` values cannot contain commas.", call. = FALSE)
  }

  msg <- list(...)

  if (!is.null(label)) {
    msg$titleText <- label
  }

  if (!is.null(selected)) {
    if (length(selected) > 1) {
      selected <- paste(selected, collapse = ",")
    }
    msg$value <- selected
  }

  if (!is.null(choices)) {
    msg$choices <- normalize_choices(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  if (!is.null(placeholder)) {
    msg$label <- placeholder
  }

  session$sendInputMessage(session$ns(inputId), msg)
}
