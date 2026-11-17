# carbon_dropdown -------------------------------------------------------------

test_that("carbon_dropdown renders items with sub-ids", {
  dd <- carbon_dropdown(
    "city", "City",
    choices = c(Paris = "paris", `New York` = "new york"),
    placeholder = "Choose a city", helper_text = "Where to?"
  )

  expect_equal(dd$name, "cds-dropdown")
  expect_equal(attr_of(dd, "id"), "city")
  expect_equal(attr_of(dd, "title-text"), "City")
  expect_equal(attr_of(dd, "label"), "Choose a city")
  expect_equal(attr_of(dd, "helper-text"), "Where to?")
  expect_equal(attr_of(dd, "size"), "md")

  items <- find_tags(dd, "cds-dropdown-item")
  expect_length(items, 2)
  expect_equal(vapply(items, attr_of, "", "id"), c("city__paris", "city__new_york"))
  expect_equal(vapply(items, attr_of, "", "value"), c("paris", "new york"))
  expect_match(as.character(items[[2]]), ">New York</cds-dropdown-item>", fixed = TRUE)
})

test_that("carbon_dropdown marks the selected item", {
  dd <- carbon_dropdown("x", choices = c("a", "b"), selected = "b")

  items <- find_tags(dd, "cds-dropdown-item")
  expect_equal(vapply(items, has_attr, logical(1), "selected"), c(FALSE, TRUE))
})

# carbon_combobox -------------------------------------------------------------

test_that("carbon_combobox renders cds-combo-box items", {
  cb <- carbon_combobox(
    "x", "Pick",
    choices = c("a", "b"), selected = "a", size = "lg"
  )

  expect_equal(cb$name, "cds-combo-box")
  expect_equal(attr_of(cb, "title-text"), "Pick")
  expect_equal(attr_of(cb, "size"), "lg")

  items <- find_tags(cb, "cds-combo-box-item")
  expect_equal(vapply(items, attr_of, "", "value"), c("a", "b"))
  expect_equal(vapply(items, has_attr, logical(1), "selected"), c(TRUE, FALSE))
})

test_that("carbon_combobox sets its value to the selected choice", {
  expect_equal(attr_of(carbon_combobox("x", choices = c("a", "b"), selected = "b"), "value"), "b")
  expect_false(has_attr(carbon_combobox("x", choices = c("a", "b")), "value"))
})

test_that("dropdown-style inputs validate size", {
  expect_error(carbon_dropdown("x", choices = "a", size = "xl"))
  expect_error(carbon_combobox("x", choices = "a", size = "xl"))
  expect_error(carbon_multiselect("x", choices = "a", size = "xl"))
})

# carbon_multiselect ----------------------------------------------------------

test_that("carbon_multiselect joins selected values with commas", {
  ms <- carbon_multiselect(
    "tags", "Tags",
    choices = c("a", "b", "c"), selected = c("a", "c")
  )

  expect_equal(ms$name, "cds-multi-select")
  expect_equal(attr_of(ms, "value"), "a,c")

  items <- find_tags(ms, "cds-multi-select-item")
  expect_length(items, 3)
  expect_equal(vapply(items, has_attr, logical(1), "selected"), c(TRUE, FALSE, TRUE))
})

test_that("carbon_multiselect omits value when nothing is selected", {
  ms <- carbon_multiselect("tags", choices = c("a", "b"))

  expect_false(has_attr(ms, "value"))
  items <- find_tags(ms, "cds-multi-select-item")
  expect_false(any(vapply(items, has_attr, logical(1), "selected")))
})

test_that("carbon_multiselect fixes item order unless sorting is requested", {
  expect_equal(
    attr_of(carbon_multiselect("x", choices = "a"), "selection-feedback"),
    "fixed"
  )
  expect_false(
    has_attr(carbon_multiselect("x", choices = "a", sort_choices = TRUE), "selection-feedback")
  )
})

test_that("carbon_multiselect rejects choices containing commas", {
  # The binding serialises the value as a comma-separated string
  expect_error(carbon_multiselect("x", choices = c("a,b", "c")), "commas")
})
