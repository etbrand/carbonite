render <- function(x) as.character(htmltools::renderTags(x)$html)

find_skeleton <- function(html) {
  xml_frag <- regmatches(
    html,
    regexpr(
      '<cds-table class="carbon-table-output__skeleton"[\\s\\S]*</cds-table>',
      html,
      perl = TRUE
    )
  )
  expect_length(xml_frag, 1)
  xml_frag
}

count_matches <- function(pattern, x) {
  lengths(regmatches(x, gregexpr(pattern, x, fixed = TRUE)))
}

test_that("carbon_table_output() starts in the loading state", {
  html <- render(carbon_table_output("tbl"))

  expect_match(html, 'class="carbon-table-output carbon-table-output--loading"')
  expect_match(html, 'id="tbl"')
  expect_match(html, "carbon-table-output__table")
})

test_that("the skeleton is a sized cds-table, not cds-table-skeleton", {
  html <- render(carbon_table_output("tbl", size = "sm"))
  skeleton <- find_skeleton(html)

  expect_false(grepl("cds-table-skeleton", html, fixed = TRUE))
  expect_match(skeleton, 'size="sm"')
  expect_match(skeleton, 'aria-hidden="true"')
  expect_match(skeleton, '<cds-table-header-row size="sm">', fixed = TRUE)
  expect_match(skeleton, '<cds-table-row size="sm">', fixed = TRUE)
})

test_that("skeleton size defaults to md and is validated", {
  html <- render(carbon_table_output("tbl"))
  expect_match(find_skeleton(html), '<cds-table-row size="md">', fixed = TRUE)

  expect_error(carbon_table_output("tbl", size = "huge"))
})

test_that("skeleton uses initial_columns and initial_rows", {
  html <- render(carbon_table_output(
    "tbl",
    initial_columns = c(mpg = "MPG", cyl = "Cylinders", hp = "HP"),
    initial_rows = 2
  ))
  skeleton <- find_skeleton(html)

  expect_match(skeleton, "<cds-table-header-cell>MPG</cds-table-header-cell>")
  expect_match(skeleton, "<cds-table-header-cell>Cylinders</cds-table-header-cell>")
  expect_false(grepl("mpg", skeleton, fixed = TRUE))
  expect_equal(count_matches("<cds-table-row ", skeleton), 2)
  expect_equal(count_matches("<cds-table-cell>", skeleton), 6)
  expect_equal(count_matches("cds--skeleton__text", skeleton), 6)
})

test_that("skeleton without initial_columns shows five unlabelled columns", {
  skeleton <- find_skeleton(render(carbon_table_output("tbl")))

  expect_equal(count_matches("<cds-table-header-cell>", skeleton), 5)
  expect_equal(count_matches("<cds-table-row ", skeleton), 5)
  # 5 header placeholders + 5 x 5 body cells
  expect_equal(count_matches("cds--skeleton__text", skeleton), 30)
})

test_that("initial_rows is validated", {
  expect_error(carbon_table_output("tbl", initial_rows = -1), "initial_rows")
  expect_error(carbon_table_output("tbl", initial_rows = "a"), "initial_rows")
  expect_error(carbon_table_output("tbl", initial_rows = c(1, 2)), "initial_rows")

  skeleton <- find_skeleton(render(carbon_table_output("tbl", initial_rows = 0)))
  expect_equal(count_matches("<cds-table-row ", skeleton), 0)
})

test_that("carbon_table() sets size on the table and its rows", {
  html <- render(carbon_table(data.frame(a = 1:2, b = 3:4), size = "xs"))

  expect_match(html, '<cds-table size="xs">', fixed = TRUE)
  expect_match(html, '<cds-table-header-row size="xs">', fixed = TRUE)
  expect_equal(count_matches('<cds-table-row size="xs"', html), 2)
  expect_false(grepl("data-show-", html, fixed = TRUE))
})

test_that("numeric-like columns carry raw sort values, before formatting", {
  df <- data.frame(
    name = c("a", "b"),
    hp = c(110, 93),
    when = as.Date(c("2024-01-02", "2023-12-31")),
    grade = factor(c("low", "high"), levels = c("low", "high")),
    flag = c(TRUE, NA)
  )
  html <- render(carbon_table(
    df,
    columns = list(hp = carbon_table_column("HP", formatter = \(x) paste(x, "hp"))),
    sortable = TRUE
  ))

  expect_match(html, '<cds-table-cell data-sort-value="110">110 hp</cds-table-cell>', fixed = TRUE)
  expect_match(html, '<cds-table-cell data-sort-value="93">93 hp</cds-table-cell>', fixed = TRUE)
  # dates as days since epoch, factors by level, logicals as 0/1
  expect_match(html, sprintf('data-sort-value="%d">2024-01-02<', as.integer(as.Date("2024-01-02"))))
  expect_match(html, 'data-sort-value="2">high<', fixed = TRUE)
  expect_match(html, 'data-sort-value="1">TRUE<', fixed = TRUE)
  # NA gets no sort value (sorts last), and character columns get none
  expect_match(html, "<cds-table-cell>NA</cds-table-cell>", fixed = TRUE)
  expect_match(html, "<cds-table-cell>a</cds-table-cell>", fixed = TRUE)
  expect_equal(count_matches('data-sort-type="numeric"', html), 4)
})

test_that("sort values round-trip doubles exactly", {
  html <- render(carbon_table(data.frame(x = c(0.1, 1e10, -2.5))))

  expect_match(html, 'data-sort-value="0.10000000000000001"', fixed = TRUE)
  expect_match(html, 'data-sort-value="10000000000"', fixed = TRUE)
  expect_match(html, 'data-sort-value="-2.5"', fixed = TRUE)
})

test_that("rows are numbered in data order", {
  html <- render(carbon_table(data.frame(x = c("c", "a", "b"))))

  expect_equal(
    regmatches(html, gregexpr('data-row-index="[0-9]+"', html))[[1]],
    sprintf('data-row-index="%d"', 1:3)
  )
})
