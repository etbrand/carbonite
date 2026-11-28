render <- function(x) as.character(htmltools::renderTags(x)$html)

test_that("carbon_accordion_item() renders title slot and content", {
  html <- render(carbon_accordion_item(
    "Overview",
    htmltools::p("Body"),
    id = "ov"
  ))

  expect_match(html, '^<cds-accordion-item id="ov">')
  expect_match(html, '<span slot="title">Overview</span>', fixed = TRUE)
  expect_match(html, "<p>Body</p>", fixed = TRUE)
  # title goes in the slot, not the tooltip-producing attribute
  expect_false(grepl(' title="', html, fixed = TRUE))
  expect_false(grepl("open", html, fixed = TRUE))
  expect_false(grepl("disabled", html, fixed = TRUE))
})

test_that("carbon_accordion_item() accepts UI as the title", {
  html <- render(carbon_accordion_item(htmltools::strong("Bold"), "x"))

  expect_match(html, '<span slot="title">\\s*<strong>Bold</strong>\\s*</span>')
})

test_that("carbon_accordion_item() sets open, disabled and attributes", {
  html <- render(carbon_accordion_item("T", "x", open = TRUE, disabled = TRUE, class = "c"))

  expect_match(html, "<cds-accordion-item open disabled class=\"c\">", fixed = TRUE)
})

test_that("carbon_accordion_item() validates flags", {
  expect_error(carbon_accordion_item("T", open = "yes"), "open")
  expect_error(carbon_accordion_item("T", disabled = NA), "disabled")
})

test_that("carbon_accordion() wraps items with size, alignment and flush", {
  html <- render(carbon_accordion(
    carbon_accordion_item("A", "a"),
    carbon_accordion_item("B", "b"),
    size = "sm",
    align = "start",
    flush = TRUE,
    id = "acc",
    class = "wide"
  ))

  expect_match(
    html,
    '^<cds-accordion id="acc" size="sm" alignment="start" isflush class="wide">'
  )
  expect_equal(lengths(regmatches(html, gregexpr("<cds-accordion-item", html))), 2)
})

test_that("carbon_accordion() defaults to md, end, not flush", {
  html <- render(carbon_accordion(carbon_accordion_item("A", "a")))

  expect_match(html, '^<cds-accordion size="md" alignment="end">')
  expect_false(grepl("isflush", html, fixed = TRUE))
})

test_that("carbon_accordion() validates its arguments", {
  item <- carbon_accordion_item("A", "a")

  expect_error(carbon_accordion(), "at least one")
  expect_error(carbon_accordion(item, htmltools::p("x")), "carbon_accordion_item")
  expect_error(carbon_accordion(item, "text"), "carbon_accordion_item")
  expect_error(carbon_accordion(item, size = "xl"))
  expect_error(carbon_accordion(item, align = "middle"))
  expect_error(carbon_accordion(item, flush = "no"), "flush")
})
