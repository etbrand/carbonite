test_that("carbon_password_input renders a cds-password-input", {
  pw <- carbon_password_input("password", "Password", placeholder = "Your password", helper_text = "Case sensitive")

  expect_equal(pw$name, "cds-password-input")
  expect_equal(attr_of(pw, "id"), "password")
  expect_equal(attr_of(pw, "label"), "Password")
  expect_equal(attr_of(pw, "size"), "md")
  expect_equal(attr_of(pw, "placeholder"), "Your password")
  expect_equal(attr_of(pw, "helper-text"), "Case sensitive")
  expect_equal(attr_of(pw, "show-password-label"), "Show password")
  expect_equal(attr_of(pw, "hide-password-label"), "Hide password")
  expect_equal(attr_of(pw, "autocomplete"), "current-password")
  expect_false(has_attr(pw, "value"))
})

test_that("carbon_password_input options and extra attributes", {
  pw <- carbon_password_input(
    "pw", value = "x", size = "sm", autocomplete = "new-password",
    show_password_label = "Afficher", hide_password_label = "Masquer", disabled = NA
  )

  expect_equal(attr_of(pw, "value"), "x")
  expect_equal(attr_of(pw, "size"), "sm")
  expect_equal(attr_of(pw, "autocomplete"), "new-password")
  expect_equal(attr_of(pw, "show-password-label"), "Afficher")
  expect_equal(attr_of(pw, "hide-password-label"), "Masquer")
  expect_true(has_attr(pw, "disabled"))
})

test_that("carbon_password_input validates", {
  expect_error(carbon_password_input("pw", value = 1), "value")
  expect_error(carbon_password_input("pw", autocomplete = NA), "autocomplete")
  expect_error(carbon_password_input("pw", size = "xl"))
})

test_that("carbon_password_input attaches the carbon dependency", {
  deps <- htmltools::findDependencies(carbon_password_input("pw"))
  expect_true("carbon" %in% vapply(deps, `[[`, character(1), "name"))
})

test_that("update_carbon_password_input sends the text input's message", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_password_input("pw", value = "", helper_text = "Try again", disabled = TRUE, session = session),
    session
  )

  expect_equal(msg$id, "pw")
  expect_equal(msg$message, list(disabled = TRUE, value = "", helperText = "Try again"))
})
