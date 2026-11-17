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

# Header, toolbar and selection ------------------------------------------------

cars <- head(mtcars[, c("mpg", "cyl")], 3)

test_that("title and description go in Carbon's header slots", {
  html <- render(carbon_table(cars, title = "Cars", description = "From mtcars"))

  expect_match(html, '<cds-table-header-title slot="title">Cars</cds-table-header-title>', fixed = TRUE)
  expect_match(html, '<cds-table-header-description slot="description">From mtcars</cds-table-header-description>', fixed = TRUE)
})

test_that("no header or toolbar markup by default", {
  html <- render(carbon_table(cars))

  expect_false(grepl("cds-table-header-title|cds-table-toolbar|is-selectable|selection-name", html))
})

test_that("carbon_table_toolbar() renders search, content and batch actions", {
  html <- render(carbon_table(
    cars,
    size = "sm",
    selection = "multiple",
    toolbar = carbon_table_toolbar(
      carbon_button("add", "Add"),
      search_placeholder = "Find",
      batch_actions = list(carbon_button("del", "Delete"))
    )
  ))

  expect_match(html, '<cds-table-toolbar slot="toolbar" size="sm">', fixed = TRUE)
  expect_match(html, '<cds-table-batch-actions>\\s*<cds-button[^>]*id="del"')
  expect_match(html, '<cds-table-toolbar-search persistent placeholder="Find" size="sm"></cds-table-toolbar-search>', fixed = TRUE)
  expect_match(html, '<cds-table-toolbar-content size="sm">[\\s\\S]*id="add"', perl = TRUE)
})

test_that("toolbar size maps md/xl to lg and search can be turned off", {
  html <- render(carbon_table(cars, size = "md", toolbar = carbon_table_toolbar(search = FALSE)))

  expect_match(html, '<cds-table-toolbar slot="toolbar" size="lg">', fixed = TRUE)
  expect_false(grepl("cds-table-toolbar-search", html, fixed = TRUE))
  expect_false(grepl("cds-table-batch-actions", html, fixed = TRUE))
})

test_that("toolbar and batch actions are validated", {
  expect_error(carbon_table(cars, toolbar = list()), "carbon_table_toolbar")
  expect_error(carbon_table_toolbar(search = "yes"), "search")
  expect_error(
    carbon_table(cars, toolbar = carbon_table_toolbar(batch_actions = list("x"))),
    "multiple"
  )
})

test_that("multiple selection marks the table and keys rows by row number", {
  html <- render(carbon_table(cars, selection = "multiple", selected = c(1, 3), id = "t"))

  expect_match(html, '<cds-table id="t" size="md" is-selectable class="carbonite-selectable-table" data-row-key-type="index">', fixed = TRUE)
  expect_false(grepl(" radio", html, fixed = TRUE))
  expect_match(html, 'data-row-index="1" data-row-key="1" selection-name="1" selected>', fixed = TRUE)
  expect_match(html, 'data-row-index="2" data-row-key="2" selection-name="2">', fixed = TRUE)
  expect_match(html, 'data-row-index="3" data-row-key="3" selection-name="3" selected>', fixed = TRUE)
})

test_that("single selection uses radios and row_key values", {
  df <- data.frame(id = c("a", "b"), x = 1:2)
  html <- render(carbon_table(df, selection = "single", row_key = "id", selected = "b"))

  expect_match(html, "is-selectable radio", fixed = TRUE)
  expect_match(html, 'data-row-key-type="key"', fixed = TRUE)
  expect_match(html, 'data-row-key="b" selection-name="b" selected>', fixed = TRUE)
})

test_that("rows always carry their key, even without selection", {
  html <- render(carbon_table(cars))

  expect_match(html, 'data-row-key="2"', fixed = TRUE)
  expect_false(grepl("selection-name|data-row-key-type", html))
})

test_that("selected is validated", {
  df <- data.frame(id = c("a", "b"), x = 1:2)

  expect_error(carbon_table(cars, selected = 1), "selection")
  expect_error(carbon_table(cars, selection = "multiple", selected = 9), "Unknown")
  expect_error(carbon_table(df, selection = "multiple", row_key = "id", selected = 1), "Unknown")
  expect_error(carbon_table(cars, selection = "single", selected = 1:2), "single row")
  expect_error(carbon_table(cars, selection = "maybe"))
})

# Pagination ------------------------------------------------------------------

test_that("without page_size the table isn't wrapped or paginated", {
  tbl <- carbon_table(data.frame(x = 1:30))

  expect_equal(tbl$name, "cds-table")
  expect_false(grepl("data-page-hidden|cds-pagination", render(tbl)))
})

test_that("page_size wraps the table with a pagination bar and hides later rows", {
  df <- data.frame(x = 1:12)
  tbl <- carbon_table(df, page_size = 5, id = "t", class = "wide")

  expect_equal(tbl$name, "div")
  expect_equal(attr_of(tbl, "class"), "carbonite-paginated-table")

  table <- find_tags(tbl, "cds-table")[[1]]
  expect_equal(attr_of(table, "id"), "t")
  expect_equal(attr_of(table, "class"), "wide")

  rows <- find_tags(tbl, "cds-table-row")
  hidden <- vapply(rows, has_attr, logical(1), "data-page-hidden")
  expect_equal(hidden, rep(c(FALSE, TRUE), c(5, 7)))

  pagination <- find_tags(tbl, "cds-pagination")
  expect_length(pagination, 1)
  expect_equal(attr_of(pagination[[1]], "page"), "1")
  expect_equal(attr_of(pagination[[1]], "page-size"), "5")
  expect_equal(attr_of(pagination[[1]], "total-items"), "12")
  expect_equal(attr_of(pagination[[1]], "size"), "md")
})

test_that("page_sizes become the pagination's options, including page_size", {
  tbl <- carbon_table(data.frame(x = 1:3), page_size = 15, page_sizes = c(50, 10))
  items <- find_tags(tbl, "cds-pagination > cds-select-item")

  expect_equal(vapply(items, attr_of, character(1), "value"), c("10", "15", "50"))
  expect_match(render(items[[2]]), ">15</cds-select-item>", fixed = TRUE)
})

test_that("the pagination bar follows the table size", {
  size_of <- function(size) {
    tbl <- carbon_table(data.frame(x = 1), page_size = 10, size = size)
    attr_of(find_tags(tbl, "cds-pagination")[[1]], "size")
  }

  expect_equal(vapply(c("xs", "sm", "md", "lg", "xl"), size_of, character(1)),
    c(xs = "sm", sm = "sm", md = "md", lg = "lg", xl = "lg"))
})

test_that("pagination works with selection, a toolbar, and an empty table", {
  tbl <- carbon_table(
    data.frame(x = 1:4), page_size = 2, selection = "multiple", selected = 4,
    toolbar = carbon_table_toolbar()
  )
  rows <- find_tags(tbl, "cds-table-row")

  expect_true(has_attr(rows[[4]], "selected"))
  expect_true(has_attr(rows[[4]], "data-page-hidden"))
  expect_length(find_tags(tbl, "cds-table-toolbar"), 1)

  empty <- carbon_table(data.frame(x = numeric()), page_size = 10)
  expect_equal(attr_of(find_tags(empty, "cds-pagination")[[1]], "total-items"), "0")
})

test_that("page_size and page_sizes are validated", {
  df <- data.frame(x = 1)

  expect_error(carbon_table(df, page_size = 0), "page_size")
  expect_error(carbon_table(df, page_size = 2.5), "page_size")
  expect_error(carbon_table(df, page_size = c(5, 10)), "page_size")
  expect_error(carbon_table(df, page_size = "10"), "page_size")
  expect_error(carbon_table(df, page_size = 10, page_sizes = c(5, NA)), "page_sizes")
  expect_error(carbon_table(df, page_size = 10, page_sizes = numeric()), "page_sizes")
})

# Expandable rows ----------------------------------------------------------------

body_children <- function(tbl) {
  table <- if (tbl$name == "cds-table") tbl else find_tags(tbl, "cds-table")[[1]]
  find_tags(table, "cds-table-body")[[1]]$children
}

test_that("without row_details there are no expanded rows", {
  tbl <- carbon_table(data.frame(x = 1:3))

  expect_false(has_attr(tbl, "expandable"))
  expect_length(find_tags(tbl, "cds-table-expanded-row"), 0)
})

test_that("row_details as a vector: each row is followed by its expanded row", {
  tbl <- carbon_table(data.frame(x = 1:3), row_details = c("one", NA, ""))

  expect_true(has_attr(tbl, "expandable"))
  expect_false(has_attr(tbl, "batch-expansion"))

  kids <- body_children(tbl)
  expect_equal(
    vapply(kids, `[[`, character(1), "name"),
    rep(c("cds-table-row", "cds-table-expanded-row"), 3)
  )
  expect_equal(vapply(kids[c(2, 4, 6)], attr_of, character(1), "data-expands-row"), c("1", "2", "3"))
  expect_equal(kids[[2]]$children[[1]], "one")
  # NA and "" mean no details: an empty placeholder, which Carbon's search needs
  expect_equal(vapply(kids[c(2, 4, 6)], has_attr, logical(1), "data-empty"), c(FALSE, TRUE, TRUE))
})

test_that("row_details as a function gets each row and can return UI or NULL", {
  df <- data.frame(name = c("a", "b"), n = c(1, 2))
  tbl <- carbon_table(
    df,
    row_details = function(row) if (row$n > 1) htmltools::p("Row", row$name),
    expand_all = TRUE
  )

  expect_true(has_attr(tbl, "batch-expansion"))
  details <- find_tags(tbl, "cds-table-expanded-row")
  expect_true(has_attr(details[[1]], "data-empty"))
  expect_false(has_attr(details[[2]], "data-empty"))
  expect_match(as.character(details[[2]]), "<p>\\s*Row\\s*b\\s*</p>")
})

test_that("row_details as a list holds tags", {
  tbl <- carbon_table(
    data.frame(x = 1:2),
    row_details = list(htmltools::strong("bold"), NULL)
  )
  details <- find_tags(tbl, "cds-table-expanded-row")

  expect_match(as.character(details[[1]]), "<strong>bold</strong>", fixed = TRUE)
  expect_true(has_attr(details[[2]], "data-empty"))
})

test_that("expanded rows of rows off the first page start hidden too", {
  tbl <- carbon_table(data.frame(x = 1:4), page_size = 2, row_details = letters[1:4])
  details <- find_tags(tbl, "cds-table-expanded-row")

  expect_equal(vapply(details, has_attr, logical(1), "data-page-hidden"), c(FALSE, FALSE, TRUE, TRUE))
})

test_that("row_details works with selection", {
  tbl <- carbon_table(data.frame(x = 1:2), selection = "multiple", row_details = c("a", "b"))

  expect_true(has_attr(tbl, "expandable"))
  expect_true(has_attr(tbl, "is-selectable"))
  expect_length(find_tags(tbl, "cds-table-row"), 2)
})

test_that("row_details and expand_all are validated", {
  df <- data.frame(x = 1:3)

  expect_error(carbon_table(df, row_details = c("a", "b")), "one element per row")
  expect_error(carbon_table(df, row_details = htmltools::p("x")), "function of a row")
  expect_error(carbon_table(df, expand_all = TRUE), "row_details")
  expect_error(carbon_table(df, row_details = letters[1:3], expand_all = "yes"), "expand_all")
})

# Lazy row details --------------------------------------------------------------

test_that("lazy_details renders placeholders without calling row_details", {
  calls <- 0
  df <- data.frame(name = c("a", "b"), notes = c("x", "y"))
  tbl <- carbon_table(
    df,
    columns = list(name = "Name"),
    row_details = function(row) { calls <<- calls + 1; row$notes },
    lazy_details = TRUE
  )

  expect_equal(calls, 0)
  expect_true(has_attr(tbl, "expandable"))
  expect_match(attr_of(tbl, "data-lazy-details"), "^lazy-[0-9]+$")

  details <- find_tags(tbl, "cds-table-expanded-row")
  expect_true(all(vapply(details, has_attr, logical(1), "data-lazy")))
  expect_false(any(vapply(details, has_attr, logical(1), "data-empty")))
  expect_match(as.character(details[[1]]), "carbonite-details-loading", fixed = TRUE)

  # The function and the full data (including columns not shown) go to
  # render_carbon_table()
  lazy <- attr(tbl, "carbonite_lazy_details")
  expect_identical(lazy$data, df)
  expect_equal(lazy$token, attr_of(tbl, "data-lazy-details"))
})

test_that("each lazy table gets a new token; paginated tables keep the attribute", {
  df <- data.frame(x = 1:4)
  a <- carbon_table(df, row_details = function(row) "a", lazy_details = TRUE, page_size = 2)
  b <- carbon_table(df, row_details = function(row) "b", lazy_details = TRUE)

  expect_false(identical(attr(a, "carbonite_lazy_details")$token, attr(b, "carbonite_lazy_details")$token))
  expect_true(has_attr(find_tags(a, "cds-table")[[1]], "data-lazy-details"))
  expect_null(attr(carbon_table(df), "carbonite_lazy_details"))
})

test_that("lazy_details is validated", {
  df <- data.frame(x = 1:2)

  expect_error(carbon_table(df, row_details = c("a", "b"), lazy_details = TRUE), "function of a row")
  expect_error(carbon_table(df, lazy_details = TRUE), "function of a row")
  expect_error(carbon_table(df, row_details = function(row) "a", lazy_details = "yes"), "lazy_details")
})

# A stand-in session that records custom messages
fake_message_session <- function() {
  session <- new.env()
  session$messages <- list()
  session$sendCustomMessage <- function(type, message) {
    session$messages[[length(session$messages) + 1]] <- list(type = type, message = message)
  }
  session
}

lazy_table <- function(fn, data = data.frame(name = c("a", "b", "c"), notes = c("x", "", "z"))) {
  attr(carbon_table(data[, "name", drop = FALSE], row_details = fn, lazy_details = TRUE), "carbonite_lazy_details") |>
    utils::modifyList(list(data = data))
}

test_that("requested rows' details are built and sent", {
  session <- fake_message_session()
  lazy <- lazy_table(function(row) if (nzchar(row$notes)) htmltools::p("Notes:", row$notes))

  .send_lazy_details(session, "tbl", lazy, list(token = lazy$token, rows = list(1, 2, 99)))

  expect_length(session$messages, 1)
  msg <- session$messages[[1]]
  expect_equal(msg$type, "carbonite-table-details")
  expect_equal(msg$message$table, "tbl")
  expect_equal(msg$message$token, lazy$token)

  sent <- msg$message$details
  expect_equal(vapply(sent, `[[`, integer(1), "row"), c(1L, 2L))  # 99 doesn't exist
  expect_match(sent[[1]]$html, "<p>\\s*Notes:\\s*x\\s*</p>")
  expect_false(sent[[1]]$empty)
  expect_true(sent[[2]]$empty)  # notes was ""
})

test_that("details dependencies are sent with them", {
  session <- fake_message_session()
  dep <- htmltools::htmlDependency("mydep", "1.0", src = c(href = "https://example.com"), script = "my.js")
  lazy <- lazy_table(function(row) htmltools::attachDependencies(htmltools::span("x"), dep))

  .send_lazy_details(session, "tbl", lazy, list(token = lazy$token, rows = list(1)))

  deps <- session$messages[[1]]$message$details[[1]]$deps
  expect_equal(vapply(deps, `[[`, "", "name"), "mydep")
})

test_that("a failing row_details shows an error and warns, without stopping", {
  session <- fake_message_session()
  lazy <- lazy_table(function(row) if (row$name == "b") stop("boom") else "ok")

  expect_warning(
    .send_lazy_details(session, "tbl", lazy, list(token = lazy$token, rows = list(1, 2))),
    "boom"
  )

  sent <- session$messages[[1]]$message$details
  expect_match(sent[[1]]$html, "ok", fixed = TRUE)
  expect_match(sent[[2]]$html, "couldn't be loaded", fixed = TRUE)
})

test_that("requests for an earlier render are ignored", {
  session <- fake_message_session()
  lazy <- lazy_table(function(row) "x")

  .send_lazy_details(session, "tbl", lazy, list(token = "lazy-0", rows = list(1)))

  expect_length(session$messages, 0)
})

test_that("render_carbon_table answers requests with the latest render", {
  requests <- list()
  local_mocked_bindings(.send_lazy_details = function(session, base, lazy, request) {
    requests[[length(requests) + 1]] <<- list(base = base, token = lazy$token, request = request)
  })

  server <- function(input, output, session) {
    n <- shiny::reactiveVal(2)
    output$tbl <- render_carbon_table({
      carbon_table(data.frame(x = seq_len(n())), row_details = function(row) row$x, lazy_details = TRUE)
    })
    shiny::observeEvent(input$more, n(3))
  }

  shiny::testServer(server, {
    output$tbl
    first <- session$userData$carbonite_lazy_details$tbl$token
    session$setInputs(tbl_details_request = list(token = first, rows = list(1)))

    session$setInputs(more = 1)
    output$tbl
    second <- session$userData$carbonite_lazy_details$tbl$token
    session$setInputs(tbl_details_request = list(token = second, rows = list(3)))

    expect_false(identical(first, second))
    # One observer: one call per request, each with the render current then
    expect_length(requests, 2)
    expect_equal(requests[[1]]$base, "tbl")
    expect_equal(requests[[1]]$token, first)
    expect_equal(requests[[2]]$token, second)
  })
})

test_that("a row_details function with a second argument gets the row number", {
  notes <- c("first", "second")
  eager <- carbon_table(data.frame(x = 1:2), row_details = function(row, i) notes[i])
  expect_equal(find_tags(eager, "cds-table-expanded-row")[[2]]$children[[1]], "second")

  session <- fake_message_session()
  lazy <- attr(
    carbon_table(data.frame(x = 1:2), row_details = function(row, i) notes[i], lazy_details = TRUE),
    "carbonite_lazy_details"
  )
  .send_lazy_details(session, "tbl", lazy, list(token = lazy$token, rows = list(2)))
  expect_match(session$messages[[1]]$message$details[[1]]$html, "second", fixed = TRUE)
})
