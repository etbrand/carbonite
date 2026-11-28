# carbon_slider ----------------------------------------------------------------

test_that("carbon_slider renders a single-value slider with a number box", {
  sl <- carbon_slider("bins", "Bins", min = 1, max = 50, value = 30)

  expect_equal(sl$name, "cds-slider")
  expect_equal(attr_of(sl, "id"), "bins")
  expect_equal(attr_of(sl, "label-text"), "Bins")
  expect_equal(attr_of(sl, "min"), "1")
  expect_equal(attr_of(sl, "max"), "50")
  expect_equal(attr_of(sl, "step"), "1")
  expect_equal(attr_of(sl, "value"), "30")
  expect_false(has_attr(sl, "value-upper"))
  expect_false(has_attr(sl, "hide-text-input"))
  expect_false(has_attr(sl, "disabled"))

  boxes <- find_tags(sl, "cds-slider-input")
  expect_length(boxes, 1)
  expect_equal(attr_of(boxes[[1]], "type"), "number")
  expect_equal(attr_of(boxes[[1]], "aria-label"), "Bins")
})

test_that("a value of length two makes a range slider", {
  sl <- carbon_slider("price", "Price", min = 0, max = 1000, value = c(200, 800), step = 10)

  expect_equal(attr_of(sl, "value"), "200")
  expect_equal(attr_of(sl, "value-upper"), "800")
  expect_equal(attr_of(sl, "step"), "10")

  boxes <- find_tags(sl, "cds-slider-input")
  expect_length(boxes, 2)
  # Carbon's two-handle slider: start box in `lower-input`, end box id "upper"
  expect_equal(attr_of(boxes[[1]], "slot"), "lower-input")
  expect_equal(attr_of(boxes[[2]], "id"), "upper")
  expect_equal(attr_of(boxes[[1]], "aria-label"), "Price start")
  expect_equal(attr_of(boxes[[2]], "aria-label"), "Price end")
})

test_that("carbon_slider options", {
  sl <- carbon_slider(
    "x", "X", min = 0, max = 1, value = 0.5, step = 0.1,
    hide_text_input = TRUE, min_label = "%", max_label = "%", disabled = TRUE, class = "wide"
  )

  expect_true(has_attr(sl, "hide-text-input"))
  expect_true(has_attr(sl, "disabled"))
  expect_equal(attr_of(sl, "min-label"), "%")
  expect_equal(attr_of(sl, "max-label"), "%")
  expect_equal(attr_of(sl, "step"), "0.1")
  expect_equal(attr_of(sl, "class"), "wide")
})

test_that("carbon_slider validates", {
  expect_error(carbon_slider("x", "X", min = 10, max = 1, value = 5), "less than")
  expect_error(carbon_slider("x", "X", min = 0, max = 10, value = 11), "between")
  expect_error(carbon_slider("x", "X", min = 0, max = 10, value = c(8, 2)), "in order")
  expect_error(carbon_slider("x", "X", min = 0, max = 10, value = 1:3), "one number")
  expect_error(carbon_slider("x", "X", min = 0, max = 10, value = "5"), "one number")
  expect_error(carbon_slider("x", "X", min = 0, max = 10, value = 5, step = 0), "positive")
  expect_error(carbon_slider("x", "X", min = "0", max = 10, value = 5), "min")
  expect_error(carbon_slider("x", "X", min = 0, max = 10, value = 5, disabled = "no"), "disabled")
})

test_that("update_carbon_slider sends value, limits, and Carbon property names", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_slider("bins", value = 10, min = 0, max = 100, step = 5, label = "Bins", disabled = TRUE, session = session),
    session
  )

  expect_equal(msg$id, "bins")
  expect_equal(msg$message, list(value = 10, min = 0, max = 100, step = 5, labelText = "Bins", disabled = TRUE))

  session <- fake_session()
  msg <- capture_input_message(update_carbon_slider("price", value = c(5, 5), session = session), session)
  expect_equal(msg$message, list(value = list(5, 5)))

  expect_error(update_carbon_slider("x", value = 1:3, session = fake_session()), "one number")
})

# carbon_date_picker -----------------------------------------------------------

test_that("carbon_date_picker renders a single-date picker", {
  dp <- carbon_date_picker("due", "Due date", value = as.Date("2026-12-01"), min = "2026-01-01", size = "sm")

  expect_equal(dp$name, "cds-date-picker")
  expect_equal(attr_of(dp, "id"), "due")
  expect_equal(attr_of(dp, "value"), "2026-12-01")
  expect_equal(attr_of(dp, "min-date"), "2026-01-01")
  expect_false(has_attr(dp, "max-date"))
  expect_equal(attr_of(dp, "date-format"), "m/d/Y")
  expect_false(has_attr(dp, "disabled"))

  inputs <- find_tags(dp, "cds-date-picker-input")
  expect_length(inputs, 1)
  expect_equal(attr_of(inputs[[1]], "kind"), "single")
  expect_equal(attr_of(inputs[[1]], "label-text"), "Due date")
  expect_equal(attr_of(inputs[[1]], "placeholder"), "mm/dd/yyyy")
  expect_equal(attr_of(inputs[[1]], "size"), "sm")
})

test_that("carbon_date_picker without a value, and options", {
  dp <- carbon_date_picker("d", "D", date_format = "Y-m-d", placeholder = "yyyy-mm-dd", disabled = TRUE)

  expect_false(has_attr(dp, "value"))
  expect_equal(attr_of(dp, "date-format"), "Y-m-d")
  expect_true(has_attr(dp, "disabled"))
})

test_that("carbon_date_range_picker joins start and end", {
  dp <- carbon_date_range_picker("period", start = "2026-01-01", end = as.Date("2026-03-31"), label_end = "To")

  expect_equal(attr_of(dp, "value"), "2026-01-01/2026-03-31")
  inputs <- find_tags(dp, "cds-date-picker-input")
  expect_equal(vapply(inputs, attr_of, character(1), "kind"), c("from", "to"))
  expect_equal(vapply(inputs, attr_of, character(1), "label-text"), c("Start date", "To"))

  expect_equal(attr_of(carbon_date_range_picker("p", start = "2026-01-01"), "value"), "2026-01-01")
  expect_false(has_attr(carbon_date_range_picker("p"), "value"))
})

test_that("date pickers validate dates", {
  expect_error(carbon_date_picker("d", "D", value = "not a date"), "value")
  expect_error(carbon_date_picker("d", "D", value = c("2026-01-01", "2026-01-02")), "single date")
  expect_error(carbon_date_picker("d", "D", min = "2026-02-01", max = "2026-01-01"), "after")
  expect_error(carbon_date_range_picker("p", start = "2026-02-01", end = "2026-01-01"), "after")
  expect_error(carbon_date_range_picker("p", end = "2026-01-01"), "needs a")
  expect_error(carbon_date_picker("d", "D", date_format = 1), "date_format")
  expect_error(carbon_date_picker("d", "D", size = "xl"))
})

test_that("update_carbon_date_picker sends ISO dates", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_date_picker("due", value = as.Date("2026-05-01"), min = "2026-01-01", max = "2026-12-31", session = session),
    session
  )
  expect_equal(msg$id, "due")
  expect_equal(msg$message, list(value = "2026-05-01", minDate = "2026-01-01", maxDate = "2026-12-31"))

  session <- fake_session()
  msg <- capture_input_message(update_carbon_date_picker("p", value = c("2026-04-01", "2026-06-30"), session = session), session)
  expect_equal(msg$message, list(value = "2026-04-01/2026-06-30"))
})

test_that("update_carbon_date_picker clears with NA or character(0), and validates", {
  for (empty in list(NA, character(0))) {
    session <- fake_session()
    msg <- capture_input_message(update_carbon_date_picker("due", value = empty, session = session), session)
    expect_equal(msg$message, list(value = ""))
  }

  expect_error(update_carbon_date_picker("p", value = c("2026-06-30", "2026-04-01"), session = fake_session()), "in order")
  expect_error(update_carbon_date_picker("p", value = rep("2026-01-01", 3), session = fake_session()), "one date")
  expect_error(update_carbon_date_picker("p", value = "nope", session = fake_session()), "value")
})

test_that("slider and date pickers attach the carbon dependency", {
  for (x in list(
    carbon_slider("s", "S", 0, 1, 0),
    carbon_date_picker("d", "D"),
    carbon_date_range_picker("r")
  )) {
    deps <- htmltools::findDependencies(x)
    expect_true("carbon" %in% vapply(deps, `[[`, character(1), "name"))
  }
})
