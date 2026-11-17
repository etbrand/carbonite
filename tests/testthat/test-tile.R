render <- function(x) as.character(htmltools::renderTags(x)$html)

test_that("carbon_tile() renders a cds-tile with its content", {
  html <- render(carbon_tile(htmltools::h4("Revenue"), "text", id = "t1"))

  expect_match(html, '^<cds-tile id="t1">')
  expect_match(html, "<h4>Revenue</h4>", fixed = TRUE)
  expect_match(html, "text\\s*</cds-tile>$")
})

test_that("carbon_tile() passes named arguments through as attributes", {
  html <- render(carbon_tile("x", class = "kpi", style = "height: 8rem"))

  expect_match(html, 'class="kpi"', fixed = TRUE)
  expect_match(html, 'style="height: 8rem"', fixed = TRUE)
})

test_that("carbon_tile(href = ) renders a clickable tile link", {
  html <- render(carbon_tile("Docs", href = "https://example.com", target = "_blank"))

  expect_match(html, "^<cds-clickable-tile ")
  expect_match(html, 'href="https://example.com"', fixed = TRUE)
  expect_match(html, 'target="_blank"', fixed = TRUE)
  expect_false(grepl("<cds-tile", html, fixed = TRUE))
})

test_that("carbon_tile() validates href", {
  expect_error(carbon_tile("x", href = 1), "href")
  expect_error(carbon_tile("x", href = c("a", "b")), "href")
})

test_that("carbon_expandable_tile() slots summary and body content", {
  html <- render(carbon_expandable_tile(
    htmltools::h4("Summary"),
    htmltools::p("Details"),
    "more"
  ))

  expect_match(html, "^<cds-expandable-tile>")
  expect_match(
    html,
    '<cds-tile-above-the-fold-content slot="above-the-fold-content">\\s*<h4>Summary</h4>\\s*</cds-tile-above-the-fold-content>'
  )
  expect_match(
    html,
    "<cds-tile-below-the-fold-content>\\s*<p>Details</p>\\s*more\\s*</cds-tile-below-the-fold-content>"
  )
  expect_false(grepl("expanded", html, fixed = TRUE))
  expect_false(grepl("with-interactive", html, fixed = TRUE))
})

test_that("carbon_expandable_tile() sets expanded and with-interactive", {
  html <- render(carbon_expandable_tile("S", "B", expanded = TRUE, interactive = TRUE))

  expect_match(html, "<cds-expandable-tile expanded with-interactive>", fixed = TRUE)
})

test_that("carbon_expandable_tile() puts named arguments on the tile", {
  html <- render(carbon_expandable_tile("S", "B", class = "wide", id = "et"))

  expect_match(html, '<cds-expandable-tile id="et" class="wide">', fixed = TRUE)
  expect_match(html, "<cds-tile-below-the-fold-content>B</cds-tile-below-the-fold-content>", fixed = TRUE)
})

test_that("carbon_expandable_tile() validates flags", {
  expect_error(carbon_expandable_tile("S", expanded = "yes"), "expanded")
  expect_error(carbon_expandable_tile("S", interactive = NA), "interactive")
})
