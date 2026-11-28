render <- function(x) as.character(htmltools::renderTags(x)$html)

switcher_of <- function(x) {
  if (inherits(x, "shiny.tag.list")) x[[1]] else x
}

test_that("without content, the switcher is a single tag selecting the first option", {
  cs <- carbon_content_switcher(
    "view",
    carbon_switch("chart", "Chart"),
    carbon_switch("table", "Table")
  )

  expect_s3_class(cs, "shiny.tag")
  expect_equal(cs$name, "cds-content-switcher")
  expect_equal(attr_of(cs, "id"), "view")
  expect_equal(attr_of(cs, "value"), "chart")
  expect_equal(attr_of(cs, "selected-index"), "0")
  expect_false(has_attr(cs, "size"))
  expect_false(has_attr(cs, "low-contrast"))

  items <- find_tags(cs, "cds-content-switcher-item")
  expect_equal(vapply(items, attr_of, character(1), "value"), c("chart", "table"))
  expect_equal(vapply(items, has_attr, logical(1), "selected"), c(TRUE, FALSE))
  expect_false(has_attr(items[[1]], "target"))
  label <- find_tags(items[[2]], "span")[[1]]
  expect_equal(attr_of(label, "class"), "carbonite-switch-label")
  expect_equal(label$children[[1]], "Table")
})

test_that("options with content get panels, with the others hidden", {
  cs <- carbon_content_switcher(
    "view",
    carbon_switch("chart", "Chart", htmltools::p("A chart")),
    carbon_switch("table", "Table", htmltools::p("A table")),
    carbon_switch("notes", "Notes"),
    selected = "table"
  )

  expect_s3_class(cs, "shiny.tag.list")
  items <- find_tags(cs[[1]], "cds-content-switcher-item")
  expect_equal(vapply(items, attr_of, character(1), "target"), paste0("view-panel-", 1:3))

  panels <- cs[[2]]
  expect_length(panels, 3)
  expect_equal(vapply(panels, attr_of, character(1), "id"), paste0("view-panel-", 1:3))
  expect_equal(vapply(panels, has_attr, logical(1), "hidden"), c(TRUE, FALSE, TRUE))
  expect_equal(attr_of(panels[[1]], "role"), "tabpanel")
  expect_match(render(panels[[2]]), "<p>A table</p>", fixed = TRUE)
})

test_that("selected-index counts only enabled options", {
  cs <- carbon_content_switcher(
    "s",
    carbon_switch("a", disabled = TRUE),
    carbon_switch("b"),
    carbon_switch("c"),
    selected = "c"
  )

  expect_equal(attr_of(cs, "value"), "c")
  expect_equal(attr_of(cs, "selected-index"), "1")
  expect_true(has_attr(find_tags(cs, "cds-content-switcher-item")[[1]], "disabled"))

  # Default: the first enabled option
  default <- carbon_content_switcher("s", carbon_switch("a", disabled = TRUE), carbon_switch("b"))
  expect_equal(attr_of(default, "value"), "b")
  expect_equal(attr_of(default, "selected-index"), "0")
})

test_that("icon options show an icon, with the label as tooltip", {
  cs <- carbon_content_switcher(
    "layout",
    carbon_switch("list", "List view", icon = "list"),
    carbon_switch("grid", "Grid view", icon = "grid"),
    size = "sm",
    low_contrast = TRUE
  )

  expect_equal(attr_of(cs, "size"), "sm")
  expect_true(has_attr(cs, "low-contrast"))

  item <- find_tags(cs, "cds-content-switcher-item")[[1]]
  expect_true(has_attr(item, "icon"))
  expect_length(find_tags(item, "svg"), 1)
  expect_null(attr_of(find_tags(item, "svg")[[1]], "slot"))
  expect_match(render(item), '<span slot="tooltip-content">List view</span>', fixed = TRUE)
})

test_that("carbon_switch validates", {
  expect_error(carbon_switch(""), "value")
  expect_error(carbon_switch(1), "value")
  expect_error(carbon_switch("a", disabled = "no"), "disabled")
  expect_equal(carbon_switch("a")$label, "a")
})

test_that("carbon_content_switcher validates its options and selection", {
  a <- carbon_switch("a")
  b <- carbon_switch("b")

  expect_error(carbon_content_switcher("s", a), "at least two")
  expect_error(carbon_content_switcher("s", a, htmltools::div()), "carbon_switch")
  expect_error(carbon_content_switcher("s", a, carbon_switch("a")), "unique")
  expect_error(carbon_content_switcher("s", a, carbon_switch("b", icon = "grid")), "icon")
  expect_error(carbon_content_switcher("s", carbon_switch("a", disabled = TRUE), carbon_switch("b", disabled = TRUE)), "enabled")
  expect_error(carbon_content_switcher("s", a, b, selected = "z"), "one of")
  expect_error(carbon_content_switcher("s", a, carbon_switch("b", disabled = TRUE), selected = "b"), "disabled")
  expect_error(carbon_content_switcher("s", a, b, size = "xl"))
  expect_error(carbon_content_switcher("s", a, b, low_contrast = NA), "low_contrast")
  expect_no_error(carbon_content_switcher("s", a, NULL, b))
})

test_that("the switcher attaches the carbon dependency", {
  deps <- htmltools::findDependencies(carbon_content_switcher("s", carbon_switch("a"), carbon_switch("b")))
  expect_true("carbon" %in% vapply(deps, `[[`, character(1), "name"))
})

test_that("update_carbon_content_switcher sends the value", {
  session <- fake_session()
  msg <- capture_input_message(update_carbon_content_switcher("view", "table", session = session), session)

  expect_equal(msg$id, "view")
  expect_equal(msg$message, list(value = "table"))
  expect_error(update_carbon_content_switcher("view", c("a", "b"), session = fake_session()), "single string")
})
