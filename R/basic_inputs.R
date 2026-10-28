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
#' @param kind The Carbon button style. One of \code{"primary"},
#'   \code{"secondary"}, \code{"tertiary"}, \code{"ghost"},
#'   \code{"danger"}, \code{"danger-tertiary"}, or
#'   \code{"danger-ghost"}.
#' @param size The Carbon button size. One of \code{"xs"}, \code{"sm"},
#'   \code{"md"}, \code{"lg"}, \code{"xl"}, or \code{"2xl"}.
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
  htmltools::tag(
    "cds-button",
    c(list(id = inputId, kind = kind, size = size, label), list(...))
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
  helper_text = NULL
) {
  size <- match.arg(size)

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
  htmltools::tag(
    "cds-select",
    list(
      id = inputId,
      size = size,
      placeholder = placeholder,
      `helper-text` = helper_text,
      `label-text` = label,
      items
    )
  )
}

# #' @export
# update_carbon_select <- function(
#   inputId,
#   selected = NULL,
#   choices = NULL,
#   label = NULL,
#   helper_text = NULL,
#   session = shiny::getDefaultReactiveDomain()
# ) {
#   session$sendCustomMessage(
#     "carbon-update-select",
#     list(
#       id = session$ns(inputId),
#       label = label,
#       choices = normalize_choices(choices),
#       selected = selected,
#       helper_text = helper_text
#     )
#   )
# }

#' Carbon Design System Text Input
#'
#' Create a Carbon Design System text input using the Carbon Web Components
#' implementation.
#'
#' @param inputId The input slot that will be used to access the value.
#' @param label Optional label displayed above the text input.
#' @param size The Carbon input size. One of \code{"xs"}, \code{"sm"},
#'   \code{"md"}, or \code{"lg"}.
#' @param placeholder Optional placeholder text displayed when the input is
#'   empty.
#' @param helper_text Optional helper text displayed below the input control.
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
  size = c("md", "xs", "sm", "lg"),
  placeholder = NULL,
  helper_text = NULL,
  ...
) {
  size <- match.arg(size)
  htmltools::tag(
    "cds-text-input",
    c(
      list(
        id = inputId,
        label = label,
        size = size,
        placeholder = placeholder,
        `helper-text` = helper_text
      ),
      list(...)
    )
  )
}

#' @export
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

  session$sendInputMessage(session$ns(inputId), msg)
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
#'     Data Science = "ds",
#'     Machine Learning = "ml",
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
  items <- Map(
    function(text, value) {
      checkbox_id <- sub_id(inputId, value)
      attrs <- list(id = checkbox_id, `label-text` = text, value = value)

      if (value %in% selected) {
        attrs$checked <- NA
      }

      htmltools::tag("cds-checkbox", attrs)
    },
    names(choices),
    unname(choices)
  )

  htmltools::tag(
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
  htmltools::tag(
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
  items <- Map(
    function(text, value) {
      radio_id <- sub_id(inputId, value)

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

  htmltools::tag(
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

#' @export
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
    msg$choices <- normalize_choices(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  session$sendInputMessage(session$ns(inputId), msg)
}

#' @export
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
    msg$choices <- normalize_choices(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  session$sendInputMessage(session$ns(inputId), msg)
}

#' @export
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
    msg$choices <- normalize_choices(choices)
  }

  if (!is.null(helper_text)) {
    msg$helperText <- helper_text
  }

  session$sendInputMessage(session$ns(inputId), msg)
}

#' @export
update_carbon_button <- function(
  inputId,
  label = NULL,
  kind = NULL,
  size = NULL,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  msg <- list(...)

  if (!is.null(label)) {
    msg$textContent <- label
  }

  if (!is.null(kind)) {
    msg$kind <- kind
  }

  session$sendInputMessage(session$ns(inputId), msg)
}

#' @export
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

  session$sendInputMessage(session$ns(inputId), msg)
}
