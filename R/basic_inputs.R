#' Carbon Design System Button
#'
#' Create a Carbon Design System button using the Carbon Web Components
#' implementation.
#'
#' This input behaves similarly to Shiny's \code{actionButton()} and generates
#' an event each time the button is clicked.
#'
#' @param inputId The input slot that will be used to access the button click
#'   event.
#' @param label The button label.
#' @param icon Optional icon shown in the button: the name of any Carbon
#'   icon (see \code{carbon_icon_names()}), e.g. \code{"add"}, or a
#'   \code{carbon_icon()}.
#' @param kind The Carbon button style. One of \code{"primary"},
#'   \code{"secondary"}, \code{"tertiary"}, \code{"ghost"},
#'   \code{"danger"}, \code{"danger-tertiary"}, or
#'   \code{"danger-ghost"}.
#' @param size The Carbon button size. One of \code{"xs"}, \code{"sm"},
#'   \code{"md"}, \code{"lg"}, \code{"xl"}, or \code{"2xl"}.
#' @param ... Additional attributes passed to the underlying Carbon
#'   button element.
#'
#' @return An HTML tag representing a Carbon button.
#'
#' @examples
#' carbon_button(
#'   inputId = "run",
#'   label = "Run Analysis"
#' )
#'
#' carbon_button(
#'   inputId = "save",
#'   label = "Save",
#'   kind = "secondary"
#' )
#'
#' carbon_button(
#'   inputId = "delete",
#'   label = "Delete",
#'   kind = "danger"
#' )
#'
#' carbon_button(
#'   inputId = "launch",
#'   label = "Launch",
#'   size = "lg"
#' )
#'
#' @export
carbon_button <- function(
  inputId,
  label,
  icon = NULL,
  kind = c(
    "primary",
    "secondary",
    "tertiary",
    "ghost",
    "danger",
    "danger-tertiary",
    "danger-ghost"
  ),
  size = c("md", "xs", "sm", "lg", "xl", "2xl"),
  ...
) {
  kind <- match.arg(kind)
  size <- match.arg(size)
  .build_carbon_tag(
    "cds-button",
    c(
      list(
        id = inputId,
        kind = kind,
        size = size,
        if (!is.null(icon)) .slot_icon(icon),
        label
      ),
      list(...)
    )
  )
}

#' Carbon Design System Select Input
#'
#' Create a Carbon Design System select input using the Carbon Web Components
#' implementation.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label Optional label displayed above the select input.
#' @param choices A named or unnamed vector of choices. Names are displayed to
#'   the user, while values are returned to the server.
#' @param selected The initially selected value. Must match one of the supplied
#'   choice values.
#' @param size Optional Carbon size. Possible values are `"xs"`, `"sm"`, `"md"`, and
#'   `"lg"`.
#' @param placeholder Optional placeholder text displayed when no value is
#'   selected.
#' @param helper_text Optional helper text displayed below input.
#' @param ... Additional attributes passed to the underlying Carbon
#'   select element.
#'
#' @return An HTML tag representing a Carbon select input.
#'
#' @examples
#' carbon_select(
#'   inputId = "species",
#'   label = "Species",
#'   choices = c(
#'     Dog = "dog",
#'     Cat = "cat",
#'     Bird = "bird"
#'   ),
#'   selected = "cat"
#' )
#'
#' carbon_select(
#'   inputId = "size",
#'   label = "Size",
#'   choices = c("Small", "Medium", "Large"),
#'   size = "sm"
#' )
#'
#' @export
carbon_select <- function(
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
  choices <- .normalize_choices(choices)

  items <- Map(
    function(text, value) {
      attrs <- list(value = value)

      if (!is.null(selected) && identical(value, selected)) {
        attrs$selected <- TRUE
      }

      htmltools::tag(
        "cds-select-item",
        c(attrs, list(text))
      )
    },
    names(choices),
    unname(choices)
  )
  .build_carbon_tag(
    "cds-select",
    c(
      list(
        id = inputId,
        value = selected,
        size = size,
        placeholder = placeholder,
        `helper-text` = helper_text,
        `label-text` = label,
        items
      ),
      list(...)
    )
  )
}

#' Carbon Design System Text Input
#'
#' Create a Carbon Design System text input using the Carbon Web Components
#' implementation.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label Optional label displayed above the text input.
#' @param value Optional initial value of the input.
#' @param size The Carbon input size. One of \code{"xs"}, \code{"sm"},
#'   \code{"md"}, or \code{"lg"}.
#' @param placeholder Optional placeholder text displayed when the input is
#'   empty.
#' @param helper_text Optional helper text displayed below the input control.
#' @param ... Additional attributes passed to the underlying Carbon
#'   text input element.
#'
#' @return An HTML tag representing a Carbon text input.
#'
#' @examples
#' carbon_text_input(
#'   inputId = "name",
#'   label = "Name"
#' )
#'
#' carbon_text_input(
#'   inputId = "email",
#'   label = "Email Address",
#'   placeholder = "name@example.com"
#' )
#'
#' carbon_text_input(
#'   inputId = "search",
#'   label = "Search",
#'   size = "sm",
#'   placeholder = "Enter search terms"
#' )
#'
#' carbon_text_input(
#'   inputId = "username",
#'   label = "Username",
#'   helper_text = "Usernames must be unique."
#' )
#'
#' @export
carbon_text_input <- function(
  inputId,
  label = NULL,
  value = NULL,
  size = c("md", "xs", "sm", "lg"),
  placeholder = NULL,
  helper_text = NULL,
  ...
) {
  size <- match.arg(size)
  .build_carbon_tag(
    "cds-text-input",
    c(
      list(
        id = inputId,
        label = label,
        value = value,
        size = size,
        placeholder = placeholder,
        `helper-text` = helper_text
      ),
      list(...)
    )
  )
}

#' Update a Carbon Text Input
#'
#' Update the properties or value of an existing Carbon text input.
#'
#' @param inputId The input slot of the text input to update.
#' @param value An optional new value for the input. If `NULL`, the existing
#'   value is unchanged.
#' @param placeholder Optional new placeholder text. If `NULL`, the existing
#'   placeholder is unchanged.
#' @param helper_text Optional new helper text. If `NULL`, the existing helper
#'   text is unchanged.
#' @param ... Additional attributes to update on the underlying Carbon text
#'   input element.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' update_carbon_text_input(
#'   "name",
#'   value = "Jane Doe",
#'   placeholder = "Enter your name"
#' )
#' }
update_carbon_text_input <- function(
  inputId,
  value = NULL,
  placeholder = NULL,
  helper_text = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(...)

  if (!is.null(value)) {
    msg$value <- value
  }

  if (!is.null(placeholder)) {
    msg$placeholder <- placeholder
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  session$sendInputMessage(inputId, msg)
}

#' Carbon Design System Checkbox Group
#'
#' Create a Carbon Design System checkbox group using the Carbon Web Components
#' implementation.
#'
#' This input behaves similarly to Shiny's \code{checkboxGroupInput()} and
#' returns a character vector containing the values of all selected checkboxes.
#'
#' @param inputId The input slot that will be used to access the selected
#'   values.
#' @param label Optional group label displayed above the checkboxes.
#' @param choices A named or unnamed vector of choices. Names are displayed to
#'   the user, while values are returned to the server.
#' @param selected A character vector of initially selected values. Values must
#'   match entries in \code{choices}.
#' @param helper_text Optional helper text displayed below the checkbox group.
#' @param ... Additional attributes passed to the underlying Carbon
#'   checkbox group element.
#'
#' @return An HTML tag representing a Carbon checkbox group.
#'
#' @examples
#' carbon_checkbox_group(
#'   inputId = "animals",
#'   label = "Favorite Animals",
#'   choices = c(
#'     Dog = "dog",
#'     Cat = "cat",
#'     Bird = "bird"
#'   )
#' )
#'
#' carbon_checkbox_group(
#'   inputId = "animals",
#'   label = "Favorite Animals",
#'   choices = c(
#'     Dog = "dog",
#'     Cat = "cat",
#'     Bird = "bird"
#'   ),
#'   selected = c("dog", "cat")
#' )
#'
#' carbon_checkbox_group(
#'   inputId = "interests",
#'   label = "Areas of Interest",
#'   choices = c(
#'     `Data Science` = "ds",
#'     `Machine Learning` = "ml",
#'     Visualization = "viz"
#'   ),
#'   helper_text = "Select all that apply."
#' )
#'
#' @export
carbon_checkbox_group <- function(
  inputId,
  label = NULL,
  choices,
  selected = NULL,
  helper_text = NULL,
  ...
) {
  choices <- .normalize_choices(choices)
  items <- Map(
    function(text, value) {
      checkbox_id <- .sub_id(inputId, value)
      attrs <- list(id = checkbox_id, `label-text` = text, value = value)

      if (value %in% selected) {
        attrs$checked <- NA
      }

      htmltools::tag("cds-checkbox", attrs)
    },
    names(choices),
    unname(choices)
  )

  .build_carbon_tag(
    "cds-checkbox-group",
    c(
      list(
        id = inputId,
        `legend-text` = label,
        `helper-text` = helper_text,
        items
      ),
      list(...)
    )
  )
}

#' Carbon Design System Number Input
#'
#' Create a Carbon Design System number input using the Carbon Web Components
#' implementation.
#'
#' This input behaves similarly to Shiny's \code{numericInput()} and returns a
#' numeric value to the server.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label Optional label displayed above the input.
#' @param value The initial value of the input.
#' @param min The minimum allowed value.
#' @param max The maximum allowed value.
#' @param step The increment between valid values.
#' @param size The Carbon input size. One of \code{"sm"},
#'   \code{"md"}, or \code{"lg"}.
#' @param placeholder Optional placeholder text displayed when the input is
#'   empty.
#' @param helper_text Optional helper text displayed below the input control.
#' @param ... Additional attributes passed to the underlying Carbon
#'   number input element.
#'
#' @return An HTML tag representing a Carbon number input.
#'
#' @examples
#' carbon_number_input(
#'   inputId = "n",
#'   label = "Number of Observations",
#'   value = 100
#' )
#'
#' carbon_number_input(
#'   inputId = "age",
#'   label = "Age",
#'   value = 30,
#'   min = 0,
#'   max = 120
#' )
#'
#' carbon_number_input(
#'   inputId = "probability",
#'   label = "Probability",
#'   value = 0.5,
#'   min = 0,
#'   max = 1,
#'   step = 0.01
#' )
#'
#' carbon_number_input(
#'   inputId = "learning_rate",
#'   label = "Learning Rate",
#'   value = 0.001,
#'   step = 0.001,
#'   helper_text = "Smaller values generally result in slower but more stable training."
#' )
#'
#' carbon_number_input(
#'   inputId = "quantity",
#'   label = "Quantity",
#'   value = 10,
#'   size = "sm"
#' )
#'
#' @export
carbon_number_input <- function(
  inputId,
  label = NULL,
  value = NULL,
  min = -100,
  max = 100,
  step = 1,
  size = c("md", "sm", "lg"),
  placeholder = NULL,
  helper_text = NULL,
  ...
) {
  size <- match.arg(size)
  .build_carbon_tag(
    "cds-number-input",
    c(
      list(
        id = inputId,
        label = label,
        value = value,
        min = min,
        max = max,
        step = step,
        size = size,
        placeholder = placeholder,
        `helper-text` = helper_text
      ),
      list(...)
    )
  )
}

#' Carbon Design System Radio Button Group
#'
#' Create a Carbon Design System radio button group using the Carbon Web
#' Components implementation.
#'
#' This input behaves similarly to Shiny's \code{radioButtons()} and returns
#' the value of the currently selected option.
#'
#' @param inputId The input slot that will be used to access the selected
#'   value.
#' @param label Optional group label displayed above the radio button group.
#' @param choices A named or unnamed vector of choices. Names are displayed to
#'   the user, while values are returned to the server.
#' @param selected The initially selected value. Must match one of the supplied
#'   choice values.
#' @param helper_text Optional helper text displayed below the radio button
#'   group.
#' @param ... Additional attributes passed to the underlying Carbon
#'   radio group element.
#'
#' @return An HTML tag representing a Carbon radio button group.
#'
#' @examples
#' carbon_radio_group(
#'   inputId = "species",
#'   label = "Species",
#'   choices = c(
#'     Dog = "dog",
#'     Cat = "cat",
#'     Bird = "bird"
#'   )
#' )
#'
#' carbon_radio_group(
#'   inputId = "species",
#'   label = "Species",
#'   choices = c(
#'     Dog = "dog",
#'     Cat = "cat",
#'     Bird = "bird"
#'   ),
#'   selected = "cat"
#' )
#'
#' carbon_radio_group(
#'   inputId = "model",
#'   label = "Model Type",
#'   choices = c(
#'     Linear = "linear",
#'     Tree = "tree",
#'     "Neural Network" = "nn"
#'   ),
#'   selected = "tree",
#'   helper_text = "Select exactly one model type."
#' )
#'
#' @export
carbon_radio_group <- function(
  inputId,
  label = NULL,
  choices,
  selected = NULL,
  helper_text = NULL,
  ...
) {
  choices <- .normalize_choices(choices)
  items <- Map(
    function(text, value) {
      radio_id <- .sub_id(inputId, value)

      attrs <- list(
        id = radio_id,
        name = inputId,
        `label-text` = text,
        value = value
      )

      if (identical(value, selected)) {
        attrs$checked <- NA
      }

      htmltools::tag("cds-radio-button", attrs)
    },
    names(choices),
    unname(choices)
  )

  .build_carbon_tag(
    "cds-radio-button-group",
    c(
      list(
        id = inputId,
        `legend-text` = label,
        `helper-text` = helper_text,
        items
      ),
      list(...)
    )
  )
}

#' Update a Carbon Select Input
#'
#' Update the properties, choices, or selected value of an existing Carbon
#' select input.
#'
#' @param inputId The input slot of the select input to update.
#' @param label An optional new label for the input. If `NULL`, the existing
#'   label is unchanged.
#' @param selected The value to select. If `NULL`, the existing selection is
#'   unchanged.
#' @param choices An optional vector of new choices. If the vector is named,
#'   the names are displayed to the user while the values are returned to
#'   the server. If `NULL`, the existing choices are unchanged.
#' @param helper_text Optional new helper text. If `NULL`, the existing helper
#'   text is unchanged.
#' @param ... Additional attributes to update on the underlying Carbon select
#'   element.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' update_carbon_select(
#'   "animal",
#'   choices = c(
#'     "Cat" = "cat",
#'     "Dog" = "dog",
#'     "Bird" = "bird"
#'   ),
#'   selected = "cat"
#' )
#' }
update_carbon_select <- function(
  inputId,
  label = NULL,
  selected = NULL,
  choices = NULL,
  helper_text = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(...)

  if (!is.null(label)) {
    msg$labelText <- label
  }

  if (!is.null(selected)) {
    msg$value <- selected
  }

  if (!is.null(choices)) {
    msg$choices <- .choices_message(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  session$sendInputMessage(inputId, msg)
}

#' Update a Carbon Radio Button Group
#'
#' Update the properties, choices, or selected value of an existing Carbon
#' radio button group.
#'
#' @param inputId The input slot of the radio button group to update.
#' @param label An optional new label for the input. If `NULL`, the existing
#'   label is unchanged.
#' @param choices An optional vector of new choices. If the vector is named,
#'   the names are displayed to the user while the values are returned to
#'   the server. If `NULL`, the existing choices are unchanged.
#' @param selected The value to select. If `NULL`, the existing selection is
#'   unchanged.
#' @param helper_text Optional new helper text. If `NULL`, the existing helper
#'   text is unchanged.
#' @param ... Additional attributes to update on the underlying Carbon radio
#'   button group element.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' update_carbon_radio_group(
#'   "animal",
#'   choices = c(
#'     "Cat" = "cat",
#'     "Dog" = "dog",
#'     "Bird" = "bird"
#'   ),
#'   selected = "cat"
#' )
#' }
update_carbon_radio_group <- function(
  inputId,
  label = NULL,
  choices = NULL,
  selected = NULL,
  helper_text = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(...)

  if (!is.null(label)) {
    msg$legendText <- label
  }

  if (!is.null(selected)) {
    msg$value <- selected
  }

  if (!is.null(choices)) {
    msg$choices <- .choices_message(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  session$sendInputMessage(inputId, msg)
}

#' Update a Carbon Checkbox Group
#'
#' Update the properties, choices, or selected values of an existing Carbon
#' checkbox group.
#'
#' @param inputId The input slot of the checkbox group to update.
#' @param label An optional new label for the input. If `NULL`, the existing
#'   label is unchanged.
#' @param choices An optional vector of new choices. If the vector is named,
#'   the names are displayed to the user while the values are returned to
#'   the server. If `NULL`, the existing choices are unchanged.
#' @param selected One or more values to select. If `NULL`, the existing
#'   selection is unchanged.
#' @param helper_text Optional new helper text. If `NULL`, the existing helper
#'   text is unchanged.
#' @param ... Additional attributes to update on the underlying Carbon
#'   checkbox group element.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' update_carbon_checkbox_group(
#'   "animals",
#'   choices = c(
#'     "Cat" = "cat",
#'     "Dog" = "dog",
#'     "Bird" = "bird"
#'   ),
#'   selected = c("cat", "dog")
#' )
#' }
update_carbon_checkbox_group <- function(
  inputId,
  label = NULL,
  choices = NULL,
  selected = NULL,
  helper_text = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(...)

  if (!is.null(label)) {
    msg$legendText <- label
  }

  if (!is.null(selected)) {
    msg$value <- selected
  }

  if (!is.null(choices)) {
    msg$choices <- .choices_message(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  session$sendInputMessage(inputId, msg)
}

#' Update a Carbon Button
#'
#' Update the properties or label of an existing Carbon button.
#'
#' @param inputId The input slot of the button to update.
#' @param label An optional new label for the button. If `NULL`, the existing
#'   label is unchanged.
#' @param kind An optional new button kind. If `NULL`, the existing kind is
#'   unchanged.
#' @param size An optional new button size. If `NULL`, the existing size is
#'   unchanged.
#' @param icon An optional new icon: an icon name or a `carbon_icon()`.
#'   `FALSE` removes the icon. If `NULL`, the existing icon is unchanged.
#' @param ... Additional attributes to update on the underlying Carbon button
#'   element.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' update_carbon_button(
#'   "submit",
#'   label = "Submitted",
#'   kind = "secondary",
#'   size = "sm"
#' )
#' }
update_carbon_button <- function(
  inputId,
  label = NULL,
  kind = NULL,
  size = NULL,
  icon = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(...)

  if (!is.null(label)) {
    msg$label <- label
  }

  if (!is.null(kind)) {
    msg$kind <- kind
  }

  if (!is.null(size)) {
    msg$size <- size
  }

  # Sent as SVG markup (rendered here, like the initial icon) or "" to remove
  if (isFALSE(icon)) {
    msg$icon <- ""
  } else if (!is.null(icon)) {
    msg$icon <- as.character(.slot_icon(icon))
  }

  session$sendInputMessage(inputId, msg)
}

#' Update a Carbon Number Input
#'
#' Update the properties or value of an existing Carbon number input.
#'
#' @param inputId The input slot of the number input to update.
#' @param value An optional new value for the input. If `NULL`, the existing
#'   value is unchanged.
#' @param label An optional new label for the input. If `NULL`, the existing
#'   label is unchanged.
#' @param min An optional new minimum allowed value. If `NULL`, the existing
#'   minimum is unchanged.
#' @param max An optional new maximum allowed value. If `NULL`, the existing
#'   maximum is unchanged.
#' @param step An optional new amount by which the value is incremented or
#'   decremented. If `NULL`, the existing step is unchanged.
#' @param size An optional new input size. If `NULL`, the existing size is
#'   unchanged.
#' @param placeholder Optional new placeholder text. If `NULL`, the existing
#'   placeholder is unchanged.
#' @param helper_text Optional new helper text. If `NULL`, the existing helper
#'   text is unchanged.
#' @param ... Additional attributes to update on the underlying Carbon number
#'   input element.
#' @param session The Shiny session object. Defaults to the current reactive
#'   domain.
#'
#' @return Invisibly returns `NULL`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' update_carbon_number_input(
#'   "quantity",
#'   value = 10,
#'   min = 0,
#'   max = 100,
#'   step = 5
#' )
#' }
update_carbon_number_input <- function(
  inputId,
  value = NULL,
  label = NULL,
  min = NULL,
  max = NULL,
  step = NULL,
  size = NULL,
  placeholder = NULL,
  helper_text = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(...)

  if (!is.null(value)) {
    msg$value <- value
  }

  if (!is.null(label)) {
    msg$label <- label
  }

  if (!is.null(min)) {
    msg$min <- min
  }

  if (!is.null(max)) {
    msg$max <- max
  }

  if (!is.null(step)) {
    msg$step <- step
  }

  if (!is.null(size)) {
    msg$size <- size
  }

  if (!is.null(placeholder)) {
    msg$placeholder <- placeholder
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  session$sendInputMessage(inputId, msg)
}
