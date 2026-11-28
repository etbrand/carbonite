render <- function(x) as.character(htmltools::renderTags(x)$html)

plans <- data.frame(
  plan = c("Lite", "Standard", "Enterprise"),
  storage = c("5 GB", "100 GB", NA)
)

test_that("carbon_structured_list renders a header and one row per data row", {
  sl <- carbon_structured_list(plans, columns = c(plan = "Plan"), condensed = TRUE)

  expect_equal(sl$name, "cds-structured-list")
  expect_true(has_attr(sl, "condensed"))
  expect_false(has_attr(sl, "flush"))
  expect_false(has_attr(sl, "selection-name"))
  expect_null(attr_of(sl, "class"))

  headers <- find_tags(sl, "cds-structured-list-header-cell")
  expect_equal(vapply(headers, function(h) h$children[[1]], character(1)), c("Plan", "storage"))

  rows <- find_tags(sl, "cds-structured-list-body > cds-structured-list-row")
  expect_length(rows, 3)
  expect_false(has_attr(rows[[1]], "selection-name"))

  cells <- find_tags(rows[[3]], "cds-structured-list-cell")
  expect_equal(vapply(cells, function(c) c$children[[1]], character(1)), c("Enterprise", ""))
})

test_that("list columns hold UI", {
  df <- data.frame(feature = c("SSO", "Audit log"))
  df$included <- I(list(htmltools::strong("Yes"), "No"))

  html <- render(carbon_structured_list(df))

  expect_match(html, "<cds-structured-list-cell>\\s*<strong>Yes</strong>\\s*</cds-structured-list-cell>")
  expect_match(html, "<cds-structured-list-cell>No</cds-structured-list-cell>", fixed = TRUE)
})

test_that("single selection marks the list, rows, and selected row", {
  sl <- carbon_structured_list(
    plans, id = "plan", selection = "single", row_key = "plan", selected = "Standard"
  )

  expect_equal(attr_of(sl, "id"), "plan")
  expect_equal(attr_of(sl, "selection-name"), "plan")
  expect_equal(attr_of(sl, "class"), "carbonite-structured-list-input")
  expect_equal(attr_of(sl, "data-row-key-type"), "key")
  expect_equal(attr_of(find_tags(sl, "cds-structured-list-header-row")[[1]], "selection-name"), "plan")

  rows <- find_tags(sl, "cds-structured-list-row")
  expect_equal(vapply(rows, attr_of, character(1), "selection-value"), plans$plan)
  expect_equal(vapply(rows, attr_of, character(1), "selection-name"), rep("plan", 3))
  expect_equal(vapply(rows, has_attr, logical(1), "selected"), c(FALSE, TRUE, FALSE))
})

test_that("without row_key, selection uses row numbers", {
  sl <- carbon_structured_list(plans, id = "p", selection = "single", selected = 3)
  rows <- find_tags(sl, "cds-structured-list-row")

  expect_equal(attr_of(sl, "data-row-key-type"), "index")
  expect_equal(vapply(rows, attr_of, character(1), "selection-value"), c("1", "2", "3"))
  expect_true(has_attr(rows[[3]], "selected"))
})

test_that("extra attributes go on the list", {
  sl <- carbon_structured_list(plans, id = "p", class = "mine", style = "max-width: 40rem")

  expect_equal(attr_of(sl, "class"), "mine")
  expect_equal(attr_of(sl, "style"), "max-width: 40rem")
})

test_that("carbon_structured_list validates its arguments", {
  expect_error(carbon_structured_list(list(a = 1)), "data frame")
  expect_error(carbon_structured_list(plans, selection = "single"), "id")
  expect_error(carbon_structured_list(plans, id = "p", selection = "single", flush = TRUE), "flush")
  expect_error(carbon_structured_list(plans, selected = 1), "selection")
  expect_error(carbon_structured_list(plans, id = "p", selection = "single", selected = 1:2), "single row")
  expect_error(carbon_structured_list(plans, id = "p", selection = "single", selected = 9), "Unknown")
  expect_error(carbon_structured_list(plans, row_key = "nope"), "row_key")
  expect_error(carbon_structured_list(plans, columns = c(nope = "X")), "Unknown")
  expect_error(carbon_structured_list(plans, columns = c("X")), "named")
  expect_error(carbon_structured_list(plans, condensed = "yes"), "condensed")
  expect_error(carbon_structured_list(plans, selection = "multiple"))
})

test_that("update_carbon_structured_list sends the selected key", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_structured_list("plan", "Enterprise", session = session), session)

  expect_equal(msg$id, "plan")
  expect_equal(msg$message, list(selected = "Enterprise"))

  session <- fake_session()
  msg <- capture_input_message(update_carbon_structured_list("plan", 2, session = session), session)
  expect_equal(msg$message, list(selected = "2"))
})

test_that("update_carbon_structured_list can clear the selection", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_structured_list("plan", character(0), session = session), session)

  expect_equal(msg$message, list(selected = NULL))
  expect_true("selected" %in% names(msg$message))

  expect_error(update_carbon_structured_list("plan", c("a", "b"), session = fake_session()), "single row")
})
