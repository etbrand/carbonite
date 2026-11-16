.create_items <- function(inputId, tag_name, choices, selected) {
  choices <- .normalize_choices(choices)
  Map(
    function(text, value) {
      option_id <- .sub_id(inputId, value)
      attrs <- list(id = option_id, value = value)

      if (!is.null(selected) && value %in% selected) {
        attrs$selected <- NA
      }

      htmltools::tag(paste0(tag_name, "-item"), c(attrs, text))
    },
    names(choices),
    unname(choices)
  )
}

#' Carbon Dropdown Input
#'
#' Create a dropdown input using the Carbon Design System.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label An optional label for the input.
#' @param choices A vector of choices to display. If the vector is named,
#'   the names are displayed to the user while the values are returned to
#'   the server.
#' @param selected The value selected by default. If `NULL`, no value is
#'   initially selected.
#' @param size The size of the input. One of `"md"`, `"xs"`, `"sm"`, or
#'   `"lg"`. Defaults to `"md"`.
#' @param placeholder Optional placeholder text displayed when no value is
#'   selected.
#' @param helper_text Optional helper text displayed with the input.
#' @param ... Additional attributes passed to the underlying Carbon dropdown
#'   element.
#'
#' @return A Carbon dropdown input suitable for use in a Shiny UI.
#'
#' @export
#'
#' @examples
#' carbon_dropdown(
#'   "animal",
#'   label = "Choose an animal",
#'   choices = c(
#'     "Cat" = "cat",
#'     "Dog" = "dog",
#'     "Bird" = "bird"
#'   ),
#'   placeholder = "Select an animal"
#' )
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
  size <- match.arg(size)
  items <- .create_items(inputId, "cds-dropdown", choices, selected)

  .build_carbon_tag(
    "cds-dropdown",
    c(
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
  )
}

#' Carbon Combo Box Input
#'
#' Create a combo box input using the Carbon Design System.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label An optional label for the input.
#' @param choices A vector of choices to display. If the vector is named,
#'   the names are displayed to the user while the values are returned to
#'   the server.
#' @param selected The value selected by default. If `NULL`, no value is
#'   initially selected.
#' @param size The size of the input. One of `"md"`, `"xs"`, `"sm"`, or
#'   `"lg"`. Defaults to `"md"`.
#' @param placeholder Optional placeholder text displayed when no value is
#'   selected.
#' @param helper_text Optional helper text displayed with the input.
#' @param ... Additional attributes passed to the underlying Carbon combo
#'   box element.
#'
#' @return A Carbon combo box input suitable for use in a Shiny UI.
#'
#' @export
#'
#' @examples
#' carbon_combobox(
#'   "animal",
#'   label = "Choose an animal",
#'   choices = c(
#'     "Cat" = "cat",
#'     "Dog" = "dog",
#'     "Bird" = "bird"
#'   ),
#'   placeholder = "Select an animal"
#' )
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
  size <- match.arg(size)
  items <- .create_items(inputId, "cds-combo-box", choices, selected)

  .build_carbon_tag(
    "cds-combo-box",
    c(
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
  )
}

#' Carbon Multiselect Input
#'
#' Create a multiselect input using the Carbon Design System.
#'
#' @param inputId The input slot that will be used to access the selected
#'   values.
#' @param label An optional label for the input.
#' @param choices A vector of choices to display. If the vector is named,
#'   the names are displayed to the user while the values are returned to
#'   the server. Choice values cannot contain commas.
#' @param selected One or more values selected by default. If `NULL`, no
#'   values are initially selected.
#' @param size The size of the input. One of `"md"`, `"xs"`, `"sm"`, or
#'   `"lg"`. Defaults to `"md"`.
#' @param placeholder Optional placeholder text displayed when no values are
#'   selected.
#' @param helper_text Optional helper text displayed with the input.
#' @param sort_choices Logical indicating whether choices should be sorted
#'   alphabetically. Defaults to `FALSE`, preserving the order in which
#'   `choices` are supplied.
#' @param ... Additional attributes passed to the underlying Carbon
#'   multiselect element.
#'
#' @return A Carbon multiselect input suitable for use in a Shiny UI.
#'
#' @export
#'
#' @examples
#' carbon_multiselect(
#'   "animals",
#'   label = "Choose animals",
#'   choices = c(
#'     "Cat" = "cat",
#'     "Dog" = "dog",
#'     "Bird" = "bird"
#'   ),
#'   selected = c("cat", "dog"),
#'   placeholder = "Select animals"
#' )
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
  if (any(grepl(",", choices, fixed = TRUE))) {
    stop("`choices` values cannot contain commas.", call. = FALSE)
  }

  size <- match.arg(size)
  items <- .create_items(inputId, "cds-multi-select", choices, selected)

  .build_carbon_tag(
    "cds-multi-select",
    c(
      list(
        id = inputId,
        `title-text` = label,
        label = placeholder,
        value = if (!is.null(selected)) paste(selected, collapse = ","),
        size = size,
        `helper-text` = helper_text,
        `data-sort` = tolower(as.character(sort_choices)),
        items
      ),
      list(...)
    )
  )
}

#' Update a Carbon Dropdown Input
#'
#' Update the properties, choices, or selected value of an existing Carbon
#' dropdown input.
#'
#' @param inputId The input slot of the dropdown to update.
#' @param label An optional new label for the input. If `NULL`, the existing
#'   label is unchanged.
#' @param selected The value to select. If `NULL`, the existing selection is
#'   unchanged.
#' @param choices An optional vector of new choices. If the vector is named,
#'   the names are displayed to the user while the values are returned to
#'   the server. If `NULL`, the existing choices are unchanged.
#' @param placeholder Optional new placeholder text. If `NULL`, the existing
#'   placeholder is unchanged.
#' @param helper_text Optional new helper text. If `NULL`, the existing helper
#'   text is unchanged.
#' @param ... Additional attributes to update on the underlying Carbon
#'   dropdown element.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' update_carbon_dropdown(
#'   "animal",
#'   choices = c(
#'     "Cat" = "cat",
#'     "Dog" = "dog",
#'     "Bird" = "bird"
#'   ),
#'   selected = "cat",
#'   placeholder = "Select an animal"
#' )
#' }
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
    msg$choices <- .normalize_choices(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  if (!is.null(placeholder)) {
    msg$label <- placeholder
  }

  session$sendInputMessage(session$ns(inputId), msg)
}

#' Update a Carbon Combo Box Input
#'
#' Update the properties, choices, or selected value of an existing Carbon
#' combo box input.
#'
#' @param inputId The input slot of the combo box to update.
#' @param label An optional new label for the input. If `NULL`, the existing
#'   label is unchanged.
#' @param selected The value to select. If `NULL`, the existing selection is
#'   unchanged.
#' @param choices An optional vector of new choices. If the vector is named,
#'   the names are displayed to the user while the values are returned to
#'   the server. If `NULL`, the existing choices are unchanged.
#' @param placeholder Optional new placeholder text. If `NULL`, the existing
#'   placeholder is unchanged.
#' @param helper_text Optional new helper text. If `NULL`, the existing helper
#'   text is unchanged.
#' @param ... Additional attributes to update on the underlying Carbon combo
#'   box element.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' update_carbon_combobox(
#'   "animal",
#'   choices = c(
#'     "Cat" = "cat",
#'     "Dog" = "dog",
#'     "Bird" = "bird"
#'   ),
#'   selected = "cat",
#'   placeholder = "Select an animal"
#' )
#' }
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
    msg$choices <- .normalize_choices(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  if (!is.null(placeholder)) {
    msg$label <- placeholder
  }

  session$sendInputMessage(session$ns(inputId), msg)
}

#' Update a Carbon Multiselect Input
#'
#' Update the properties, choices, or selected values of an existing Carbon
#' multiselect input.
#'
#' @param inputId The input slot of the multiselect to update.
#' @param label An optional new label for the input. If `NULL`, the existing
#'   label is unchanged.
#' @param selected One or more values to select. If `NULL`, the existing
#'   selection is unchanged.
#' @param choices An optional vector of new choices. If the vector is named,
#'   the names are displayed to the user while the values are returned to
#'   the server. Choice values cannot contain commas. If `NULL`, the existing
#'   choices are unchanged.
#' @param placeholder Optional new placeholder text. If `NULL`, the existing
#'   placeholder is unchanged.
#' @param helper_text Optional new helper text. If `NULL`, the existing helper
#'   text is unchanged.
#' @param ... Additional attributes to update on the underlying Carbon
#'   multiselect element.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' update_carbon_multiselect(
#'   "animals",
#'   choices = c(
#'     "Cat" = "cat",
#'     "Dog" = "dog",
#'     "Bird" = "bird"
#'   ),
#'   selected = c("cat", "dog"),
#'   placeholder = "Select animals"
#' )
#' }
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
    msg$choices <- .normalize_choices(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  if (!is.null(placeholder)) {
    msg$label <- placeholder
  }

  session$sendInputMessage(session$ns(inputId), msg)
}
