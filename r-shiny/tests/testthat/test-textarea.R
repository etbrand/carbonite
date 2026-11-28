test_that("carbon_textarea renders a cds-textarea", {
  ta <- carbon_textarea("comments", "Comments", placeholder = "Anything?", helper_text = "Optional")

  expect_equal(ta$name, "cds-textarea")
  expect_equal(attr_of(ta, "id"), "comments")
  expect_equal(attr_of(ta, "label"), "Comments")
  expect_equal(attr_of(ta, "rows"), "4")
  expect_equal(attr_of(ta, "placeholder"), "Anything?")
  expect_equal(attr_of(ta, "helper-text"), "Optional")
  expect_false(has_attr(ta, "value"))
  expect_false(has_attr(ta, "enable-counter"))
  expect_false(has_attr(ta, "max-count"))
  expect_false(has_attr(ta, "counter-mode"))
})

test_that("carbon_textarea with a value, rows, a counter, and extra attributes", {
  ta <- carbon_textarea("s", value = "line 1\nline 2", rows = 8, max_count = 100, count_by = "word", disabled = NA)

  expect_equal(attr_of(ta, "value"), "line 1\nline 2")
  expect_equal(attr_of(ta, "rows"), "8")
  expect_true(has_attr(ta, "enable-counter"))
  expect_equal(attr_of(ta, "max-count"), "100")
  expect_equal(attr_of(ta, "counter-mode"), "word")
  expect_true(has_attr(ta, "disabled"))

  expect_equal(attr_of(carbon_textarea("s", max_count = 10), "counter-mode"), "character")
})

test_that("carbon_textarea validates", {
  expect_error(carbon_textarea("s", value = 1), "value")
  expect_error(carbon_textarea("s", rows = 0), "rows")
  expect_error(carbon_textarea("s", rows = 2.5), "rows")
  expect_error(carbon_textarea("s", max_count = 0), "max_count")
  expect_error(carbon_textarea("s", max_count = "10"), "max_count")
  expect_error(carbon_textarea("s", count_by = "line"))
})

test_that("carbon_textarea attaches the carbon dependency", {
  deps <- htmltools::findDependencies(carbon_textarea("s"))
  expect_true("carbon" %in% vapply(deps, `[[`, character(1), "name"))
})

test_that("update_carbon_textarea sends the text input's message", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_textarea("s", value = "", rows = 8, session = session), session)

  expect_equal(msg$id, "s")
  expect_equal(msg$message, list(rows = 8, value = ""))
})
