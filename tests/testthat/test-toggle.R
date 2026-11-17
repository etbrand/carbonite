render <- function(x) as.character(htmltools::renderTags(x)$html)

test_that("carbon_toggle renders a cds-toggle that starts off", {
  tg <- carbon_toggle("notify", "Notifications")

  expect_equal(tg$name, "cds-toggle")
  expect_equal(attr_of(tg, "id"), "notify")
  expect_equal(attr_of(tg, "label-text"), "Notifications")
  expect_equal(attr_of(tg, "label-a"), "On")
  expect_equal(attr_of(tg, "label-b"), "Off")
  expect_false(has_attr(tg, "toggled"))
  expect_false(has_attr(tg, "size"))
})

test_that("carbon_toggle sets value, state text, size, and extra attributes", {
  tg <- carbon_toggle(
    "dark", value = TRUE, on_label = "Enabled", off_label = "",
    size = "sm", disabled = NA
  )

  expect_true(has_attr(tg, "toggled"))
  expect_equal(attr_of(tg, "label-a"), "Enabled")
  expect_equal(attr_of(tg, "label-b"), "")
  expect_equal(attr_of(tg, "size"), "sm")
  expect_true(has_attr(tg, "disabled"))
  expect_false(has_attr(tg, "label-text"))
  expect_match(render(tg), "<cds-toggle id=\"dark\" toggled", fixed = TRUE)
})

test_that("carbon_toggle validates its arguments", {
  expect_error(carbon_toggle("x", value = "yes"), "value")
  expect_error(carbon_toggle("x", value = NA), "value")
  expect_error(carbon_toggle("x", size = "lg"))
})

test_that("update_carbon_toggle maps arguments to properties", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_toggle(
      "tg", value = FALSE, label = "Wi-Fi", on_label = "Yes", off_label = "No",
      disabled = TRUE, session = session
    ),
    session
  )

  expect_equal(msg$id, "tg")
  expect_equal(
    msg$message,
    list(disabled = TRUE, toggled = FALSE, labelText = "Wi-Fi", labelA = "Yes", labelB = "No")
  )
})

test_that("update_carbon_toggle sends only what changed, and validates value", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_toggle("tg", value = TRUE, session = session), session)
  expect_equal(msg$message, list(toggled = TRUE))

  expect_error(update_carbon_toggle("tg", value = "on", session = fake_session()), "value")
})
