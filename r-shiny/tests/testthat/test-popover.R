test_that("carbon_popover puts the trigger first and the content in its slot", {
  pop <- carbon_popover(
    carbon_button("help", "Help"),
    htmltools::p("Some help"),
    id = "help_popover"
  )

  expect_equal(pop$name, "cds-popover")
  expect_equal(attr_of(pop, "id"), "help_popover")
  expect_equal(attr_of(pop, "class"), "carbonite-popover")
  expect_equal(attr_of(pop, "align"), "bottom")
  expect_false(has_attr(pop, "open"))
  expect_false(has_attr(pop, "data-caret"))
  expect_false(has_attr(pop, "data-drop-shadow"))
  expect_false(has_attr(pop, "highcontrast"))

  expect_equal(pop$children[[1]]$name, "cds-button")
  content <- pop$children[[2]]
  expect_equal(content$name, "cds-popover-content")
  expect_equal(attr_of(content, "slot"), "content")
  body <- find_tags(content, "div")[[1]]
  expect_equal(attr_of(body, "class"), "carbonite-popover__body")
  expect_match(as.character(body), "<p>Some help</p>", fixed = TRUE)
})

test_that("carbon_popover options", {
  pop <- carbon_popover(
    "Text trigger", "Content",
    open = TRUE, align = "right-start", autoalign = TRUE, caret = FALSE,
    high_contrast = TRUE, drop_shadow = FALSE, padded = FALSE
  )

  expect_false(has_attr(pop, "id"))
  expect_true(has_attr(pop, "open"))
  expect_equal(attr_of(pop, "align"), "right-start")
  expect_true(has_attr(pop, "autoalign"))
  expect_true(has_attr(pop, "highcontrast"))
  expect_equal(attr_of(pop, "data-caret"), "false")
  expect_equal(attr_of(pop, "data-drop-shadow"), "false")
  # Plain-text triggers are wrapped: Carbon's trigger is an element
  expect_equal(pop$children[[1]]$name, "span")
  expect_null(attr_of(find_tags(pop$children[[2]], "div")[[1]], "class"))
})

test_that("carbon_popover validates", {
  expect_error(carbon_popover("t", "c", align = "middle"))
  expect_error(carbon_popover("t", "c", open = "yes"), "open")
  expect_error(carbon_popover("t", "c", caret = NA), "caret")
})

test_that("carbon_popover attaches the carbon dependency", {
  deps <- htmltools::findDependencies(carbon_popover("t", "c"))
  expect_true("carbon" %in% vapply(deps, `[[`, character(1), "name"))
})

test_that("update_carbon_popover sends open", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_popover("p", open = TRUE, session = session), session)

  expect_equal(msg$id, "p")
  expect_equal(msg$message, list(open = TRUE))
  expect_error(update_carbon_popover("p", open = "yes", session = fake_session()), "open")
})
