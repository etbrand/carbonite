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

test_that("with a rail sidebar: rail layout class and collapse-mode", {
  page <- carbon_page(sidebar = carbon_sidebar(carbon_nav_item("a", "A", icon = "home"), rail = TRUE))
  html <- render(page)

  expect_match(html, 'class="carbon-app carbon-app--rail"', fixed = TRUE)
  expect_match(html, '<cds-side-nav id="carbon-sidebar" collapse-mode="rail">', fixed = TRUE)
})

test_that("carbon_sidebar() is not a rail by default and validates rail", {
  html <- render(carbon_sidebar(carbon_nav_item("a", "A")))

  expect_false(grepl("collapse-mode", html, fixed = TRUE))
  expect_error(carbon_sidebar(rail = "yes"), "rail")
})

test_that("carbon_nav_item() puts its icon in the title-icon slot", {
  item <- carbon_nav_item("home", "Home", icon = "home")
  svg <- htmltools::tagQuery(item)$find("svg")$selectedTags()[[1]]

  expect_equal(htmltools::tagGetAttribute(svg, "slot"), "title-icon")
  expect_match(render(item), "</svg>\\s*Home\\s*</cds-side-nav-link>")

  custom <- carbon_nav_item("home", "Home", icon = carbon_icon("home", class = "x"))
  expect_match(render(custom), 'slot="title-icon"', fixed = TRUE)

  expect_false(grepl("<svg", render(carbon_nav_item("home", "Home")), fixed = TRUE))
  expect_error(carbon_nav_item("home", "Home", icon = "not-an-icon"), "Unknown Carbon icon")
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

test_that("carbon_page puts header_content on the right of the header", {
  page <- carbon_page(
    carbon_panel("home", "Home"),
    header_content = carbon_select("region", choices = c("A", "B"), size = "sm")
  )

  header <- find_tags(page, "cds-header")[[1]]
  area <- find_tags(header, ".carbonite-header-content")
  expect_length(area, 1)
  expect_length(find_tags(area[[1]], "cds-select#region"), 1)
  expect_length(find_tags(carbon_page(carbon_panel("home", "Home")), ".carbonite-header-content"), 0)
})
