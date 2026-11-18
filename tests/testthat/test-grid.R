test_that("carbon_grid has no row gap by default, as in Carbon", {
  html <- as.character(carbon_grid(carbon_column(width = 8, "A")))

  expect_match(html, '<div class="cds--css-grid">', fixed = TRUE)
  expect_no_match(html, "row-gap")
})

test_that("row_gap uses a step of Carbon's spacing scale", {
  html <- as.character(carbon_grid(row_gap = 7, carbon_column(width = 8, "A")))
  expect_match(html, 'style="row-gap: var(--cds-spacing-07, 2rem);"', fixed = TRUE)

  expect_match(as.character(carbon_grid(row_gap = 1)), "var(--cds-spacing-01, 0.125rem)", fixed = TRUE)
  expect_match(as.character(carbon_grid(row_gap = 13)), "var(--cds-spacing-13, 10rem)", fixed = TRUE)
})

test_that("row_gap combines with the grid's own attributes", {
  html <- as.character(carbon_grid(row_gap = 5, id = "tiles", style = "max-width: 80rem;"))

  expect_match(html, 'id="tiles"', fixed = TRUE)
  expect_match(html, 'style="row-gap: var(--cds-spacing-05, 1rem); max-width: 80rem;"', fixed = TRUE)
})

test_that("row_gap must be a spacing step", {
  for (bad in list(0, 14, 2.5, "07", c(5, 7), NA_real_)) {
    expect_error(carbon_grid(row_gap = bad), "step of Carbon's spacing scale")
  }
  expect_error(carbon_grid(row_gap = 0), class = "rlang_error")
})

# Global styles ------------------------------------------------------------------

css_file <- function(...) {
  paste(readLines(system.file("www", ..., package = "carbonite"), warn = FALSE), collapse = "\n")
}

test_that("Carbon's type classes are available", {
  css <- css_file("carbon", "carbonite.min.css")

  for (token in c("heading-06", "heading-03", "body-01", "body-02", "helper-text-01", "label-01")) {
    expect_match(css, sprintf(".cds--type-%s{", token), fixed = TRUE)
  }
  expect_match(css, ".cds--type-semibold{font-weight:600}", fixed = TRUE)
})

test_that("page content is spaced with Carbon tokens", {
  css <- css_file("carbon-page.css")

  expect_match(css, "padding-top: calc(3rem + var(--cds-spacing-07, 2rem));", fixed = TRUE)
  expect_match(css, "padding-bottom: var(--cds-spacing-07, 2rem);", fixed = TRUE)
  # carbonite doesn't restyle the app's own tables
  expect_no_match(css, "(^|\\n|\\})\\s*th\\s*\\{")
})
