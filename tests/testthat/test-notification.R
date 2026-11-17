render <- function(x) as.character(htmltools::renderTags(x)$html)

# carbon_inline_notification ---------------------------------------------------

test_that("carbon_inline_notification puts title and subtitle in Carbon's slots", {
  n <- carbon_inline_notification("Saved", "All changes saved.", kind = "success", id = "n1")

  expect_equal(n$name, "cds-inline-notification")
  expect_equal(attr_of(n, "kind"), "success")
  expect_equal(attr_of(n, "id"), "n1")
  # Not as attributes: a `title` attribute would add a browser tooltip
  expect_false(has_attr(n, "title"))
  expect_false(has_attr(n, "subtitle"))
  expect_false(has_attr(n, "hide-close-button"))
  expect_false(has_attr(n, "low-contrast"))

  expect_match(render(n), '<span slot="title">Saved</span>', fixed = TRUE)
  expect_match(render(n), '<span slot="subtitle">All changes saved.</span>', fixed = TRUE)
})

test_that("carbon_inline_notification options", {
  n <- carbon_inline_notification(
    htmltools::strong("Read only"), close_button = FALSE, low_contrast = TRUE
  )

  expect_equal(attr_of(n, "kind"), "info")
  expect_true(has_attr(n, "hide-close-button"))
  expect_true(has_attr(n, "low-contrast"))
  expect_false(grepl('slot="subtitle"', render(n), fixed = TRUE))
  expect_match(render(n), '<span slot="title">\\s*<strong>Read only</strong>')

  expect_error(carbon_inline_notification("x", kind = "danger"))
  expect_error(carbon_inline_notification("x", close_button = "no"), "close_button")
  expect_error(carbon_inline_notification("x", low_contrast = NA), "low_contrast")
})

# show_carbon_notification -----------------------------------------------------

test_that("show_carbon_notification inserts a toast at the end of <body>", {
  session <- ui_session()
  id <- show_carbon_notification(
    "Saved", "All changes saved.", kind = "success", caption = "12:00",
    session = session
  )

  expect_match(id, "^carbonite-notification-[0-9a-f]{12}$")
  expect_length(session$sent, 1)

  insert <- session$sent[[1]]
  expect_equal(insert$type, "insert")
  expect_equal(insert$selector, "body")
  expect_equal(insert$where, "beforeEnd")

  html <- insert$html
  expect_match(html, paste0('^<cds-toast-notification kind="success" id="', id, '" class="carbonite-toast" timeout="5000">'))
  expect_match(html, '<span slot="title">Saved</span>', fixed = TRUE)
  expect_match(html, '<span slot="subtitle">All changes saved.</span>', fixed = TRUE)
  expect_match(html, '<span slot="caption">12:00</span>', fixed = TRUE)
})

test_that("show_carbon_notification: no timeout with duration = NULL, and options", {
  session <- ui_session()
  show_carbon_notification(
    "Working", duration = NULL, close_button = FALSE, low_contrast = TRUE,
    session = session
  )
  html <- session$sent[[1]]$html

  expect_false(grepl("timeout", html, fixed = TRUE))
  expect_match(html, 'kind="info" hide-close-button low-contrast', fixed = TRUE)
  expect_false(grepl("caption|subtitle", html))

  session <- ui_session()
  show_carbon_notification("Quick", duration = 0.25, session = session)
  expect_match(session$sent[[1]]$html, 'timeout="250"', fixed = TRUE)
})

test_that("show_carbon_notification with an id replaces the one showing", {
  session <- ui_session()
  id <- show_carbon_notification("Step 2 of 3", id = "progress", session = session)

  expect_equal(id, "progress")
  expect_length(session$sent, 2)
  expect_equal(session$sent[[1]], list(type = "remove", selector = "#progress", multiple = FALSE))
  expect_match(session$sent[[2]]$html, 'id="progress"', fixed = TRUE)
})

test_that("generated ids differ", {
  session <- ui_session()
  ids <- replicate(5, show_carbon_notification("x", session = session))

  expect_equal(anyDuplicated(ids), 0)
})

test_that("show_carbon_notification validates its arguments", {
  session <- ui_session()

  expect_error(show_carbon_notification("x", duration = 0, session = session), "duration")
  expect_error(show_carbon_notification("x", duration = "5", session = session), "duration")
  expect_error(show_carbon_notification("x", duration = c(1, 2), session = session), "duration")
  expect_error(show_carbon_notification("x", id = "has space", session = session), "id")
  expect_error(show_carbon_notification("x", id = "1abc", session = session), "id")
  expect_error(show_carbon_notification("x", kind = "danger", session = session))
  expect_length(session$sent, 0)
})

test_that("remove_carbon_notification removes by id", {
  session <- ui_session()
  remove_carbon_notification("progress", session = session)

  expect_equal(session$sent, list(list(type = "remove", selector = "#progress", multiple = FALSE)))
  expect_error(remove_carbon_notification(c("a", "b"), session = session), "id")
})
