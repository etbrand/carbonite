render <- function(x) as.character(htmltools::renderTags(x)$html)

test_that("carbon_modal() builds an open modal with header, body, and footer", {
  modal <- carbon_modal(
    htmltools::p("Body text"),
    title = "Delete report?",
    label = "Quarterly sales",
    size = "sm"
  )

  expect_equal(modal$name, "cds-modal")
  expect_true(has_attr(modal, "open"))
  expect_equal(attr_of(modal, "size"), "sm")
  expect_false(has_attr(modal, "prevent-close-on-click-outside"))
  expect_false(has_attr(modal, "aria-label"))

  expect_length(find_tags(modal, "cds-modal-header > cds-modal-close-button"), 1)
  expect_match(render(find_tags(modal, "cds-modal-label")[[1]]), "Quarterly sales")
  expect_match(render(find_tags(modal, "cds-modal-heading")[[1]]), "Delete report?")
  expect_match(render(find_tags(modal, "cds-modal-body")[[1]]), "<p>Body text</p>", fixed = TRUE)

  # Default footer: a Cancel button that closes the modal in the browser
  close <- find_tags(modal, "cds-modal-footer > cds-button")
  expect_length(close, 1)
  expect_true(has_attr(close[[1]], "data-modal-close"))
  expect_equal(attr_of(close[[1]], "kind"), "secondary")
})

test_that("carbon_modal() options: no footer, no title, easy_close", {
  modal <- carbon_modal("Hi", footer = NULL, easy_close = FALSE)

  expect_length(find_tags(modal, "cds-modal-footer"), 0)
  expect_length(find_tags(modal, "cds-modal-heading"), 0)
  expect_length(find_tags(modal, "cds-modal-label"), 0)
  expect_equal(attr_of(modal, "aria-label"), "Dialog")
  expect_true(has_attr(modal, "prevent-close-on-click-outside"))

  expect_error(carbon_modal(easy_close = "no"), "easy_close")
  expect_error(carbon_modal(size = "xl"))
})

test_that("carbon_modal() keeps footer buttons in order", {
  modal <- carbon_modal(
    footer = htmltools::tagList(
      carbon_modal_close_button(),
      carbon_button("ok", "OK")
    )
  )
  buttons <- find_tags(modal, "cds-modal-footer cds-button")

  expect_length(buttons, 2)
  expect_null(attr_of(buttons[[1]], "id"))
  expect_equal(attr_of(buttons[[2]], "id"), "ok")
  expect_false(has_attr(buttons[[2]], "data-modal-close"))
})

test_that("carbon_modal_close_button() renders a closing button", {
  html <- render(carbon_modal_close_button("Got it", kind = "primary"))

  expect_match(html, '<cds-button kind="primary" data-modal-close>Got it</cds-button>', fixed = TRUE)
  expect_error(carbon_modal_close_button(kind = "huge"))
})

test_that("show_carbon_modal() replaces any open modal, then inserts this one", {
  session <- ui_session()
  show_carbon_modal(carbon_modal("Hello", title = "Hi"), session = session)

  expect_length(session$sent, 2)
  expect_equal(session$sent[[1]], list(type = "remove", selector = ".carbon-modal-wrapper", multiple = TRUE))

  insert <- session$sent[[2]]
  expect_equal(insert$type, "insert")
  expect_equal(insert$selector, "body")
  expect_equal(insert$where, "beforeEnd")
  expect_match(insert$html, '^<div class="carbon-modal-wrapper">\\s*<cds-modal open')
})

test_that("show_carbon_modal() only accepts a carbon_modal()", {
  expect_error(show_carbon_modal(htmltools::div("x"), session = ui_session()), "carbon_modal")
  expect_error(show_carbon_modal("x", session = ui_session()), "carbon_modal")
})

test_that("remove_carbon_modal() removes every modal wrapper", {
  session <- ui_session()
  remove_carbon_modal(session = session)

  expect_equal(session$sent, list(list(type = "remove", selector = ".carbon-modal-wrapper", multiple = TRUE)))
})
