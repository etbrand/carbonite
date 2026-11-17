render <- function(x) as.character(htmltools::renderTags(x)$html)

app_div <- function(page) {
  htmltools::tagQuery(page)$find("#carbon-app")$selectedTags()[[1]]
}

# The class of the panel with this id, from a rendered page.
panel_class <- function(page, id) {
  panel <- htmltools::tagQuery(page)$find(paste0("#", id))$selectedTags()[[1]]
  htmltools::tagGetAttribute(panel, "class")
}

test_that("carbon_page() with no content renders an empty page", {
  page <- carbon_page()
  app <- app_div(page)

  expect_s3_class(page, "shiny.tag")
  expect_null(htmltools::tagGetAttribute(app, "data-default-route"))
  expect_match(render(page), '<main id="carbon-main" class="carbon-main"></main>', fixed = TRUE)
})

test_that("carbon_page() shows non-panel content as is", {
  html <- render(carbon_page(htmltools::h1("Hello"), htmltools::p("World")))

  expect_match(html, "<h1>Hello</h1>", fixed = TRUE)
  expect_match(html, "<p>World</p>", fixed = TRUE)
  expect_false(grepl("data-default-route", html, fixed = TRUE))
})

test_that("without a sidebar: single-column layout and no menu button", {
  html <- render(carbon_page())

  expect_match(html, 'class="carbon-app carbon-app--no-sidebar"', fixed = TRUE)
  expect_false(grepl("cds-header-menu-button", html, fixed = TRUE))
})

test_that("with a sidebar: two-column layout and a menu button", {
  html <- render(carbon_page(sidebar = carbon_sidebar(carbon_nav_item("a", "A"))))

  expect_match(html, 'class="carbon-app"', fixed = TRUE)
  expect_match(html, "<cds-header-menu-button>", fixed = TRUE)
})

test_that("the first panel is the default route and starts active", {
  page <- carbon_page(
    htmltools::h1("Always shown"),
    carbon_panel("a", "A"),
    carbon_panel("b", "B")
  )

  expect_match(render(page), 'data-default-route="a"', fixed = TRUE)
  expect_equal(panel_class(page, "a"), "carbon-panel active")
  expect_equal(panel_class(page, "b"), "carbon-panel")
})

test_that("default_route picks the active panel", {
  page <- carbon_page(carbon_panel("a", "A"), carbon_panel("b", "B"), default_route = "b")

  expect_match(render(page), 'data-default-route="b"', fixed = TRUE)
  expect_equal(panel_class(page, "b"), "carbon-panel active")
  expect_equal(panel_class(page, "a"), "carbon-panel")
})

test_that("panels inside a tagList are found", {
  page <- carbon_page(htmltools::tagList(carbon_panel("x", "X"), carbon_panel("y", "Y")))

  expect_match(render(page), 'data-default-route="x"', fixed = TRUE)
  expect_equal(panel_class(page, "x"), "carbon-panel active")
  expect_equal(panel_class(page, "y"), "carbon-panel")
})

test_that("NULL content is ignored", {
  page <- carbon_page(NULL, carbon_panel("a", "A"), NULL)

  expect_equal(panel_class(page, "a"), "carbon-panel active")
})

test_that("carbon_page() validates panels and default_route", {
  expect_error(carbon_page(carbon_panel("a", "1"), carbon_panel("a", "2")), "unique")
  expect_error(carbon_page(carbon_panel("a", "A"), default_route = "zzz"), "default_route")
  expect_error(carbon_page(default_route = "a"), "no panels")
})
