test_that("12-hour time picker shows the time with AM/PM", {
  tp <- carbon_time_picker("start", "Start time", value = "14:05")

  expect_equal(tp$name, "cds-time-picker")
  expect_equal(attr_of(tp, "id"), "start")
  expect_equal(attr_of(tp, "label-text"), "Start time")
  expect_equal(attr_of(tp, "value"), "2:05")
  expect_equal(attr_of(tp, "data-clock"), "12")
  expect_equal(attr_of(tp, "size"), "md")
  expect_equal(attr_of(tp, "placeholder"), "hh:mm")
  expect_match(attr_of(tp, "invalid-text"), "AM or PM")
  # Carbon's own (12-hour) pattern applies
  expect_false(has_attr(tp, "pattern"))

  select <- find_tags(tp, "cds-time-picker-select")
  expect_length(select, 1)
  expect_equal(attr_of(select[[1]], "value"), "PM")
  expect_equal(
    vapply(find_tags(select[[1]], "cds-select-item"), attr_of, character(1), "value"),
    c("AM", "PM")
  )
})

test_that("12-hour conversion around noon and midnight", {
  shown <- function(value) {
    tp <- carbon_time_picker("t", value = value)
    paste(attr_of(tp, "value"), attr_of(find_tags(tp, "cds-time-picker-select")[[1]], "value"))
  }

  expect_equal(shown("00:00"), "12:00 AM")
  expect_equal(shown("09:30"), "9:30 AM")
  expect_equal(shown("12:00"), "12:00 PM")
  expect_equal(shown("23:59"), "11:59 PM")
})

test_that("24-hour time picker has no AM/PM and a 24-hour pattern", {
  tp <- carbon_time_picker("alarm", value = "6:45", clock = "24", size = "sm", disabled = TRUE)

  expect_equal(attr_of(tp, "value"), "06:45")
  expect_equal(attr_of(tp, "data-clock"), "24")
  expect_equal(attr_of(tp, "size"), "sm")
  expect_match(attr_of(tp, "pattern"), "2\\[0-3\\]")
  expect_true(has_attr(tp, "disabled"))
  expect_length(find_tags(tp, "cds-time-picker-select"), 0)
  expect_match(attr_of(tp, "invalid-text"), "24-hour")
})

test_that("no value, and a custom invalid text", {
  tp <- carbon_time_picker("t", invalid_text = "Bad time")

  expect_false(has_attr(tp, "value"))
  expect_equal(attr_of(tp, "invalid-text"), "Bad time")
  expect_equal(attr_of(find_tags(tp, "cds-time-picker-select")[[1]], "value"), "AM")
})

test_that("carbon_time_picker validates", {
  expect_error(carbon_time_picker("t", value = "25:00"), "24-hour time")
  expect_error(carbon_time_picker("t", value = "9:30 PM"), "24-hour time")
  expect_error(carbon_time_picker("t", value = 930), "24-hour time")
  expect_error(carbon_time_picker("t", clock = "36"))
  expect_error(carbon_time_picker("t", disabled = "no"), "disabled")
})

test_that("carbon_time_picker attaches the carbon dependency", {
  deps <- htmltools::findDependencies(carbon_time_picker("t"))
  expect_true("carbon" %in% vapply(deps, `[[`, character(1), "name"))
})

test_that("update_carbon_time_picker sends a normalised time", {
  session <- fake_session()
  msg <- capture_input_message(
    update_carbon_time_picker("t", value = "9:05", label = "Start", disabled = FALSE, session = session),
    session
  )

  expect_equal(msg$id, "t")
  expect_equal(msg$message, list(value = "09:05", labelText = "Start", disabled = FALSE))

  session <- fake_session()
  msg <- capture_input_message(update_carbon_time_picker("t", value = "", session = session), session)
  expect_equal(msg$message, list(value = ""))

  expect_error(update_carbon_time_picker("t", value = "noon", session = fake_session()), "24-hour time")
})
