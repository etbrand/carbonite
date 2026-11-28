# Progress indicator -------------------------------------------------------------

test_that("carbon_progress_indicator renders steps from strings and carbon_progress_step()", {
  pi <- carbon_progress_indicator(
    "signup",
    "Account",
    carbon_progress_step("Billing", secondary_label = "Optional", invalid = TRUE),
    "Review",
    current = 2
  )

  expect_equal(pi$name, "cds-progress-indicator")
  expect_equal(attr_of(pi, "id"), "signup")
  expect_equal(attr_of(pi, "current-index"), "1")
  expect_false(has_attr(pi, "vertical"))
  expect_false(has_attr(pi, "data-clickable"))

  steps <- find_tags(pi, "cds-progress-step")
  expect_equal(vapply(steps, attr_of, character(1), "label"), c("Account", "Billing", "Review"))
  expect_equal(attr_of(steps[[2]], "secondary-label"), "Optional")
  expect_true(has_attr(steps[[2]], "invalid"))
  expect_equal(attr_of(steps[[1]], "description"), "Account")
})

test_that("carbon_progress_indicator options", {
  pi <- carbon_progress_indicator(
    "s", "A", carbon_progress_step("B", disabled = TRUE),
    vertical = TRUE, space_equally = TRUE, clickable = TRUE
  )

  expect_equal(attr_of(pi, "current-index"), "0")
  expect_true(has_attr(pi, "vertical"))
  expect_true(has_attr(pi, "space-equally"))
  expect_true(has_attr(pi, "data-clickable"))
  expect_true(has_attr(find_tags(pi, "cds-progress-step")[[2]], "disabled"))

  # Without an id: a static indicator
  expect_false(has_attr(carbon_progress_indicator(NULL, "A", "B"), "id"))
})

test_that("carbon_progress_indicator validates", {
  expect_error(carbon_progress_indicator("s"), "at least one step")
  expect_error(carbon_progress_indicator("s", "A", 1), "Steps")
  expect_error(carbon_progress_indicator("s", "A", htmltools::div()), "Steps")
  expect_error(carbon_progress_indicator("s", "A", "B", current = 3), "from 1 to 2")
  expect_error(carbon_progress_indicator("s", "A", current = 0), "step number")
  expect_error(carbon_progress_indicator(NULL, "A", clickable = TRUE), "inputId")
  expect_error(carbon_progress_indicator("s", "A", vertical = "yes"), "vertical")
  expect_error(carbon_progress_step(1), "label")
  expect_error(carbon_progress_step("A", invalid = NA), "invalid")
})

test_that("update_carbon_progress_indicator sends the step", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_progress_indicator("s", 3, session = session), session)

  expect_equal(msg$id, "s")
  expect_equal(msg$message, list(current = 3))
  expect_error(update_carbon_progress_indicator("s", 0, session = fake_session()), "step number")
})

# Progress bar -----------------------------------------------------------------

test_that("carbon_progress_bar renders a cds-progress-bar", {
  pb <- carbon_progress_bar("upload", "Uploading", value = 40, helper_text = "4 of 10 files")

  expect_equal(pb$name, "cds-progress-bar")
  expect_equal(attr_of(pb, "id"), "upload")
  expect_equal(attr_of(pb, "label"), "Uploading")
  expect_equal(attr_of(pb, "value"), "40")
  expect_equal(attr_of(pb, "max"), "100")
  expect_equal(attr_of(pb, "helper-text"), "4 of 10 files")
  expect_equal(attr_of(pb, "status"), "active")
  expect_equal(attr_of(pb, "type"), "default")
  expect_equal(attr_of(pb, "size"), "big")
  expect_false(has_attr(pb, "hide-label"))
})

test_that("an indeterminate progress bar has no value; other options", {
  pb <- carbon_progress_bar("p", "Loading", max = 10, status = "finished", type = "inline", size = "small", hide_label = TRUE)

  expect_false(has_attr(pb, "value"))
  expect_equal(attr_of(pb, "max"), "10")
  expect_equal(attr_of(pb, "status"), "finished")
  expect_equal(attr_of(pb, "type"), "inline")
  expect_equal(attr_of(pb, "size"), "small")
  expect_true(has_attr(pb, "hide-label"))
})

test_that("carbon_progress_bar validates", {
  expect_error(carbon_progress_bar("p", "P", value = 120), "from 0 to")
  expect_error(carbon_progress_bar("p", "P", value = -1), "from 0 to")
  expect_error(carbon_progress_bar("p", "P", value = "50"), "from 0 to")
  expect_error(carbon_progress_bar("p", "P", max = 0), "max")
  expect_error(carbon_progress_bar("p", "P", status = "done"))
  expect_error(carbon_progress_bar("p", "P", hide_label = 1), "hide_label")
})

# A session recording custom messages, with a module namespace
custom_session <- function(ns = shiny::NS(NULL)) {
  session <- new.env()
  session$ns <- ns
  session$custom <- list()
  session$sendCustomMessage <- function(type, message) {
    session$custom[[length(session$custom) + 1]] <- list(type = type, message = message)
  }
  session
}

test_that("update_carbon_progress_bar sends a custom message to the namespaced id", {
  session <- custom_session(shiny::NS("mod"))
  update_carbon_progress_bar("p", value = 70, max = 200, label = "L", helper_text = "7 of 10", status = "active", session = session)

  expect_length(session$custom, 1)
  expect_equal(session$custom[[1]]$type, "carbonite-progress-bar")
  expect_equal(
    session$custom[[1]]$message,
    list(id = "mod-p", value = 70, max = 200, label = "L", helperText = "7 of 10", status = "active")
  )
})

test_that("update_carbon_progress_bar: NA value is indeterminate; validation", {
  session <- custom_session()
  update_carbon_progress_bar("p", value = NA, session = session)

  msg <- session$custom[[1]]$message
  expect_true("value" %in% names(msg))
  expect_null(msg$value)

  expect_error(update_carbon_progress_bar("p", value = -5, session = custom_session()), "from 0")
  expect_error(update_carbon_progress_bar("p", max = 0, session = custom_session()), "max")
  expect_error(update_carbon_progress_bar("p", status = "done", session = custom_session()))
})

test_that("progress components attach the carbon dependency", {
  for (x in list(carbon_progress_indicator("s", "A"), carbon_progress_bar("p", "P"))) {
    deps <- htmltools::findDependencies(x)
    expect_true("carbon" %in% vapply(deps, `[[`, character(1), "name"))
  }
})
