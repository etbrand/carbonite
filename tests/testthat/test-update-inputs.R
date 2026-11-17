# These tests check the messages that update_carbon_*() send. The JS bindings'
# receiveMessage() assigns every key except `id`/`choices` straight onto the
# element as a property, so keys must be camelCase Carbon property names.

test_that("update functions namespace the input id exactly once in a module", {
  # The module session's sendInputMessage() adds the namespace itself, so
  # update functions must pass the bare id (not session$ns(id)).
  session <- fake_session(ns = shiny::NS("mod"))
  msg <- capture_input_message(update_carbon_text_input("txt", value = "hi", session = session), session)

  expect_equal(msg$id, "mod-txt")
})

test_that("update functions send an empty message when given nothing", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_select("x", session = session), session)

  expect_equal(msg$message, list())
})

# update_carbon_text_input ----------------------------------------------------

test_that("update_carbon_text_input maps arguments to properties", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_text_input(
      "txt", value = "hi", placeholder = "Type", helper_text = "Help",
      disabled = TRUE, session = session
    ),
    session
  )

  expect_equal(msg$id, "txt")
  expect_equal(
    msg$message,
    list(disabled = TRUE, value = "hi", placeholder = "Type", helperText = "Help")
  )
})

test_that("update_carbon_text_input can clear the value", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_text_input("txt", value = "", session = session), session)

  expect_equal(msg$message$value, "")
})

# update_carbon_number_input --------------------------------------------------

test_that("update_carbon_number_input maps arguments to properties", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_number_input(
      "n", value = 3, label = "N", min = 0, max = 5, step = 0.5,
      size = "sm", placeholder = "0", helper_text = "Help",
      session = session
    ),
    session
  )

  expect_equal(
    msg$message,
    list(
      value = 3, label = "N", min = 0, max = 5, step = 0.5,
      size = "sm", placeholder = "0", helperText = "Help"
    )
  )
})

test_that("update_carbon_number_input sends value 0", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_number_input("n", value = 0, session = session), session)

  expect_identical(msg$message, list(value = 0))
})

# update_carbon_button --------------------------------------------------------

test_that("update_carbon_button maps label, kind and size", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_button("b", label = "Stop", kind = "danger", size = "lg", session = session),
    session
  )

  # `label` (not `textContent`) so the binding can keep the icon SVG
  expect_equal(msg$message, list(label = "Stop", kind = "danger", size = "lg"))
})

test_that("update_carbon_button sends a new icon as slotted SVG markup", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_button("b", icon = "edit", session = session),
    session
  )

  expect_named(msg$message, "icon")
  expect_equal(msg$message$icon, as.character(carbon_icon("edit", slot = "icon")))
  expect_match(msg$message$icon, '^<svg [^>]*slot="icon"')
})

test_that("update_carbon_button removes the icon with icon = FALSE", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_button("b", icon = FALSE, session = session), session)

  expect_equal(msg$message, list(icon = ""))
})

test_that("update_carbon_button validates the icon", {
  expect_error(update_carbon_button("b", icon = "nope", session = fake_session()), "Unknown")
})

test_that("update_carbon_checkbox_group can clear the selection", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_checkbox_group("cb", selected = character(0), session = session),
    session
  )

  expect_identical(msg$message, list(value = character(0)))
})

# update_carbon_select --------------------------------------------------------

test_that("update_carbon_select maps arguments to properties", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_select(
      "s", label = "Fruit", selected = "b", choices = c("a", "b"),
      helper_text = "Help", session = session
    ),
    session
  )

  expect_equal(msg$message$labelText, "Fruit")
  expect_equal(msg$message$value, "b")
  expect_equal(msg$message$helperText, "Help")
  # Unnamed choices are named by their values so the JS can use them as labels
  expect_equal(msg$message$choices, list(a = "a", b = "b"))
})

test_that("update_carbon_select keeps choice labels", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_select("s", choices = c(Apple = "apple"), session = session),
    session
  )

  expect_equal(msg$message$choices, list(Apple = "apple"))
})

# update_carbon_radio_group / update_carbon_checkbox_group --------------------

test_that("update_carbon_radio_group maps arguments to properties", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_radio_group(
      "r", label = "Size", choices = c(Small = "s", Large = "l"),
      selected = "l", helper_text = "Help", session = session
    ),
    session
  )

  expect_equal(
    msg$message,
    list(
      legendText = "Size", value = "l",
      choices = list(Small = "s", Large = "l"), helperText = "Help"
    )
  )
})

test_that("update_carbon_checkbox_group sends every selected value", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_checkbox_group(
      "cb", label = "Opts", choices = c("a", "b", "c"),
      selected = c("a", "c"), session = session
    ),
    session
  )

  expect_equal(msg$message$legendText, "Opts")
  expect_equal(msg$message$value, c("a", "c"))
  expect_equal(msg$message$choices, list(a = "a", b = "b", c = "c"))
})

# Dropdown family -------------------------------------------------------------

test_that("update_carbon_dropdown and combobox map label and placeholder", {
  for (fn in list(update_carbon_dropdown, update_carbon_combobox)) {
    session <- fake_session()
    msg <- capture_input_message(
      fn(
        "d", label = "City", selected = "a", choices = c("a", "b"),
        placeholder = "Choose", helper_text = "Help", session = session
      ),
      session
    )

    expect_equal(
      msg$message,
      list(
        titleText = "City", value = "a", choices = list(a = "a", b = "b"),
        helperText = "Help", label = "Choose"
      )
    )
  }
})

test_that("single-select dropdowns reject multiple selected values", {
  session <- fake_session()

  expect_error(update_carbon_dropdown("d", selected = c("a", "b"), session = session), "single value")
  expect_error(update_carbon_combobox("d", selected = c("a", "b"), session = session), "single value")
  expect_length(session$messages, 0)
})

test_that("update_carbon_multiselect joins selected values with commas", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_multiselect("m", selected = c("a", "c"), session = session),
    session
  )

  expect_equal(msg$message, list(value = "a,c"))
})

test_that("update_carbon_multiselect sends a single selected value as-is", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_multiselect(
      "m", label = "Tags", selected = "a", choices = c("a", "b"),
      placeholder = "Pick", helper_text = "Help", session = session
    ),
    session
  )

  expect_equal(
    msg$message,
    list(
      titleText = "Tags", value = "a", choices = list(a = "a", b = "b"),
      helperText = "Help", label = "Pick"
    )
  )
})

test_that("update_carbon_multiselect rejects choices containing commas", {
  session <- fake_session()

  expect_error(
    update_carbon_multiselect("m", choices = c("a,b", "c"), session = session),
    "commas"
  )
  expect_length(session$messages, 0)
})

# Real Shiny session ----------------------------------------------------------

test_that("update functions work inside a module server", {
  server <- function(id) {
    shiny::moduleServer(id, function(input, output, session) {
      shiny::observe(update_carbon_text_input("txt", value = "hi"))
    })
  }

  expect_no_error(shiny::testServer(server, args = list(id = "mod"), {
    session$flushReact()
    expect_equal(session$ns("txt"), "mod-txt")
  }))
})

# update_carbon_table_selection ------------------------------------------------

test_that("update_carbon_table_selection targets the _selected input", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_table_selection("cars", selected = c(1, 3), session = session),
    session
  )

  # Not namespaced here: a module's session already namespaces
  # sendInputMessage(), as with Shiny's own update*() functions.
  expect_equal(msg$id, "cars_selected")
  expect_equal(msg$message, list(selected = c("1", "3")))
})

test_that("update_carbon_table_selection clears with NULL", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_table_selection("cars", selected = NULL, session = session),
    session
  )

  # character(0) is sent as [], which the binding treats as "clear"
  expect_equal(msg$message, list(selected = character(0)))
})

test_that("choices are sent without jsonlite's named-vector warning", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_combobox("c", choices = c("USD – US dollar" = "USD", "EUR – Euro" = "EUR"), session = session),
    session
  )

  # Same {label: value} object the JS expects, with no deprecation message
  expect_silent(json <- shiny:::toJSON(msg$message))
  expect_equal(as.character(json), '{"choices":{"USD – US dollar":"USD","EUR – Euro":"EUR"}}')
})
